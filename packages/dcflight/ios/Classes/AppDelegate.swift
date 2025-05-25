//
//  AppDelegate.swift
//  Runner
//
//  Created by Tahiru Agbanwa on 4/15/25.
//

import Flutter
import UIKit

@objc open class DCAppDelegate: FlutterAppDelegate {
    
    // Flutter engine instance that will be used by the whole app
    var flutterEngine: FlutterEngine?
    
    @objc public static func registerWithRegistrar(_ registrar: FlutterPluginRegistrar) {
        // Register the plugin with the Flutter engine
        print("✅ DCFlight plugin registered with Flutter")
        
        // Set up method channels directly through the registrar
        let messenger = registrar.messenger()
        
        // Initialize method channels for bridge and events
        DCMauiBridgeMethodChannel.shared.initialize(with: messenger)
        DCMauiEventMethodHandler.shared.initialize(with: messenger)
        // Note: Layout is now handled natively, no need for layout method channel
    }
    
    override open func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
      // Create and run engine before diverging to ensure Dart code executes
      self.flutterEngine = FlutterEngine(name: "io.dcflight.engine")
      self.flutterEngine?.run(withEntrypoint: "main", libraryURI: nil)
      
      
      // Now diverge to DCFlight setup
      divergeToFlight()
      print("divergence complete")
      
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
