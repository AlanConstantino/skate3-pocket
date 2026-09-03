#!/bin/bash
# Measure a running game the same way for any app, by asking the compositor
# when frames actually reached the screen rather than trusting either app's
# own counter. SurfaceFlinger keeps the last 128 present timestamps per layer;
# the gaps between them are the frame intervals a player actually sees.
#
# usage: bench.sh <package> [seconds] [label]
set -uo pipefail
. "$(dirname "$0")/env.sh"
PKG_UNDER_TEST="${1:?usage: bench.sh <package> [seconds] [label]}"
SECS="${2:-30}"
LABEL="${3:-$PKG_UNDER_TEST}"

adbs() { adb -s "$SERIAL" "$@"; }

pid=$(adbs shell pidof "$PKG_UNDER_TEST" | tr -d '\r')
[ -n "$pid" ] || { echo "$PKG_UNDER_TEST is not running"; exit 1; }

# The layer name SurfaceFlinger knows this app's window by.
# Two traps here, both of which report a convincing zero for an app that is
# rendering perfectly well:
#
#  1. "Background for ..." is a solid-colour layer behind the real one and
#     never presents a frame of its own.
#  2. --list wraps each name in a RequestedLayerState{...} envelope with a
#     trailing parentId, but --latency wants the bare name INCLUDING its
#     leading hex id. Hand it the envelope and it silently matches nothing.
# The (BLAST) child is the one frames are queued to; its parent SurfaceView
# layer carries no frame history at all. Prefer the child, and note that both
# get new ids every time the surface is recreated, so this has to be resolved
# fresh on each run rather than remembered.
all=$(adbs shell dumpsys SurfaceFlinger --list 2>/dev/null | tr -d '\r' \
        | grep -i "$PKG_UNDER_TEST" | grep -v 'Background for')
raw=$(printf '%s\n' "$all" | grep -F '(BLAST)' | tail -1)
[ -n "$raw" ] || raw=$(printf '%s\n' "$all" | grep -i 'SurfaceView' | tail -1)
[ -n "$raw" ] || raw=$(printf '%s\n' "$all" | tail -1)
[ -n "$raw" ] || { echo "no SurfaceFlinger layer for $PKG_UNDER_TEST"; exit 1; }
layer=$(printf '%s' "$raw" | sed -E 's/^RequestedLayerState\{//; s/\}$//; s/ parentId=[0-9]+.*$//')

# A layer that answers with nothing but a refresh period is the wrong one.
probe=$(adbs shell "dumpsys SurfaceFlinger --latency '$layer'" 2>/dev/null | tr -d '\r' | grep -c '[0-9]')
if [ "${probe:-0}" -lt 2 ]; then
  echo "   NOTE: this layer has no frame history yet; a zero below is not evidence of a freeze"
fi

echo "== $LABEL"
echo "   layer: $layer"
echo "   sampling ${SECS}s - play normally now"

# The layer name contains spaces, so it has to be quoted for the shell ON THE
# DEVICE. Passing it as a separate argument to `adb shell` lets adb rejoin the
# argv with spaces and the device shell then splits it into words again, which
# matches no layer and reports zero frames for an app that is rendering.
adbs shell "dumpsys SurfaceFlinger --latency-clear '$layer'" >/dev/null 2>&1
start_cpu=$(adbs shell cat /proc/$pid/stat 2>/dev/null | awk '{print $14+$15}')
sleep "$SECS"
end_cpu=$(adbs shell cat /proc/$pid/stat 2>/dev/null | awk '{print $14+$15}')

adbs shell "dumpsys SurfaceFlinger --latency '$layer'" 2>/dev/null | tr -d '\r' > /tmp/bench_latency.txt
mem=$(adbs shell dumpsys meminfo "$PKG_UNDER_TEST" 2>/dev/null | tr -d '\r' | grep -E 'TOTAL PSS' | head -1)
therm=$(adbs shell dumpsys thermalservice 2>/dev/null | tr -d '\r' | grep -iE 'Temperature\{.*type=SKIN|mStatus' | head -2)
ticks=$(adbs shell getconf CLK_TCK 2>/dev/null | tr -d '\r'); ticks=${ticks:-100}

python3 - "$LABEL" "$SECS" "$start_cpu" "$end_cpu" "$ticks" <<'PY'
import sys
label, secs, c0, c1, ticks = sys.argv[1], float(sys.argv[2]), sys.argv[3], sys.argv[4], float(sys.argv[5])
rows = [l.split() for l in open('/tmp/bench_latency.txt').read().splitlines() if l.strip()]
# First line is the refresh period in ns; each later row is
# desired-present / actual-present / frame-ready, in nanoseconds.
present = []
for r in rows[1:]:
    if len(r) >= 3:
        try:
            t = int(r[1])
        except ValueError:
            continue
        # 0 and the sentinel mean "never presented".
        if t > 0 and t < (1 << 63) - 1:
            present.append(t)
present.sort()
gaps = [(b - a) / 1e6 for a, b in zip(present, present[1:]) if 0 < (b - a) < 1e9]
print(f"   presented frames sampled: {len(present)}")
if gaps:
    gaps_sorted = sorted(gaps)
    n = len(gaps_sorted)
    p = lambda q: gaps_sorted[min(n - 1, int(n * q))]
    span = (present[-1] - present[0]) / 1e9
    print(f"   fps (presented)  {len(gaps)/span:6.1f}")
    print(f"   frame interval   p50 {p(0.50):5.2f} ms   p95 {p(0.95):5.2f} ms   p99 {p(0.99):5.2f} ms   max {gaps_sorted[-1]:6.2f} ms")
    print(f"   over 20 ms       {100*sum(1 for g in gaps_sorted if g > 20)/n:5.1f} %  of frames")
else:
    print("   no frame intervals captured (app may be idle or not presenting)")
try:
    cpu_s = (int(c1) - int(c0)) / ticks
    print(f"   cpu              {100*cpu_s/secs:6.1f} % of one core")
except Exception:
    pass
PY
echo "   $mem"
[ -n "$therm" ] && echo "   thermal: $therm"
