#!/bin/bash
# Median guest-frame cost from the engine's own per-frame log.
#
# The SurfaceFlinger frame interval cannot be used to compare builds here: the
# presenter is FIFO on a 60 Hz panel, so every frame is quantised to a multiple
# of 16.65 ms and five different configurations all reported p50 116.54 ms
# (7 vsyncs) while the underlying work ranged 83-142 ms. These numbers come
# from "slow guest frame dt=... rest=..." instead, which is continuous, and it
# takes the median of every logged frame rather than the last three.
set -uo pipefail
SERIAL=R83X303S5ZL
FILES=/sdcard/Android/data/com.nakas.skate3/files
LABEL="${1:-run}"
adb -s "$SERIAL" shell "grep 'slow guest frame' $FILES/skate3.log" 2>/dev/null \
 | sed -E 's/.*dt=([0-9.]+)ms.*cap=([0-9.]+) build=([0-9.]+).*rest=([0-9.]+)\]ms.*/\1 \2 \3 \4/' \
 | python3 -c "
import sys,statistics as st
rows=[list(map(float,l.split())) for l in sys.stdin if len(l.split())==4]
if len(rows)<10:
    print(f'   $LABEL: only {len(rows)} frames logged - not enough to compare'); raise SystemExit
dt=[r[0] for r in rows]; cap=[r[1] for r in rows]; bld=[r[2] for r in rows]; rest=[r[3] for r in rows]
def s(n,v): return f'{n}={st.median(v):6.1f}ms'
print(f'   $LABEL  n={len(rows)}  ' + '  '.join([s('dt',dt),s('cap',cap),s('build',bld),s('rest',rest)]))
print(f'      rest p25={st.quantiles(rest,n=4)[0]:.1f} p75={st.quantiles(rest,n=4)[2]:.1f}  min={min(rest):.1f} max={max(rest):.1f}')
"

# The lines above only log frames slow enough to trip a threshold, so they are
# biased upward and few. The [pace] windows cover every frame in a 30 s span
# and their p50 is the guest frame time, not the vsync-quantised presented one.
echo "      pace windows (every frame, 30s each):"
adb -s "$SERIAL" shell "grep '\[pace\] 30s' $FILES/skate3.log" 2>/dev/null \
 | sed -E 's/.*\[pace\] /         /' | tail -4

