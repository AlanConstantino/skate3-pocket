package com.nakas.skate3

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper

/**
 * Relaunches the game after a setting that only takes effect at startup.
 *
 * An app process cannot exec itself, and the game process is about to exit, so
 * the relaunch has to be issued from somewhere that outlives it: this activity
 * declares android:process=":restart" and therefore runs in its own process.
 * It starts a fresh task and finishes; by then the old process has gone.
 */
class RestartActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // A moment for the game process to finish exiting. Starting a
        // singleTask activity while the old instance is still alive would be
        // delivered to it as onNewIntent instead of launching anything.
        // The manifest uses a translucent theme: Theme.NoDisplay requires
        // finish() before onResume completes and crashes during this delay.
        Handler(Looper.getMainLooper()).postDelayed({
            val intent = Intent(this, SetupActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            }
            startActivity(intent)
            finish()
            Runtime.getRuntime().exit(0)
        }, 750)
    }
}
