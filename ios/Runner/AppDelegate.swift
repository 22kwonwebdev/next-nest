import Flutter
import Photos
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let galleryChannel = FlutterMethodChannel(
      name: "quotation_app/gallery",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    galleryChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard call.method == "saveImageToGallery" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let imageData = (arguments["bytes"] as? FlutterStandardTypedData)?.data,
        UIImage(data: imageData) != nil
      else {
        result(FlutterError(
          code: "INVALID_IMAGE",
          message: "The image data could not be read.",
          details: nil
        ))
        return
      }
      self?.saveImageToPhotos(imageData, result: result)
    }
  }

  private func saveImageToPhotos(_ data: Data, result: @escaping FlutterResult) {
    let saveImage = {
      guard let image = UIImage(data: data) else {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "INVALID_IMAGE",
            message: "The image data could not be read.",
            details: nil
          ))
        }
        return
      }
      PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAsset(from: image)
      }) { success, error in
        DispatchQueue.main.async {
          if success {
            result("Photos")
          } else {
            result(FlutterError(
              code: "PHOTO_SAVE_FAILED",
              message: error?.localizedDescription ?? "Could not save image to Photos.",
              details: nil
            ))
          }
        }
      }
    }

    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        if status == .authorized {
          saveImage()
        } else {
          DispatchQueue.main.async {
            result(FlutterError(
              code: "PHOTO_PERMISSION_DENIED",
              message: "Allow photo access to save images to Photos.",
              details: nil
            ))
          }
        }
      }
    } else {
      PHPhotoLibrary.requestAuthorization { status in
        if status == .authorized {
          saveImage()
        } else {
          DispatchQueue.main.async {
            result(FlutterError(
              code: "PHOTO_PERMISSION_DENIED",
              message: "Allow photo access to save images to Photos.",
              details: nil
            ))
          }
        }
      }
    }
  }
}
