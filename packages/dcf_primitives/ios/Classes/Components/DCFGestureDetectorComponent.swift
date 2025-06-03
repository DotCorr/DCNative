import UIKit
import dcflight

/// Component that handles gesture recognition
class DCFGestureDetectorComponent: NSObject, DCFComponent, ComponentMethodHandler {
    // Keep singleton instance to prevent deallocation when gesture targets are registered
    private static let sharedInstance = DCFGestureDetectorComponent()
    
    // Gesture recognizers by view
    private static var gestureRecognizers = [UIView: [UIGestureRecognizer]]()
    
    // Static storage for gesture event handlers
    private static var gestureEventHandlers = [UIView: (String, (String, String, [String: Any]) -> Void)]()
    
    // Store strong reference to self when views are registered
    private static var registeredViews = [UIView: DCFGestureDetectorComponent]()
    
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        // Create a view to capture gestures
        let gestureView = GestureView()
        
        // Force user interaction to be enabled
        gestureView.isUserInteractionEnabled = true
        gestureView.backgroundColor = .clear
        
        // Apply props
        updateView(gestureView, withProps: props)
        
        // Enable debug mode in development
        #if DEBUG
        gestureView._debugMode = true
        #endif
        
        print("🆕 Created gesture view with props: \(props)")
        return gestureView
    }
    
    func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool {
        // Apply visibility
        if let enabled = props["enabled"] as? Bool {
            view.isUserInteractionEnabled = enabled
        }
        
        // Configure gestures based on events registered
        configureGestures(view)
        
        return true
    }
    
    // Configure gesture recognizers
    private func configureGestures(_ view: UIView) {
        // Clean up previous gesture recognizers
        if let recognizers = DCFGestureDetectorComponent.gestureRecognizers[view] {
            for recognizer in recognizers {
                view.removeGestureRecognizer(recognizer)
            }
        }
        
        // Create new gesture recognizers array for this view
        var recognizers = [UIGestureRecognizer]()
        
        // Add tap gesture recognizer
        let tapRecognizer = UITapGestureRecognizer(target: DCFGestureDetectorComponent.sharedInstance, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapRecognizer)
        recognizers.append(tapRecognizer)
        
        // Add long press gesture recognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: DCFGestureDetectorComponent.sharedInstance, action: #selector(handleLongPress(_:)))
        view.addGestureRecognizer(longPressRecognizer)
        recognizers.append(longPressRecognizer)
        
        // Add swipe gesture recognizers (left, right, up, down)
        let swipeLeftRecognizer = UISwipeGestureRecognizer(target: DCFGestureDetectorComponent.sharedInstance, action: #selector(handleSwipeLeft(_:)))
        swipeLeftRecognizer.direction = .left
        view.addGestureRecognizer(swipeLeftRecognizer)
        recognizers.append(swipeLeftRecognizer)
        
        let swipeRightRecognizer = UISwipeGestureRecognizer(target: DCFGestureDetectorComponent.sharedInstance, action: #selector(handleSwipeRight(_:)))
        swipeRightRecognizer.direction = .right
        view.addGestureRecognizer(swipeRightRecognizer)
        recognizers.append(swipeRightRecognizer)
        
        let swipeUpRecognizer = UISwipeGestureRecognizer(target: DCFGestureDetectorComponent.sharedInstance, action: #selector(handleSwipeUp(_:)))
        swipeUpRecognizer.direction = .up
        view.addGestureRecognizer(swipeUpRecognizer)
        recognizers.append(swipeUpRecognizer)
        
        let swipeDownRecognizer = UISwipeGestureRecognizer(target: DCFGestureDetectorComponent.sharedInstance, action: #selector(handleSwipeDown(_:)))
        swipeDownRecognizer.direction = .down
        view.addGestureRecognizer(swipeDownRecognizer)
        recognizers.append(swipeDownRecognizer)
        
        // Add pan gesture recognizer
        let panRecognizer = UIPanGestureRecognizer(target: DCFGestureDetectorComponent.sharedInstance, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(panRecognizer)
        recognizers.append(panRecognizer)
        
        // Store gesture recognizers for cleanup
        DCFGestureDetectorComponent.gestureRecognizers[view] = recognizers
        
        // Store strong reference to component instance to prevent deallocation
        DCFGestureDetectorComponent.registeredViews[view] = DCFGestureDetectorComponent.sharedInstance
    }
    
    // MARK: - Gesture Handlers
    
    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        if let view = recognizer.view {
            tryAllEventHandlingMethods(view, eventType: "onTap", eventData: [:])
        }
    }
    
    @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began, let view = recognizer.view {
            tryAllEventHandlingMethods(view, eventType: "onLongPress", eventData: [:])
        }
    }
    
    @objc func handleSwipeLeft(_ recognizer: UISwipeGestureRecognizer) {
        if let view = recognizer.view {
            tryAllEventHandlingMethods(view, eventType: "onSwipeLeft", eventData: [:])
        }
    }
    
    @objc func handleSwipeRight(_ recognizer: UISwipeGestureRecognizer) {
        if let view = recognizer.view {
            tryAllEventHandlingMethods(view, eventType: "onSwipeRight", eventData: [:])
        }
    }
    
    @objc func handleSwipeUp(_ recognizer: UISwipeGestureRecognizer) {
        if let view = recognizer.view {
            tryAllEventHandlingMethods(view, eventType: "onSwipeUp", eventData: [:])
        }
    }
    
    @objc func handleSwipeDown(_ recognizer: UISwipeGestureRecognizer) {
        if let view = recognizer.view {
            tryAllEventHandlingMethods(view, eventType: "onSwipeDown", eventData: [:])
        }
    }
    
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let view = recognizer.view else { return }
        
        let translation = recognizer.translation(in: view)
        let velocity = recognizer.velocity(in: view)
        
        var eventType = "onPan"
        var eventData: [String: Any] = [
            "translationX": translation.x,
            "translationY": translation.y,
            "velocityX": velocity.x,
            "velocityY": velocity.y,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        switch recognizer.state {
        case .began:
            eventType = "onPanStart"
        case .changed:
            eventType = "onPanUpdate"
        case .ended, .cancelled:
            eventType = "onPanEnd"
        default:
            return
        }
        
        tryAllEventHandlingMethods(view, eventType: eventType, eventData: eventData)
    }
    
    // Try all event handling methods in sequence
    private func tryAllEventHandlingMethods(_ view: UIView, eventType: String, eventData: [String: Any] = [:]) {
        if tryDirectEventHandling(view, eventType: eventType, eventData: eventData) || 
           tryStaticDictionaryHandling(view, eventType: eventType, eventData: eventData) ||
           tryGenericEventHandling(view, eventType: eventType, eventData: eventData) {
            print("✅ \(eventType) gesture event handled successfully")
        } else {
            print("⚠️ \(eventType) gesture event not handled - no handler registered")
        }
    }
    
    // Try direct handling via associated objects with specific keys
    private func tryDirectEventHandling(_ view: UIView, eventType: String, eventData: [String: Any]) -> Bool {
        if let viewId = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "gestureViewId".hashValue)!) as? String,
           let callback = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "gestureCallback".hashValue)!) as? (String, String, [String: Any]) -> Void {
            
            print("🎯 Direct handler found for gesture view: \(viewId)")
            
            // Prepare enhanced event data
            var enhancedEventData = eventData
            enhancedEventData["direct"] = true
            if !enhancedEventData.keys.contains("timestamp") {
                enhancedEventData["timestamp"] = Date().timeIntervalSince1970
            }
            
            // Invoke callback directly
            callback(viewId, eventType, enhancedEventData)
            return true
        }
        return false
    }
    
    // Try handling via static dictionary
    private func tryStaticDictionaryHandling(_ view: UIView, eventType: String, eventData: [String: Any]) -> Bool {
        if let (viewId, callback) = DCFGestureDetectorComponent.gestureEventHandlers[view] {
            print("🔘 Gesture event via static dictionary: \(viewId)")
            
            var enhancedEventData = eventData
            enhancedEventData["staticDict"] = true
            if !enhancedEventData.keys.contains("timestamp") {
                enhancedEventData["timestamp"] = Date().timeIntervalSince1970
            }
            
            callback(viewId, eventType, enhancedEventData)
            return true
        }
        return false
    }
    
    // Try handling via generic associated objects
    private func tryGenericEventHandling(_ view: UIView, eventType: String, eventData: [String: Any]) -> Bool {
        if let viewId = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "viewId".hashValue)!) as? String,
           let callback = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!) as? (String, String, [String: Any]) -> Void {
            
            print("🔍 Found event handler via associated objects for view \(viewId)")
            
            var enhancedEventData = eventData
            enhancedEventData["generic"] = true
            if !enhancedEventData.keys.contains("timestamp") {
                enhancedEventData["timestamp"] = Date().timeIntervalSince1970
            }
            
            callback(viewId, eventType, enhancedEventData)
            return true
        }
        return false
    }
    
    // MARK: - Event Listener Management
    
    func addEventListeners(to view: UIView, viewId: String, eventTypes: [String], 
                          eventCallback: @escaping (String, String, [String: Any]) -> Void) {
        // Store event data with associated objects
        storeEventData(on: view, viewId: viewId, eventTypes: eventTypes, callback: eventCallback)
        
        print("✅ Successfully added event handlers to gesture view \(viewId)")
    }
    
    // Store event data using multiple methods for redundancy
    private func storeEventData(on view: UIView, viewId: String, eventTypes: [String], 
                               callback: @escaping (String, String, [String: Any]) -> Void) {
        // Store the event information as associated objects - generic keys
        objc_setAssociatedObject(
            view,
            UnsafeRawPointer(bitPattern: "viewId".hashValue)!,
            viewId,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        objc_setAssociatedObject(
            view,
            UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!,
            eventTypes,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        objc_setAssociatedObject(
            view,
            UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!,
            callback,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        // Additional redundant storage - gesture specific keys
        objc_setAssociatedObject(
            view,
            UnsafeRawPointer(bitPattern: "gestureViewId".hashValue)!,
            viewId,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        objc_setAssociatedObject(
            view,
            UnsafeRawPointer(bitPattern: "gestureCallback".hashValue)!,
            callback,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        // Store in static dictionary as additional backup
        DCFGestureDetectorComponent.gestureEventHandlers[view] = (viewId, callback)
    }
    
    func removeEventListeners(from view: UIView, viewId: String, eventTypes: [String]) {
        // Clean up all references
        cleanupEventReferences(from: view, viewId: viewId)
        
        print("✅ Removed event listeners from gesture view: \(viewId)")
    }
    
    // Helper to clean up all event references
    private func cleanupEventReferences(from view: UIView, viewId: String) {
        // Remove from static handlers dictionary
        DCFGestureDetectorComponent.gestureEventHandlers.removeValue(forKey: view)
        DCFGestureDetectorComponent.registeredViews.removeValue(forKey: view)
        
        // Clear all associated objects
        let keys = ["viewId", "eventTypes", "eventCallback", "gestureViewId", "gestureCallback"]
        for key in keys {
            objc_setAssociatedObject(
                view,
                UnsafeRawPointer(bitPattern: key.hashValue)!,
                nil,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    // MARK: - Method Handling
    
    func handleMethod(methodName: String, args: [String: Any], view: UIView) -> Bool {
        // Handle custom methods
        switch methodName {
        case "enableGestures":
            view.isUserInteractionEnabled = true
            return true
        case "disableGestures":
            view.isUserInteractionEnabled = false
            return true
        default:
            return false
        }
    }
}

/// Custom view class for gesture detection with debug capabilities
class GestureView: UIView {
    // Debug mode
    var _debugMode = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // Force user interaction to be enabled
        self.isUserInteractionEnabled = true
    }
}
