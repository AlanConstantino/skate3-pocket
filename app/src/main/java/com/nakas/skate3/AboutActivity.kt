package com.nakas.skate3

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.text.Html
import android.text.method.LinkMovementMethod
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/** Credits and bundled notices stay available without loading the game. */
class AboutActivity : Activity() {
    override fun onCreate(state: Bundle?) {
        super.onCreate(state)
        val notices = intent.getBooleanExtra("show_notices", false)
        val pad = (20 * resources.displayMetrics.density).toInt()
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(pad, pad, pad, pad)
            setBackgroundColor(Color.parseColor("#101418"))
        }
        content.addView(TextView(this).apply {
            text = if (notices) "Third-party notices" else "Skate 3 Pocket ${BuildConfig.VERSION_NAME}"
            textSize = 26f
            setTextColor(Color.WHITE)
        })
        val body = TextView(this).apply {
            textSize = 15f
            setTextColor(Color.parseColor("#C8CDD4"))
            setLinkTextColor(Color.parseColor("#9ED8F5"))
            setPadding(0, pad, 0, pad)
            text = if (notices) assets.open("third-party/NOTICE.txt").bufferedReader().use { it.readText() }
                else Html.fromHtml(assets.open("about.html").bufferedReader().use { it.readText() },
                    Html.FROM_HTML_MODE_LEGACY)
            movementMethod = LinkMovementMethod.getInstance()
        }
        content.addView(ScrollView(this).apply { addView(body) },
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        if (!notices) content.addView(Button(this).apply {
            text = "Third-party notices"
            isAllCaps = false
            setOnClickListener {
                startActivity(Intent(this@AboutActivity, AboutActivity::class.java)
                    .putExtra("show_notices", true))
            }
        })
        content.addView(Button(this).apply {
            text = "Back"
            isAllCaps = false
            setOnClickListener { finish() }
        })
        setContentView(content)
    }
}
