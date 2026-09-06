package com.nakas.skate3

import android.app.Activity
import org.libsdl.app.SDLActivity
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import java.io.File
import java.util.Locale

/**
 * Something to look at while the disc is unpacked.
 *
 * The engine extracts ~6 GB before it draws its first frame, so the SDL
 * surface exists and stays black for minutes. Players concluded it had hung,
 * force-closed it part way, and were left with a half-extracted game - which
 * became the most common "the port doesn't work" report there is, from people
 * whose install had been working the whole time.
 *
 * This sits above the SDL surface and says what is happening. The progress is
 * real and needs nothing from the engine: the game folder grows towards the
 * disc's own size as it extracts, so measuring it IS the progress. It stops
 * when the folder stops growing and the executable has appeared, then hands
 * the screen over.
 */
object InstallOverlay {

    private const val POLL_MS = 1000L
    // The disc is ~6 GB after extraction; used only to scale the bar before
    // the real total is known.
    private const val ASSUMED_TOTAL_BYTES = 6_400_000_000.0

    fun attach(activity: Activity) {
        val pad = (24 * activity.resources.displayMetrics.density).toInt()
        val title = TextView(activity).apply {
            text = "Installing Skate 3"
            textSize = 22f
            setTextColor(Color.WHITE)
        }
        val detail = TextView(activity).apply {
            text = "Unpacking the disc image…"
            textSize = 15f
            setTextColor(Color.parseColor("#C8CDD4"))
            setPadding(0, pad / 2, 0, pad / 2)
        }
        val bar = ProgressBar(activity, null, android.R.attr.progressBarStyleHorizontal).apply {
            max = 1000
            isIndeterminate = false
        }
        val note = TextView(activity).apply {
            text = "This takes several minutes. Do not close the app or let the " +
                "screen turn off - the install would be left half-finished."
            textSize = 13f
            setTextColor(Color.parseColor("#8B93A0"))
            setPadding(0, pad / 2, 0, 0)
        }
        val panel = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(pad * 2, pad, pad * 2, pad)
            // Opaque: it has to hide the black surface, not blend into it.
            setBackgroundColor(Color.parseColor("#101418"))
            addView(title)
            addView(detail)
            addView(bar, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                                                ViewGroup.LayoutParams.WRAP_CONTENT))
            addView(note)
        }
        // Into SDL's own layout, above its SurfaceView, rather than through
        // addContentView - SDLActivity calls setContentView(mLayout) during
        // its onCreate, and anything added around that races with it. A
        // sibling added after mSurface draws over it; SDL does not z-order the
        // surface on top.
        val host = SDLActivity.getContentView()?.parent as? ViewGroup
            ?: (SDLActivity.getContentView() as? ViewGroup)
        if (host != null) {
            host.addView(panel, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                                                       ViewGroup.LayoutParams.MATCH_PARENT))
        } else {
            activity.addContentView(
                panel,
                ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                                       ViewGroup.LayoutParams.MATCH_PARENT))
        }

        // Safety net. If the "finished" test below ever fails to fire, this
        // panel would sit over a running game forever and there would be no
        // way past it. A slow device unpacking from slow storage is the case
        // to allow for, so the limit is generous - but it is absolute.
        handlerRemoveAfter(activity, panel, 45L * 60L * 1000L)

        val handler = Handler(Looper.getMainLooper())
        val gameDir = GameData.gameDir(activity)
        var lastSize = -1L
        var unchangedPolls = 0

        handler.post(object : Runnable {
            override fun run() {
                val size = directorySize(gameDir)
                if (size == lastSize) {
                    unchangedPolls++
                } else {
                    unchangedPolls = 0
                    lastSize = size
                }

                val fraction = (size / ASSUMED_TOTAL_BYTES).coerceIn(0.0, 1.0)
                bar.progress = (fraction * 1000).toInt()
                detail.text = String.format(
                    Locale.US, "Unpacking the disc image…  %.2f GB", size / 1e9
                )

                // Done when the executable is there and nothing has been
                // written for a few seconds - the engine has moved on to
                // booting the game, which draws for itself.
                val settled = unchangedPolls >= 5 && File(gameDir, "default.xex").isFile
                if (settled) {
                    detail.text = "Starting the game…"
                    bar.isIndeterminate = true
                    handler.postDelayed({ (panel.parent as? ViewGroup)?.removeView(panel) }, 1500)
                    return
                }
                handler.postDelayed(this, POLL_MS)
            }
        })
    }

    private fun handlerRemoveAfter(activity: Activity, panel: View, afterMs: Long) {
        Handler(Looper.getMainLooper()).postDelayed({
            (panel.parent as? ViewGroup)?.removeView(panel)
        }, afterMs)
    }

    /** Bytes on disk under [dir]; a missing folder is simply zero so far. */
    private fun directorySize(dir: File): Long = try {
        dir.walkTopDown().filter { it.isFile }.map { it.length() }.sum()
    } catch (_: Exception) {
        0L
    }
}
