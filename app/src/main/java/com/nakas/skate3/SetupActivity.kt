package com.nakas.skate3

import android.app.Activity
import android.app.ActivityManager
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.io.File

/**
 * The launcher. Its whole job is to establish that the game's own files are
 * present before starting the engine, and to say plainly what is missing when
 * they are not.
 *
 * It does not extract anything itself: the engine already contains a disc
 * reader and a title-update stager that the desktop builds use, and running
 * them twice in two languages would be two things to keep correct. All this
 * screen does is hand over the paths.
 */
class SetupActivity : Activity() {

    private lateinit var status: TextView
    private lateinit var playButton: Button
    private lateinit var titleUpdateButton: Button
    @Volatile private var busy = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(buildUi())
        refresh()
    }

    override fun onResume() {
        super.onResume()
        refresh()
    }

    /**
     * Two columns, because the activity is locked to landscape and a single
     * stacked column runs the buttons off the bottom of a phone held sideways -
     * which hid the one button the player needed. Text on the left, actions on
     * the right, each side scrolling on its own so neither can push the other
     * out of reach.
     */
    private fun buildUi(): View {
        val pad = (20 * resources.displayMetrics.density).toInt()
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(pad, pad, pad, pad)
            setBackgroundColor(Color.parseColor("#101418"))
        }

        val left = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        left.addView(TextView(this).apply {
            text = "Skate 3"
            textSize = 30f
            setTextColor(Color.WHITE)
        })
        status = TextView(this).apply {
            textSize = 14f
            setTextColor(Color.parseColor("#C8CDD4"))
            setPadding(0, pad / 2, 0, 0)
        }
        left.addView(status)
        root.addView(ScrollView(this).apply { addView(left) },
            LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f))

        val actions = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(pad, 0, 0, 0)
        }
        playButton = button("Play") { startGame() }
        actions.addView(playButton)
        actions.addView(button("Install from a disc image…") { startGame() })
        titleUpdateButton = button("Download title update") { downloadTitleUpdate() }
        actions.addView(titleUpdateButton)
        actions.addView(button("Copy the details") { copyDiagnostics() })
        root.addView(ScrollView(this).apply { addView(actions) },
            LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f))

        return root
    }

    private fun button(label: String, onClick: () -> Unit) = Button(this).apply {
        text = label
        textSize = 16f
        gravity = Gravity.CENTER
        setOnClickListener { onClick() }
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = (8 * resources.displayMetrics.density).toInt() }
    }

    private fun refresh() {
        if (busy) return
        val ready = GameData.isReadyToPlay(this)
        val game = GameData.isGameInstalled(this)
        val tu = GameData.isTitleUpdateInstalled(this)
        // Only worth offering while it is the missing piece.
        titleUpdateButton.visibility = if (tu) View.GONE else View.VISIBLE
        status.text = buildString {
            appendLine(if (ready) "Ready to play." else "The game's own files are not here yet.")
            appendLine()
            appendLine("Disc files: ${if (game) "installed" else "missing"}")
            appendLine("Title update 3: ${if (tu) "staged" else "missing"}")
            appendLine()
            appendLine(GameData.gameDir(this@SetupActivity).absolutePath)
            appendLine(GameData.describeFree(this@SetupActivity))
            if (!ready) {
                appendLine()
                appendLine(
                    "Choose \"Install from a disc image\" and pick your own Skate 3 " +
                        "Xbox 360 disc image. Around 6 GB is extracted here. No game " +
                        "content ships inside this app."
                )
                if (!tu) {
                    appendLine()
                    appendLine(
                        "The title update is required to boot. Download it, or pick your " +
                            "own copy during the install."
                    )
                }
            }
        }
        playButton.isEnabled = ready
        playButton.alpha = if (ready) 1f else 0.4f
    }

    /**
     * Fetches the title update and lets the engine stage it. The engine checks
     * both patch payloads by hash, so a wrong or truncated file is rejected
     * there rather than turning into a crash once the game is running.
     */
    private fun downloadTitleUpdate() {
        if (busy) return
        busy = true
        titleUpdateButton.isEnabled = false
        status.text = "Downloading the title update…"
        Thread {
            val outcome = try {
                val file = TitleUpdate.download(this) { got, total ->
                    val line = if (total > 0) {
                        "Downloading the title update… ${got * 100 / total}%"
                    } else {
                        "Downloading the title update… ${got / 1024} KB"
                    }
                    runOnUiThread { status.text = line }
                }
                Result.success(file)
            } catch (e: Exception) {
                Result.failure(e)
            }
            runOnUiThread {
                busy = false
                titleUpdateButton.isEnabled = true
                outcome.fold(
                    onSuccess = { file ->
                        // Hand it straight to the engine, which stages and
                        // verifies it during startup.
                        startGame(listOf("--skate3_install_tu=${file.absolutePath}"))
                    },
                    onFailure = { e ->
                        status.text = "The title update could not be downloaded.\n\n" +
                            (e.message ?: e.toString()) +
                            "\n\nCheck the connection, or put the file on the phone and use " +
                            "\"install from a disc image\" to pick it yourself."
                    }
                )
            }
        }.start()
    }

    /**
     * Both buttons do the same thing, and the difference is only what the
     * player is about to see: the engine notices for itself that the game
     * files are missing and shows its own installer, which reaches the system
     * document picker through the activity. Duplicating that check here in
     * Kotlin would be a second thing to keep true.
     */
    private fun startGame(extraArgs: List<String> = emptyList()) {
        GameData.userDir(this).mkdirs()
        GameData.gameDir(this).mkdirs()
        val args = buildList {
            addAll(extraArgs)
            // Only on a first run: the engine writes its own settings after
            // that, and re-applying a preset every launch would silently undo
            // whatever was changed in the menu.
            if (!File(GameData.userDir(this@SetupActivity), "settings.toml").exists()) {
                add("--skate3_performance_profile=${proposedProfile()}")
            }
        }
        startActivity(Intent(this, Skate3Activity::class.java).apply {
            putExtra(Skate3Activity.EXTRA_ARGUMENTS, args.toTypedArray())
        })
    }

    /**
     * A starting quality preset from the amount of RAM, which is the closest
     * proxy Android offers for how much phone this is. The player can change
     * it in the game's own settings afterwards and that choice sticks.
     */
    private fun proposedProfile(): String {
        val info = ActivityManager.MemoryInfo()
        (getSystemService(ACTIVITY_SERVICE) as ActivityManager).getMemoryInfo(info)
        val gb = info.totalMem.toDouble() / (1024 * 1024 * 1024)
        return if (gb >= 5.5) "performance" else "potato"
    }

    private fun copyDiagnostics() {
        val info = ActivityManager.MemoryInfo()
        (getSystemService(ACTIVITY_SERVICE) as ActivityManager).getMemoryInfo(info)
        val text = buildString {
            appendLine("${Build.MANUFACTURER} ${Build.MODEL} (${Build.DEVICE})")
            appendLine("Android ${Build.VERSION.RELEASE}, API ${Build.VERSION.SDK_INT}")
            appendLine("SoC ${Build.SOC_MANUFACTURER} ${Build.SOC_MODEL}")
            appendLine("ABIs ${Build.SUPPORTED_ABIS.joinToString()}")
            appendLine("RAM ${info.totalMem / (1024 * 1024)} MB")
            appendLine("Game files ${GameData.gameDir(this@SetupActivity)}")
            appendLine("Ready ${GameData.isReadyToPlay(this@SetupActivity)}")
        }
        val clipboard = getSystemService(CLIPBOARD_SERVICE) as android.content.ClipboardManager
        clipboard.setPrimaryClip(android.content.ClipData.newPlainText("skate3", text))
        status.text = text
    }
}
