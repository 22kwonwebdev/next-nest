package com.example.quotation_app

import android.content.ContentValues
import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.media.MediaScannerConnection
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "quotation_app/downloads"
    private val galleryChannel = "quotation_app/gallery"
    private val galleryPermissionRequestCode = 7142
    private var pendingGallerySave: PendingGallerySave? = null

    private data class PendingGallerySave(
        val fileName: String,
        val bytes: ByteArray,
        val result: MethodChannel.Result,
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "saveToDownloads") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                try {
                    val fileName = call.argument<String>("fileName")
                        ?: throw IllegalArgumentException("Missing file name")
                    val bytes = call.argument<ByteArray>("bytes")
                        ?: throw IllegalArgumentException("Missing file bytes")
                    result.success(saveToDownloads(fileName, bytes))
                } catch (error: Exception) {
                    result.error("DOWNLOAD_SAVE_FAILED", error.message, null)
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, galleryChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "saveImageToGallery") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val fileName = call.argument<String>("fileName")
                        ?: throw IllegalArgumentException("Missing image file name")
                    val bytes = call.argument<ByteArray>("bytes")
                        ?: throw IllegalArgumentException("Missing image bytes")
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
                        checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
                        PackageManager.PERMISSION_GRANTED
                    ) {
                        pendingGallerySave = PendingGallerySave(fileName, bytes, result)
                        requestPermissions(
                            arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                            galleryPermissionRequestCode,
                        )
                    } else {
                        result.success(saveImageToGallery(fileName, bytes))
                    }
                } catch (error: Exception) {
                    result.error("GALLERY_SAVE_FAILED", error.message, null)
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != galleryPermissionRequestCode) return
        val pending = pendingGallerySave ?: return
        pendingGallerySave = null
        if (grantResults.firstOrNull() != PackageManager.PERMISSION_GRANTED) {
            pending.result.error(
                "GALLERY_PERMISSION_DENIED",
                "Allow photo and media access to save this image.",
                null,
            )
            return
        }
        try {
            pending.result.success(saveImageToGallery(pending.fileName, pending.bytes))
        } catch (error: Exception) {
            pending.result.error("GALLERY_SAVE_FAILED", error.message, null)
        }
    }

    private fun saveImageToGallery(fileName: String, bytes: ByteArray): String {
        val mimeType = when (fileName.substringAfterLast('.', "").lowercase()) {
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            else -> throw IllegalArgumentException("Only PNG and JPG images are supported")
        }
        val resolver = applicationContext.contentResolver

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Images.Media.MIME_TYPE, mimeType)
                put(
                    MediaStore.Images.Media.RELATIVE_PATH,
                    "${Environment.DIRECTORY_PICTURES}/Next Nest",
                )
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                ?: throw IOException("Could not create image in Gallery")
            try {
                resolver.openOutputStream(uri)?.use { it.write(bytes) }
                    ?: throw IOException("Could not open image in Gallery")
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
                return "Pictures/Next Nest"
            } catch (error: Exception) {
                resolver.delete(uri, null, null)
                throw error
            }
        }

        val directory = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
            "Next Nest",
        )
        if (!directory.exists() && !directory.mkdirs()) {
            throw IOException("Could not create Gallery directory")
        }
        val file = File(directory, fileName)
        file.writeBytes(bytes)
        MediaScannerConnection.scanFile(this, arrayOf(file.absolutePath), arrayOf(mimeType), null)
        return file.absolutePath
    }

    private fun saveToDownloads(fileName: String, bytes: ByteArray): String {
        val mimeType = when (fileName.substringAfterLast('.', "").lowercase()) {
            "pdf" -> "application/pdf"
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            else -> "application/octet-stream"
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IOException("Could not create file in Downloads")
            try {
                resolver.openOutputStream(uri)?.use { it.write(bytes) }
                    ?: throw IOException("Could not open file in Downloads")
                values.clear()
                values.put(MediaStore.Downloads.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
                return "Downloads/$fileName"
            } catch (error: Exception) {
                resolver.delete(uri, null, null)
                throw error
            }
        }

        val directory = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!directory.exists() && !directory.mkdirs()) {
            throw IOException("Could not create Downloads directory")
        }
        val file = File(directory, fileName)
        file.writeBytes(bytes)
        return file.absolutePath
    }
}
