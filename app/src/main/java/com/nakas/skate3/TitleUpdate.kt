package com.nakas.skate3

import android.content.Context
import android.util.Log
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

/**
 * Fetching Title Update 3.
 *
 * The game will not boot without it: this build executes title-update code, so
 * the two patch payloads have to be staged beside the game files. The engine
 * already knows how to stage and verify them, and it already carries a
 * download URL for desktop - but that path shells out to curl, which stock
 * Android does not have. So the transfer happens here and the file is handed
 * to the engine, which checks both payloads by hash and refuses anything that
 * does not match. A truncated or wrong download therefore fails loudly at
 * staging rather than becoming a mystery crash later.
 *
 * Nothing about the patch ships inside this app. It is the publisher's data
 * and stays on the player's side of the line, which is the same rule the
 * engine's own build applies when it declines to bundle it.
 */
object TitleUpdate {

    // The address the engine configures for every other platform.
    const val DEFAULT_URL = "https://xboxunity.net/Resources/Lib/TitleUpdate.php?tuid=21774"

    /** A container far outside this range is a redirect or an error page. */
    private const val MIN_BYTES = 512L * 1024
    private const val MAX_BYTES = 256L * 1024 * 1024

    fun destination(context: Context): File = File(GameData.root(context), "title_update.bin")

    /**
     * Downloads to a temporary file and moves it into place only once complete,
     * so an interrupted transfer cannot leave something that looks finished.
     * Returns the file, or throws with a message worth showing.
     */
    fun download(context: Context, url: String = DEFAULT_URL,
                 onProgress: (Long, Long) -> Unit = { _, _ -> }): File {
        val target = destination(context)
        // The folder may not exist yet; writing the temporary file straight
        // into it fails with ENOENT and looks like a network problem.
        target.parentFile?.mkdirs()
        val partial = File(target.parentFile, target.name + ".part")
        partial.delete()

        val connection = (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = 30_000
            readTimeout = 60_000
            instanceFollowRedirects = true
            setRequestProperty("User-Agent", "skate3-android")
        }
        try {
            val code = connection.responseCode
            if (code !in 200..299) {
                throw IllegalStateException("The server answered $code ${connection.responseMessage}")
            }
            val expected = connection.contentLengthLong
            if (expected in 1 until MIN_BYTES || expected > MAX_BYTES) {
                throw IllegalStateException("That is not the title update: $expected bytes")
            }
            var written = 0L
            connection.inputStream.use { input ->
                partial.outputStream().use { output ->
                    val buffer = ByteArray(64 * 1024)
                    while (true) {
                        val n = input.read(buffer)
                        if (n < 0) break
                        output.write(buffer, 0, n)
                        written += n
                        if (written > MAX_BYTES) {
                            throw IllegalStateException("The download kept going past $MAX_BYTES bytes")
                        }
                        onProgress(written, expected)
                    }
                }
            }
            if (written < MIN_BYTES) {
                throw IllegalStateException("Only $written bytes arrived; the download was cut short")
            }
            target.delete()
            if (!partial.renameTo(target)) {
                throw IllegalStateException("Could not put the download in place")
            }
            Log.i("skate3", "title update downloaded: $written bytes -> $target")
            return target
        } finally {
            partial.delete()
            connection.disconnect()
        }
    }
}
