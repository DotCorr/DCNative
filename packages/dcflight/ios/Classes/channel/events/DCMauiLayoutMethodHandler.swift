import Flutter
import UIKit

/// Handles layout method channel interactions between Flutter and native code
class DCMauiLayoutMethodHandler: NSObject {
    /// Singleton instance
    static let shared = DCMauiLayoutMethodHandler()
    let frame = UIScreen.main.bounds;
    
    /// Method channel for layout operations
    var methodChannel: FlutterMethodChannel?
    
    /// Initialize with Flutter binary messenger
    func initialize(with binaryMessenger: FlutterBinaryMessenger) {
        // Create method channel
        methodChannel = FlutterMethodChannel(
            name: "com.dcmaui.layout",
            binaryMessenger: binaryMessenger
        )
        
        // Set up method handler
        methodChannel?.setMethodCallHandler(handleMethodCall)
        
        print("📐 Layout method channel initialized")
    }
    
    /// Handle method calls from Flutter
    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Get the arguments
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "ARGS_ERROR", message: "Arguments cannot be null", details: nil))
            return
        }
        
        // Handle methods - only non-layout methods are exposed to Dart
        switch call.method {
        case "getScreenDimensions":
            handleGetScreenDimensions(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // Get screen dimensions
    private func handleGetScreenDimensions(result: @escaping FlutterResult) {
        let bounds = UIScreen.main.bounds
        let dimensions = [
            "width": bounds.width,
            "height": bounds.height,
            "scale": UIScreen.main.scale,
            "statusBarHeight": UIApplication.shared.statusBarFrame.height
        ]
        
        result(dimensions)
    }
}
