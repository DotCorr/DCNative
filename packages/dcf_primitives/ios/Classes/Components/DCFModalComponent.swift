import UIKit
import dcflight

class DCFModalComponent: NSObject, DCFComponent {
    private static var activeModals: [UIView: (UIViewController, UIView)] = [:]
    private static let sharedInstance = DCFModalComponent()
    
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        // Modal container view - this should NEVER be visible or participate in layout
        let containerView = UIView()
        containerView.backgroundColor = UIColor.clear
        containerView.isHidden = true  // Always hidden
        containerView.clipsToBounds = true
        containerView.alpha = 0  // Extra insurance it's not visible
        
        // CRITICAL: Make container view have zero size so it doesn't participate in layout
        containerView.frame = CGRect.zero
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add size constraints to keep it at zero size
        containerView.widthAnchor.constraint(equalToConstant: 0).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 0).isActive = true
        
        // Apply initial properties
        updateView(containerView, withProps: props)
        
        return containerView
    }
    
    func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool {
        guard let visible = props["visible"] as? Bool else { return false }
        
        if visible {
            presentModal(for: view, props: props)
        } else {
            dismissModal(for: view)
        }
        
        // Ensure container always stays hidden and at zero size
        view.isHidden = true
        view.alpha = 0
        view.frame = CGRect.zero
        
        return true
    }
    
    private func presentModal(for view: UIView, props: [String: Any]) {
        // Don't present if already presented
        if DCFModalComponent.activeModals[view] != nil { return }
        
        let modalViewController = UIViewController()
        let modalView = UIView()
        
        // Configure modal view
        // Apply StyleSheet properties
        modalView.applyStyles(props: props)
        
        // Handle modal-specific background properties
        if let transparent = props["transparent"] as? Bool, transparent {
            modalView.backgroundColor = UIColor.clear
        } else if modalView.backgroundColor == nil {
            // Only set default if no backgroundColor was specified in StyleSheet
            modalView.backgroundColor = UIColor.white
        }
        
        modalViewController.view = modalView
        
        // Configure presentation style
        if let presentationStyle = props["presentationStyle"] as? String {
            switch presentationStyle {
            case "fullScreen":
                modalViewController.modalPresentationStyle = .fullScreen
            case "pageSheet":
                modalViewController.modalPresentationStyle = .pageSheet
            case "formSheet":
                modalViewController.modalPresentationStyle = .formSheet
            case "overFullScreen":
                modalViewController.modalPresentationStyle = .overFullScreen
            case "overCurrentContext":
                modalViewController.modalPresentationStyle = .overCurrentContext
            case "popover":
                modalViewController.modalPresentationStyle = .popover
            default:
                modalViewController.modalPresentationStyle = .automatic
            }
        }
        
        // Configure transition style
        if let transitionStyle = props["transitionStyle"] as? String {
            switch transitionStyle {
            case "flipHorizontal":
                modalViewController.modalTransitionStyle = .flipHorizontal
            case "crossDissolve":
                modalViewController.modalTransitionStyle = .crossDissolve
            case "partialCurl":
                modalViewController.modalTransitionStyle = .partialCurl
            default:
                modalViewController.modalTransitionStyle = .coverVertical
            }
        }
        
        // Store reference to both modal controller and its view
        DCFModalComponent.activeModals[view] = (modalViewController, modalView)
        
        // Move children from container view to modal view
        moveChildrenToModal(from: view, to: modalView)
        
        // Present modal
        if let topViewController = UIApplication.shared.windows.first?.rootViewController {
            var presentingController = topViewController
            while let presented = presentingController.presentedViewController {
                presentingController = presented
            }
            
            presentingController.present(modalViewController, animated: true) {
                // Trigger onShow event using proper event system
                self.triggerEventIfRegistered(view: view, eventType: "onShow", eventData: [:])
            }
        }
    }
    
    private func dismissModal(for view: UIView) {
        guard let (modalViewController, modalView) = DCFModalComponent.activeModals[view] else { return }
        
        // Move modal children back to container view to preserve them
        moveChildrenBackToContainer(from: modalView, to: view)
        
        // Ensure container view stays hidden and at zero size
        view.isHidden = true
        view.alpha = 0
        view.frame = CGRect.zero
        
        modalViewController.dismiss(animated: true) {
            // Clean up reference
            DCFModalComponent.activeModals.removeValue(forKey: view)
            
            // Trigger onDismiss event using proper event system
            self.triggerEventIfRegistered(view: view, eventType: "onDismiss", eventData: [:])
        }
    }
    
    // Move children from container view to modal view
    private func moveChildrenToModal(from containerView: UIView, to modalView: UIView) {
        let children = containerView.subviews
        for child in children {
            child.removeFromSuperview()
            modalView.addSubview(child)
        }
        
        // Container must stay hidden - children are now safely in modal
        // containerView.isHidden = false  // REMOVED: This was causing children to appear in main UI
        
        print("📱 Moved \(children.count) children to modal view - container stays hidden")
    }
    
    // Move children back to container view when modal is dismissed
    private func moveChildrenBackToContainer(from modalView: UIView, to containerView: UIView) {
        let children = modalView.subviews
        for child in children {
            child.removeFromSuperview()
            containerView.addSubview(child)
        }
        
        // Container must stay hidden - children are preserved but not visible in main UI
        containerView.isHidden = true
        containerView.alpha = 0
        containerView.frame = CGRect.zero
        
        print("📱 Moved \(children.count) children back to container view (stays hidden)")
    }
    
    // Trigger event if the view has been registered for that event type
    private func triggerEventIfRegistered(view: UIView, eventType: String, eventData: [String: Any]) {
        guard let eventTypes = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!) as? [String],
              let callback = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!) as? (String, String, [String: Any]) -> Void,
              let viewId = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "viewId".hashValue)!) as? String else {
            print("📱 Modal event not registered - no handlers found for \(eventType)")
            return
        }
        
        if eventTypes.contains(eventType) {
            print("✅ Triggering modal event: \(eventType)")
            callback(viewId, eventType, eventData)
        } else {
            print("📱 Modal event \(eventType) not in registered types: \(eventTypes)")
        }
    }
    
    // MARK: - Event Handling Implementation
    
    func addEventListeners(to view: UIView, viewId: String, eventTypes: [String],
                           eventCallback: @escaping (String, String, [String: Any]) -> Void) {
        print("📱 Adding modal event listeners to view \(viewId): \(eventTypes)")
        
        // Store the event callback and view ID using associated objects
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
        
        print("✅ Successfully registered modal event handlers for view \(viewId)")
    }
    
    func removeEventListeners(from view: UIView, viewId: String, eventTypes: [String]) {
        print("📱 Removing modal event listeners from view \(viewId): \(eventTypes)")
        
        // Update the stored event types
        if let existingTypes = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!) as? [String] {
            var remainingTypes = existingTypes
            for type in eventTypes {
                if let index = remainingTypes.firstIndex(of: type) {
                    remainingTypes.remove(at: index)
                }
            }
            
            if remainingTypes.isEmpty {
                // Clean up all event data if no events remain
                objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "viewId".hashValue)!, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                print("🧹 Cleared all modal event data for view \(viewId)")
            } else {
                // Store updated event types
                objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!, remainingTypes, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                print("🔄 Updated modal event types for view \(viewId): \(remainingTypes)")
            }
        }
    }
}
