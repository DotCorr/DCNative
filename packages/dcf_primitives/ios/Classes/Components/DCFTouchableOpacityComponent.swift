import UIKit
import dcflight

/// Component that handles touchable opacity functionality
class DCFTouchableOpacityComponent: NSObject, DCFComponent, ComponentMethodHandler {
    // Keep singleton instance to prevent deallocation when touch targets are registered
    private static let sharedInstance = DCFTouchableOpacityComponent()
    
    // Static storage for touch event handlers
    private static var touchEventHandlers = [UIView: (String, (String, String, [String: Any]) -> Void)]()
    
    // Store strong reference to self when views are registered
    private static var registeredViews = [UIView: DCFTouchableOpacityComponent]()
    
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        // Create view to handle touches
        let touchableView = TouchableView()
        touchableView.component = self
        
        // Force user interaction to be enabled
        touchableView.isUserInteractionEnabled = true
        
        // Apply props
        updateView(touchableView, withProps: props)
        
        // Enable debug mode in development
        #if DEBUG
        touchableView._debugMode = true
        #endif
        
        print("🆕 Created touchable view with props: \(props)")
        return touchableView
    }
    
    func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool {
        guard let touchableView = view as? TouchableView else { return false }
        
        // Set active opacity
        if let activeOpacity = props["activeOpacity"] as? CGFloat {
            touchableView.activeOpacity = activeOpacity
            
            // Store as associated object for direct access in handlers
            objc_setAssociatedObject(
                view,
                UnsafeRawPointer(bitPattern: "activeOpacity".hashValue)!,
                activeOpacity,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        } else {
            touchableView.activeOpacity = 0.2 // Default
        }
        
        // Set disabled state
        if let disabled = props["disabled"] as? Bool {
            touchableView.isUserInteractionEnabled = !disabled
            // Apply disabled visual state if needed
            touchableView.alpha = disabled ? 0.5 : 1.0
        }
        
        // Set long press delay
        if let longPressDelay = props["longPressDelay"] as? Int {
            touchableView.longPressDelay = TimeInterval(longPressDelay) / 1000.0
        }
        
        return true
    }
    
    // MARK: - Event Handling
    
    func handleTouchDown(_ view: TouchableView) {
        // Animate to pressed state
        UIView.animate(withDuration: 0.1) {
            view.alpha = view.activeOpacity
        }
        
        // Trigger onPressIn event using multiple methods
        if tryDirectEventHandling(view, eventType: "onPressIn") || 
           tryStaticDictionaryHandling(view, eventType: "onPressIn") ||
           tryGenericEventHandling(view, eventType: "onPressIn") {
          
        } else {
            print("⚠️ onPressIn event not handled - no handler registered")
        }
        
        // Set up long press timer
        view.startLongPressTimer()
    }
    
    func handleTouchUp(_ view: TouchableView, inside: Bool) {
        // Cancel long press timer
        view.cancelLongPressTimer()
        
        // Animate back to normal state
        UIView.animate(withDuration: 0.1) {
            view.alpha = 1.0
        }
        
        // Trigger onPressOut event
        tryAllEventHandlingMethods(view, eventType: "onPressOut")
        
        // Trigger onPress event if touch ended inside the view
        if inside {
            tryAllEventHandlingMethods(view, eventType: "onPress")
        }
    }
    
    func handleLongPress(_ view: TouchableView) {
        // Trigger long press event
        tryAllEventHandlingMethods(view, eventType: "onLongPress")
    }
    
    // Try all event handling methods in sequence
    private func tryAllEventHandlingMethods(_ view: UIView, eventType: String) {
        if tryDirectEventHandling(view, eventType: eventType) || 
           tryStaticDictionaryHandling(view, eventType: eventType) ||
           tryGenericEventHandling(view, eventType: eventType) {
        } else {
            print("⚠️ \(eventType) event not handled - no handler registered")
        }
    }
    
    // Try direct handling via associated objects with specific keys
    private func tryDirectEventHandling(_ view: UIView, eventType: String) -> Bool {
        if let viewId = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "touchableViewId".hashValue)!) as? String,
           let callback = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "touchableCallback".hashValue)!) as? (String, String, [String: Any]) -> Void {
            
            print("🎯 Direct handler found for touchable view: \(viewId)")
            
            // Prepare event data
            let eventData: [String: Any] = [
                "timestamp": Date().timeIntervalSince1970,
                "direct": true
            ]
            
            // Invoke callback directly
            callback(viewId, eventType, eventData)
            return true
        }
        return false
    }
    
    // Try handling via static dictionary
    private func tryStaticDictionaryHandling(_ view: UIView, eventType: String) -> Bool {
        if let (viewId, callback) = DCFTouchableOpacityComponent.touchEventHandlers[view] {
            print("🔘 Touchable event via static dictionary: \(viewId)")
            
            callback(viewId, eventType, [
                "timestamp": Date().timeIntervalSince1970,
                "staticDict": true
            ])
            return true
        }
        return false
    }
    
    // Try handling via generic associated objects
    private func tryGenericEventHandling(_ view: UIView, eventType: String) -> Bool {
        if let viewId = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "viewId".hashValue)!) as? String,
           let callback = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!) as? (String, String, [String: Any]) -> Void {
            
            print("🔍 Found event handler via associated objects for view \(viewId)")
            
            callback(viewId, eventType, [
                "timestamp": Date().timeIntervalSince1970,
                "generic": true
            ])
            return true
        }
        return false
    }
    
    // MARK: - Method Handling
    
    func handleMethod(methodName: String, args: [String: Any], view: UIView) -> Bool {
        switch methodName {
        case "setOpacity":
            if let opacity = args["opacity"] as? CGFloat {
                view.alpha = opacity
                return true
            }
        case "setHighlighted":
            if let highlighted = args["highlighted"] as? Bool,
               let touchableView = view as? TouchableView {
                if highlighted {
                    touchableView.alpha = touchableView.activeOpacity
                } else {
                    touchableView.alpha = 1.0
                }
                return true
            }
        default:
            break
        }
        
        return false
    }
    
    // MARK: - Event Listener Management
    
    func addEventListeners(to view: UIView, viewId: String, eventTypes: [String], 
                          eventCallback: @escaping (String, String, [String: Any]) -> Void) {
        guard let touchableView = view as? TouchableView else { 
            print("❌ Cannot add event listeners to non-touchable view")
            return 
        }
 
        // Ensure the component is set
        touchableView.component = DCFTouchableOpacityComponent.sharedInstance
        
        // Store event data with associated objects
        storeEventData(on: touchableView, viewId: viewId, eventTypes: eventTypes, callback: eventCallback)
        
        // Store strong reference to component instance to prevent deallocation
        DCFTouchableOpacityComponent.registeredViews[touchableView] = DCFTouchableOpacityComponent.sharedInstance
        
        print("✅ Successfully added event handlers to touchable view \(viewId)")
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
        
        // Additional redundant storage - touchable specific keys
        objc_setAssociatedObject(
            view,
            UnsafeRawPointer(bitPattern: "touchableViewId".hashValue)!,
            viewId,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        objc_setAssociatedObject(
            view,
            UnsafeRawPointer(bitPattern: "touchableCallback".hashValue)!,
            callback,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        // Store in static dictionary as additional backup
        DCFTouchableOpacityComponent.touchEventHandlers[view] = (viewId, callback)
    }
    
    func removeEventListeners(from view: UIView, viewId: String, eventTypes: [String]) {
        // Clean up all references
        cleanupEventReferences(from: view, viewId: viewId)
        
        print("✅ Removed event listeners from touchable view: \(viewId)")
    }
    
    // Helper to clean up all event references
    private func cleanupEventReferences(from view: UIView, viewId: String) {
        // Remove from static handlers dictionary
        DCFTouchableOpacityComponent.touchEventHandlers.removeValue(forKey: view)
        DCFTouchableOpacityComponent.registeredViews.removeValue(forKey: view)
        
        // Clear all associated objects
        let keys = ["viewId", "eventTypes", "eventCallback", "touchableViewId", "touchableCallback"]
        for key in keys {
            objc_setAssociatedObject(
                view,
                UnsafeRawPointer(bitPattern: key.hashValue)!,
                nil,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

/// Custom view class for touchable opacity
class TouchableView: UIView {
    // Reference to component
    weak var component: DCFTouchableOpacityComponent?
    
    // Active opacity when pressed
    var activeOpacity: CGFloat = 0.2
    
    // Long press properties
    var longPressDelay: TimeInterval = 0.5
    var longPressTimer: Timer?
    
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
    
    // Start long press timer
    func startLongPressTimer() {
        cancelLongPressTimer()
        
        longPressTimer = Timer.scheduledTimer(withTimeInterval: longPressDelay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.component?.handleLongPress(self)
        }
    }
    
    // Cancel long press timer
    func cancelLongPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = nil
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        component?.handleTouchDown(self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        // Check if touch is inside view
        if let touch = touches.first {
            let point = touch.location(in: self)
            let inside = bounds.contains(point)
            component?.handleTouchUp(self, inside: inside)
        } else {
            component?.handleTouchUp(self, inside: false)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        component?.handleTouchUp(self, inside: false)
    }
}
