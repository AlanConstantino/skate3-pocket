package com.nakas.skate3

import android.content.Context
import android.os.StatFs
import java.io.File

/**
 * Where the game's own files live, and whether they are all there yet.
 *
 * Everything sits under the app's external files directory
 * (/storage/emulated/0/Android/data/com.nakas.skate3/files). That is visible
 * to any file manager and to `adb push`, needs no storage permission, and is
 * removed when the app is uninstalled. The native side derives the same paths
 * from SDL, so the two agree without either being told.
 */
object GameData {

    /** The disc dump takes about 6 GB; refuse to start an install without room. */
    const val REQUIRED_FREE_BYTES = 7L * 1024 * 1024 * 1024

    fun root(context: Context): File =
        context.getExternalFilesDir(null) ?: context.filesDir

    fun gameDir(context: Context): File = File(root(context), "game")
    fun userDir(context: Context): File = File(root(context), "user")

    /** The disc has been extracted: the executable the recompiler was built from. */
    fun isGameInstalled(context: Context): Boolean =
        File(gameDir(context), "default.xex").isFile

    /**
     * The title update is staged. This build executes TU3 code, so the two
     * patch payloads have to be beside the game files or it cannot boot.
     */
    fun isTitleUpdateInstalled(context: Context): Boolean {
        val game = gameDir(context)
        return File(game, "default.xexp").isFile &&
            File(game, "data/webkit/EAWebkit.xexp").isFile
    }

    fun isReadyToPlay(context: Context): Boolean =
        isGameInstalled(context) && isTitleUpdateInstalled(context)

    fun freeBytes(context: Context): Long =
        try {
            val stat = StatFs(root(context).absolutePath)
            stat.availableBlocksLong * stat.blockSizeLong
        } catch (_: Exception) {
            0L
        }

    fun describeFree(context: Context): String {
        val gb = freeBytes(context).toDouble() / (1024 * 1024 * 1024)
        return String.format("%.1f GB free", gb)
    }
}
