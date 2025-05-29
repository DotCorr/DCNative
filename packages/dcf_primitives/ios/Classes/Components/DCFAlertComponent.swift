import UIKit
import dcflight

class DCFAlertComponent: NSObject, DCFComponent {
    static let sharedInstance = DCFAlertComponent()
    
    // Store event handlers for alert placeholder views
    static var alertEventHandlers = [UIView: (String, [String], (String, String, [String: Any]) -> Void)]()
    
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        // Alert doesn't create a view - it's presented directly
        // We'll return a transparent view as a placeholder
        let placeholderView = UIView()
        placeholderView.isHidden = true
        placeholderView.alpha = 0
        
        // Apply StyleSheet properties
        placeholderView.applyStyles(props: props)
        
        // Trigger alert presentation after a small delay
        DispatchQueue.main.async {
            self.presentAlert(props: props, placeholderView: placeholderView)
        }
        
        return placeholderView
    }
    
    func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool {
        // Apply StyleSheet properties
        view.applyStyles(props: props)
        
        // For alerts, updates mean presenting a new alert
        presentAlert(props: props, placeholderView: view)
        return true
    }
    
    private func presentAlert(props: [String: Any], placeholderView: UIView) {
        guard let title = props["title"] as? String else { return }
        
        let alertStyle: UIAlertController.Style
        if let style = props["alertStyle"] as? String {
            alertStyle = style == "actionSheet" ? .actionSheet : .alert
        } else {
            alertStyle = .alert
        }
        
        let alertController = UIAlertController(
            title: title,
            message: props["message"] as? String,
            preferredStyle: alertStyle
        )
        
        // Add actions from props
        if let actions = props["actions"] as? [[String: Any]] {
            for actionData in actions {
                guard let text = actionData["text"] as? String else { continue }
                
                let style: UIAlertAction.Style
                if let styleString = actionData["style"] as? String {
                    switch styleString {
                    case "cancel":
                        style = .cancel
                    case "destructive":
                        style = .destructive
                    default:
                        style = .default
                    }
                } else {
                    style = .default
                }
                
                let action = UIAlertAction(title: text, style: style) { _ in
                    // Trigger callback with action data using proper event system
                    self.triggerEventIfRegistered(
                        placeholderView,
                        eventType: "onAction",
                        eventData: [
                            "actionIndex": actionData["index"] as? Int ?? 0,
                            "actionText": text,
                            "actionStyle": styleString ?? "default"
                        ]
                    )
                }
                
                alertController.addAction(action)
            }
        }
        
        // Trigger onShow event
        triggerEventIfRegistered(placeholderView, eventType: "onShow", eventData: [:])
        
        // Present the alert
        if let topViewController = UIApplication.shared.windows.first?.rootViewController {
            var presentingController = topViewController
            while let presented = presentingController.presentedViewController {
                presentingController = presented
            }
            presentingController.present(alertController, animated: true) {
                // Alert was presented successfully
                self.triggerEventIfRegistered(placeholderView, eventType: "onPresented", eventData: [:])
            }
        }
    }
    
    // Trigger event if the view has been registered for that event type
    private func triggerEventIfRegistered(_ view: UIView, eventType: String, eventData: [String: Any]) {
        // Try handlers dictionary first
        if let (viewId, eventTypes, callback) = DCFAlertComponent.alertEventHandlers[view] {
            if eventTypes.contains(eventType) {
                print("✅ Triggering Alert event: \(eventType) for view \(viewId)")
                callback(viewId, eventType, eventData)
                return
            }
        }
        
        // Fallback to associated objects
        guard let eventTypes = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!) as? [String],
              let callback = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!) as? (String, String, [String: Any]) -> Void,
              let viewId = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "viewId".hashValue)!) as? String else {
            print("🚨 Alert event not registered - no handlers found for \(eventType)")
            return
        }
        
        if eventTypes.contains(eventType) {
            print("✅ Triggering Alert event (fallback): \(eventType) for view \(viewId)")
            callback(viewId, eventType, eventData)
        } else {
            print("🚨 Alert event \(eventType) not in registered types: \(eventTypes)")
        }
    }
    
    // MARK: - Event Handling Implementation
    
    func addEventListeners(to view: UIView, viewId: String, eventTypes: [String], 
                          eventCallback: @escaping (String, String, [String: Any]) -> Void) {
        print("🚨 Adding Alert event listeners to view \(viewId): \(eventTypes)")
        
        // Store event registration info
        DCFAlertComponent.alertEventHandlers[view] = (viewId, eventTypes, eventCallback)
        
        // Also store using associated objects as backup
        objc_setAssociatedObject(view, 
                               UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!, 
                               eventCallback, 
                               .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        objc_setAssociatedObject(view, 
                               UnsafeRawPointer(bitPattern: "viewId".hashValue)!, 
                               viewId, 
                               .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        objc_setAssociatedObject(view, 
                               UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!,
                               eventTypes,
                               .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        print("✅ Successfully registered Alert event handlers for view \(viewId)")
    }
    
    func removeEventListeners(from view: UIView, viewId: String, eventTypes: [String]) {
        print("🚨 Removing Alert event listeners from view \(viewId): \(eventTypes)")
        
        // Remove from handlers dictionary
        DCFAlertComponent.alertEventHandlers.removeValue(forKey: view)
        
        // Clean up associated objects
        objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "viewId".hashValue)!, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        print("✅ Removed Alert event handlers for view \(viewId)")
    }
}
