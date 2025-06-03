import UIKit
import dcflight

class DCFButtonComponent: NSObject, DCFComponent, ComponentMethodHandler {
    // Keep singleton instance to prevent deallocation when button targets are registered
    private static let sharedInstance = DCFButtonComponent()
    
    // Static storage for button handlers
    private static var buttonEventHandlers = [UIButton: (String, (String, String, [String: Any]) -> Void)]()
    
    // Store strong reference to self when buttons are registered
    private static var registeredButtons = [UIButton: DCFButtonComponent]()
    
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        // Use custom button for better touch handling
        let button = CustomButton(type: .system)
        
        // Make sure user interaction is explicitly enabled
        button.isUserInteractionEnabled = true
        
        // Apply initial styling
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(UIColor.white, for: .normal)
        
        // Apply props
        updateView(button, withProps: props)
        
        // Enable debug mode for this button in development
        #if DEBUG
        button._debugMode = true
        #endif
        
        print("🆕 Created button with props: \(props)")
        return button
    }
    
    func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool {
        guard let button = view as? UIButton else { return false }
        
        // Set title if specified
        if let title = props["title"] as? String {
            button.setTitle(title, for: .normal)
        }
        
        // Set title color if specified
        if let color = props["color"] as? String {
            button.setTitleColor(ColorUtilities.color(fromHexString: color), for: .normal)
        }
        
        // Set background color if specified
        if let backgroundColor = props["backgroundColor"] as? String {
            button.backgroundColor = ColorUtilities.color(fromHexString:backgroundColor)
        }
        
        // Set disabled state if specified
        if let disabled = props["disabled"] as? Bool {
            button.isEnabled = !disabled
            button.alpha = disabled ? 0.5 : 1.0
        }
        
        return true
    }
    
    // Handle button press
    @objc func handleButtonPress(_ sender: UIButton) {
        
        // Try to find handler using multiple backup methods
        if tryDirectHandling(sender) || tryStaticDictionaryHandling(sender) || tryAssociatedObjectHandling(sender) {
        } else {
            // Last resort attempt - use generic triggerEvent if all else fails
            triggerEvent(on: sender, eventType: "onPress", eventData: [:])
        }
    }
    
    // Try direct handling via buttonViewId and buttonCallback
    private func tryDirectHandling(_ sender: UIButton) -> Bool {
        if let viewId = objc_getAssociatedObject(sender, UnsafeRawPointer(bitPattern: "buttonViewId".hashValue)!) as? String,
           let callback = objc_getAssociatedObject(sender, UnsafeRawPointer(bitPattern: "buttonCallback".hashValue)!) as? (String, String, [String: Any]) -> Void {
            
            print("🎯 Direct handler found for button: \(viewId)")
            
            // Prepare event data
            let eventData: [String: Any] = [
                "pressed": true,
                "timestamp": Date().timeIntervalSince1970,
                "buttonTitle": sender.title(for: .normal) ?? "",
                "direct": true
            ]
            
            // Invoke callback directly
            callback(viewId, "onPress", eventData)
            return true
        }
        return false
    }
    
    // Try handling via static dictionary
    private func tryStaticDictionaryHandling(_ sender: UIButton) -> Bool {
        if let (viewId, callback) = DCFButtonComponent.buttonEventHandlers[sender] {
            
            callback(viewId, "onPress", [
                "pressed": true,
                "timestamp": Date().timeIntervalSince1970,
                "buttonTitle": sender.title(for: .normal) ?? "",
                "staticDict": true
            ])
            return true
        }
        return false
    }
    
    // Try handling via regular associated objects
    private func tryAssociatedObjectHandling(_ sender: UIButton) -> Bool {
        if let viewId = objc_getAssociatedObject(sender, UnsafeRawPointer(bitPattern: "viewId".hashValue)!) as? String,
           let callback = objc_getAssociatedObject(sender, UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!) as? (String, String, [String: Any]) -> Void {
            
            print("🔍 Found event handler via associated objects for view \(viewId)")
            
            callback(viewId, "onPress", [
                "pressed": true,
                "timestamp": Date().timeIntervalSince1970,
                "buttonTitle": sender.title(for: .normal) ?? "",
                "emergency": true
            ])
            return true
        }
        return false
    }
    
    @objc func handleButtonTouchDown(_ sender: UIButton) {
        if let activeOpacity = objc_getAssociatedObject(
            sender,
            UnsafeRawPointer(bitPattern: "activeOpacity".hashValue)!
        ) as? CGFloat {
            UIView.animate(withDuration: 0.15) {
                sender.alpha = activeOpacity
            }
        } else {
            UIView.animate(withDuration: 0.15) {
                sender.alpha = 0.7 // Default active opacity
            }
        }
    }
    
    @objc func handleButtonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.15) {
            sender.alpha = 1.0
        }
    }
    
    // MARK: - Event Handling
    
    func addEventListeners(to view: UIView, viewId: String, eventTypes: [String], 
                          eventCallback: @escaping (String, String, [String: Any]) -> Void) {
        guard let button = view as? UIButton else {
            return 
        }
 
        // Store event data with associated objects
        storeEventData(on: button, viewId: viewId, eventTypes: eventTypes, callback: eventCallback)
        
        // Remove any existing targets to avoid duplicates
        button.removeTarget(nil, action: nil, for: .touchUpInside)
        button.removeTarget(nil, action: nil, for: .touchDown)
        button.removeTarget(nil, action: nil, for: .touchUpOutside)
        button.removeTarget(nil, action: nil, for: .touchCancel)
        
        // Use sharedInstance to ensure the target isn't deallocated
        button.addTarget(DCFButtonComponent.sharedInstance, action: #selector(handleButtonPress(_:)), for: .touchUpInside)
        button.addTarget(DCFButtonComponent.sharedInstance, action: #selector(handleButtonTouchDown(_:)), for: .touchDown)
        button.addTarget(DCFButtonComponent.sharedInstance, action: #selector(handleButtonTouchUp(_:)), for: .touchUpInside)
        button.addTarget(DCFButtonComponent.sharedInstance, action: #selector(handleButtonTouchUp(_:)), for: .touchUpOutside)
        button.addTarget(DCFButtonComponent.sharedInstance, action: #selector(handleButtonTouchUp(_:)), for: .touchCancel)
        
        // Store strong reference to component instance to prevent deallocation
        DCFButtonComponent.registeredButtons[button] = DCFButtonComponent.sharedInstance
        
    }
    
    // Store event data using multiple methods for redundancy
    private func storeEventData(on button: UIButton, viewId: String, eventTypes: [String], 
                               callback: @escaping (String, String, [String: Any]) -> Void) {
        // Store the event information as associated objects
        objc_setAssociatedObject(
            button,
            UnsafeRawPointer(bitPattern: "viewId".hashValue)!,
            viewId,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        objc_setAssociatedObject(
            button,
            UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!,
            eventTypes,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        objc_setAssociatedObject(
            button,
            UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!,
            callback,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        // Additional redundant storage
        objc_setAssociatedObject(
            button,
            UnsafeRawPointer(bitPattern: "buttonViewId".hashValue)!,
            viewId,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        objc_setAssociatedObject(
            button,
            UnsafeRawPointer(bitPattern: "buttonCallback".hashValue)!,
            callback,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        // Store in static dictionary as additional backup
        DCFButtonComponent.buttonEventHandlers[button] = (viewId, callback)
    }
    
    func removeEventListeners(from view: UIView, viewId: String, eventTypes: [String]) {
        guard let button = view as? UIButton else { return }
        
        // Clean up all references
        cleanupEventReferences(from: button, viewId: viewId)
        
        // Remove all touch events
        button.removeTarget(nil, action: nil, for: .allEvents)
        
    }
    
    // Helper to clean up all event references
    private func cleanupEventReferences(from button: UIButton, viewId: String) {
        // Remove from static handlers dictionary
        DCFButtonComponent.buttonEventHandlers.removeValue(forKey: button)
        DCFButtonComponent.registeredButtons.removeValue(forKey: button)
        
        // Clear all associated objects
        let keys = ["viewId", "eventTypes", "eventCallback", "buttonViewId", "buttonCallback"]
        for key in keys {
            objc_setAssociatedObject(
                button,
                UnsafeRawPointer(bitPattern: key.hashValue)!,
                nil,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    // Handle component methods
    func handleMethod(methodName: String, args: [String: Any], view: UIView) -> Bool {
        guard let button = view as? UIButton else { return false }
        
        switch methodName {
        case "setHighlighted":
            if let highlighted = args["highlighted"] as? Bool {
                button.isHighlighted = highlighted
                return true
            }
        case "performClick":
            // Programmatically trigger a button press
            handleButtonPress(button)
            return true
        default:
            return false
        }
        
        return false
    }
}

// Custom button class to ensure touch events are properly captured
class CustomButton: UIButton {
    var _debugMode = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    private func setupButton() {
        // Force user interaction to be enabled
        self.isUserInteractionEnabled = true
        
        // Ensure touch area is sufficient
        self.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
  //removed debug logs, making too much noise but maintained the methods just incase
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
    }
}
