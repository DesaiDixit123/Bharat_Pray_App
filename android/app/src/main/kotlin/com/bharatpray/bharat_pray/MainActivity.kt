package com.bharatpray.bharat_pray

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.bharatpray/audio_picker"
    private val AUDIO_PICK_CODE = 2001
    private var pendingResult: MethodChannel.Result? = null

    override fun getRenderMode(): RenderMode {
        return RenderMode.texture
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickAudioFile" -> {
                        pendingResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "audio/*"
                            // Also accept common audio MIME types
                            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(
                                "audio/mpeg",   // MP3
                                "audio/mp4",    // M4A / AAC
                                "audio/wav",    // WAV
                                "audio/ogg",    // OGG
                                "audio/flac",   // FLAC
                                "audio/x-wav",
                                "audio/aac"
                            ))
                        }
                        startActivityForResult(intent, AUDIO_PICK_CODE)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == AUDIO_PICK_CODE) {
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                val uri: Uri = data.data!!
                val name = getFileName(uri) ?: "audio_file"

                // Copy the content:// file to app cache dir so audioplayers can read it
                val realPath = copyContentUriToCache(uri, name)

                if (realPath != null) {
                    pendingResult?.success(mapOf("name" to name, "path" to realPath))
                } else {
                    // Fallback: return content URI string (may not play on all devices)
                    pendingResult?.success(mapOf("name" to name, "path" to uri.toString()))
                }
            } else {
                // User pressed back — return null (no crash)
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }

    private fun copyContentUriToCache(uri: Uri, fileName: String): String? {
        return try {
            val audioDir = File(cacheDir, "jap_audio")
            if (!audioDir.exists()) audioDir.mkdirs()
            val destFile = File(audioDir, fileName)
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(destFile).use { output ->
                    input.copyTo(output)
                }
            }
            destFile.absolutePath
        } catch (e: Exception) {
            null
        }
    }

    private fun getFileName(uri: Uri): String? {
        return try {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                cursor.moveToFirst()
                cursor.getString(nameIndex)
            }
        } catch (e: Exception) {
            uri.lastPathSegment
        }
    }
}
