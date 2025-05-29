import UIKit
import dcflight

// Distinct view class for Modal containers to avoid type collision with ContextMenu
class DCFModalContainerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = UIColor.clear
        isHidden = true
        clipsToBounds = true
        alpha = 0
    }
}

class DCFModalComponent: NSObject, DCFComponent, UIAdaptivePresentationControllerDelegate {
    private static var activeModals: [UIView: (UIViewController, UIView)] = [:]
    private static let sharedInstance = DCFModalComponent()
    
    // Static storage for modal event handlers (same pattern as button)
    private static var modalEventHandlers = [UIView: (String, (String, String, [String: Any]) -> Void)]()
    
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        // Modal container view - this should NEVER be visible or participate in layout
        let containerView = DCFModalContainerView()
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
        
        let modalViewController: UIViewController
        let modalView = UIView()
        
        // Configure modal view
        // Apply StyleSheet properties
        modalView.applyStyles(props: props)
        
        // Apply modal-specific border radius
        if let borderRadius = props["borderRadius"] as? Double {
            modalView.layer.cornerRadius = CGFloat(borderRadius)
            modalView.layer.masksToBounds = true
        }
        
        // Handle modal-specific background properties
        if let transparent = props["transparent"] as? Bool, transparent {
            modalView.backgroundColor = UIColor.clear
        } else if modalView.backgroundColor == nil {
            // Only set default if no backgroundColor was specified in StyleSheet
            modalView.backgroundColor = UIColor.white
        }
        
        // Check if header is specified
        if let headerProps = props["header"] as? [String: Any] {
            // Create navigation controller with header
            let contentViewController = UIViewController()
            contentViewController.view = modalView
            
            let navigationController = UINavigationController(rootViewController: contentViewController)
            modalViewController = navigationController
            
            // Configure navigation bar (header)
            setupModalHeader(navigationController: navigationController, 
                           contentViewController: contentViewController,
                           headerProps: headerProps, 
                           containerView: view)
        } else {
            // No header - use plain view controller
            let plainViewController = UIViewController()
            plainViewController.view = modalView
            modalViewController = plainViewController
        }
        
        // Store weak reference to container view for delegate callbacks
        objc_setAssociatedObject(
            modalViewController,
            UnsafeRawPointer(bitPattern: "containerView".hashValue)!,
            view,
            .OBJC_ASSOCIATION_ASSIGN // Use ASSIGN to avoid retain cycle
        )
        
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
                // Set up presentation controller delegate after presentation
                modalViewController.presentationController?.delegate = DCFModalComponent.sharedInstance
                
                // Trigger onShow event using same pattern as TouchableOpacity
                self.triggerEvent(view, eventType: "onShow", eventData: [:])
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
            
            // Trigger onDismiss event using same pattern as TouchableOpacity
            self.triggerEvent(view, eventType: "onDismiss", eventData: [:])
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
    
    // Trigger event using multiple backup methods (same pattern as button)
    private func triggerEvent(_ view: UIView, eventType: String, eventData: [String: Any]) {
        // Try multiple handling methods like button component
        if tryDirectHandling(view, eventType: eventType, eventData: eventData) ||
           tryStaticDictionaryHandling(view, eventType: eventType, eventData: eventData) ||
           tryAssociatedObjectHandling(view, eventType: eventType, eventData: eventData) {
            // Success
        } else {
            print("📱 Modal event \(eventType) not registered - no callback found")
        }
    }
    
    // Try direct handling via modalViewId and modalCallback
    private func tryDirectHandling(_ view: UIView, eventType: String, eventData: [String: Any]) -> Bool {
        if let viewId = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "modalViewId".hashValue)!) as? String,
           let callback = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "modalCallback".hashValue)!) as? (String, String, [String: Any]) -> Void {
            
            print("🎯 Direct modal handler found for view: \(viewId)")
            callback(viewId, eventType, eventData)
            return true
        }
        return false
    }
    
    // Try handling via static dictionary
    private func tryStaticDictionaryHandling(_ view: UIView, eventType: String, eventData: [String: Any]) -> Bool {
        if let (viewId, callback) = DCFModalComponent.modalEventHandlers[view] {
            print("📦 Static dictionary modal handler found for view: \(viewId)")
            callback(viewId, eventType, eventData)
            return true
        }
        return false
    }
    
    // Try handling via individual event callbacks
    private func tryAssociatedObjectHandling(_ view: UIView, eventType: String, eventData: [String: Any]) -> Bool {
        let key = "modal_callback_\(eventType)"
        if let callback = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: key.hashValue)!) as? (String, String, [String: Any]) -> Void,
           let viewId = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "modal_viewId".hashValue)!) as? String {
            
            print("🔍 Associated object modal handler found for view \(viewId)")
            callback(viewId, eventType, eventData)
            return true
        }
        return false
    }
    
    // MARK: - Event Handling Implementation
    
    func addEventListeners(to view: UIView, viewId: String, eventTypes: [String],
                           eventCallback: @escaping (String, String, [String: Any]) -> Void) {
        print("📱 Adding modal event listeners to view \(viewId): \(eventTypes)")
        
        // Store event data with multiple methods for redundancy (same as button)
        storeEventData(on: view, viewId: viewId, eventTypes: eventTypes, callback: eventCallback)
        
        print("✅ Successfully registered modal event handlers for view \(viewId): \(eventTypes)")
    }
    
    // Store event data using multiple methods for redundancy (same pattern as button)
    private func storeEventData(on view: UIView, viewId: String, eventTypes: [String], 
                               callback: @escaping (String, String, [String: Any]) -> Void) {
        // Store individual callbacks for each event type
        for eventType in eventTypes {
            let key = "modal_callback_\(eventType)"
            objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: key.hashValue)!, callback, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        // Store view ID for reference
        objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "modal_viewId".hashValue)!, viewId, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Additional redundant storage (same as button component)
        objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "modalViewId".hashValue)!, viewId, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "modalCallback".hashValue)!, callback, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Store in static dictionary as additional backup
        DCFModalComponent.modalEventHandlers[view] = (viewId, callback)
    }
    
    func removeEventListeners(from view: UIView, viewId: String, eventTypes: [String]) {
        print("📱 Removing modal event listeners from view \(viewId): \(eventTypes)")
        
        // Clean up all references (same as button)
        cleanupEventReferences(from: view, viewId: viewId)
        
        print("✅ Removed modal event handlers for view \(viewId)")
    }
    
    // Helper to clean up all event references (same pattern as button)
    private func cleanupEventReferences(from view: UIView, viewId: String) {
        // Remove from static handlers dictionary
        DCFModalComponent.modalEventHandlers.removeValue(forKey: view)
        
        // Clear all associated objects
        let keys = ["modal_viewId", "modalViewId", "modalCallback", "modal_callback_onShow", "modal_callback_onDismiss", 
                   "modal_callback_onRequestClose", "modal_callback_onLeftButtonPress", "modal_callback_onRightButtonPress"]
        for key in keys {
            objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: key.hashValue)!, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension DCFModalComponent {
    
    // Called when user tries to dismiss modal with gesture (like swipe down)
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Get the container view from the modal view controller
        if let containerView = objc_getAssociatedObject(
            presentationController.presentedViewController,
            UnsafeRawPointer(bitPattern: "containerView".hashValue)!
        ) as? UIView {
            
            // Trigger onRequestClose event
            triggerEvent(containerView, eventType: "onRequestClose", eventData: [:])
        }
        
        // Return false to prevent automatic dismissal - let Dart handle it
        return false
    }
    
    // Called if the modal is actually dismissed (programmatically or system override)
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // Get the container view from the modal view controller
        if let containerView = objc_getAssociatedObject(
            presentationController.presentedViewController,
            UnsafeRawPointer(bitPattern: "containerView".hashValue)!
        ) as? UIView {
            
            // Clean up modal reference
            DCFModalComponent.activeModals.removeValue(forKey: containerView)
            
            // Move children back to container
            if let modalView = presentationController.presentedViewController.view {
                moveChildrenBackToContainer(from: modalView, to: containerView)
            }
            
            // Trigger onDismiss event
            triggerEvent(containerView, eventType: "onDismiss", eventData: [:])
        }
    }
}

// MARK: - Modal Header Configuration
    
extension DCFModalComponent {
    
    private func setupModalHeader(navigationController: UINavigationController, 
                                contentViewController: UIViewController,
                                headerProps: [String: Any], 
                                containerView: UIView) {
        
        let navigationBar = navigationController.navigationBar
        
        // Configure navigation bar appearance
        if let backgroundColor = headerProps["backgroundColor"] as? String {
            navigationBar.backgroundColor = ColorUtilities.color(fromHexString: backgroundColor)
        }
        
        // Set title
        if let title = headerProps["title"] as? String {
            contentViewController.title = title
            
            // Configure title appearance
            if let titleColor = headerProps["titleColor"] as? String {
                navigationBar.titleTextAttributes = [
                    .foregroundColor: ColorUtilities.color(fromHexString: titleColor)
                ]
            }
            
            if let fontSize = headerProps["fontSize"] as? Double {
                var attributes = navigationBar.titleTextAttributes ?? [:]
                let currentFont = (attributes[.font] as? UIFont) ?? UIFont.systemFont(ofSize: 17)
                attributes[.font] = currentFont.withSize(CGFloat(fontSize))
                navigationBar.titleTextAttributes = attributes
            }
            
            if let fontWeight = headerProps["fontWeight"] as? String {
                var attributes = navigationBar.titleTextAttributes ?? [:]
                let currentSize = ((attributes[.font] as? UIFont)?.pointSize) ?? 17
                
                let font: UIFont
                switch fontWeight {
                case "bold":
                    font = UIFont.boldSystemFont(ofSize: currentSize)
                case "medium":
                    font = UIFont.systemFont(ofSize: currentSize, weight: .medium)
                case "light":
                    font = UIFont.systemFont(ofSize: currentSize, weight: .light)
                default:
                    font = UIFont.systemFont(ofSize: currentSize)
                }
                
                attributes[.font] = font
                navigationBar.titleTextAttributes = attributes
            }
        }
        
        // Configure left button
        if let leftButtonProps = headerProps["leftButton"] as? [String: Any] {
            let leftButton = createHeaderButton(buttonProps: leftButtonProps, containerView: containerView, isLeftButton: true)
            contentViewController.navigationItem.leftBarButtonItem = leftButton
        } else if let showCloseButton = headerProps["showCloseButton"] as? Bool, showCloseButton {
            // Add default close button on the left - use sharedInstance as target
            let closeButton = UIBarButtonItem(title: "Close", style: .plain, target: DCFModalComponent.sharedInstance, action: #selector(defaultCloseButtonTapped(_:)))
            
            // Store container view reference for close button
            objc_setAssociatedObject(closeButton, 
                                   UnsafeRawPointer(bitPattern: "containerView".hashValue)!, 
                                   containerView, 
                                   .OBJC_ASSOCIATION_ASSIGN)
            
            contentViewController.navigationItem.leftBarButtonItem = closeButton
        }
        
        // Configure right button
        if let rightButtonProps = headerProps["rightButton"] as? [String: Any] {
            let rightButton = createHeaderButton(buttonProps: rightButtonProps, containerView: containerView, isLeftButton: false)
            contentViewController.navigationItem.rightBarButtonItem = rightButton
        }
    }
    
    private func createHeaderButton(buttonProps: [String: Any], containerView: UIView, isLeftButton: Bool) -> UIBarButtonItem {
        let title = buttonProps["title"] as? String ?? ""
        let styleString = buttonProps["style"] as? String ?? "plain"
        let enabled = buttonProps["enabled"] as? Bool ?? true
        
        let style: UIBarButtonItem.Style
        switch styleString {
        case "done":
            style = .done
        case "bordered":
            style = .plain // iOS doesn't have direct bordered style for bar button items
        default:
            style = .plain
        }
        
        let button = UIBarButtonItem(title: title, style: style, target: DCFModalComponent.sharedInstance, action: #selector(headerButtonTapped(_:)))
        button.isEnabled = enabled
        
        // Store container view and button side for event handling
        objc_setAssociatedObject(button, 
                               UnsafeRawPointer(bitPattern: "containerView".hashValue)!, 
                               containerView, 
                               .OBJC_ASSOCIATION_ASSIGN)
        
        objc_setAssociatedObject(button, 
                               UnsafeRawPointer(bitPattern: "isLeftButton".hashValue)!, 
                               isLeftButton, 
                               .OBJC_ASSOCIATION_RETAIN)
        
        return button
    }
    
    @objc private func headerButtonTapped(_ sender: UIBarButtonItem) {
        guard let containerView = objc_getAssociatedObject(sender, UnsafeRawPointer(bitPattern: "containerView".hashValue)!) as? UIView,
              let isLeftButton = objc_getAssociatedObject(sender, UnsafeRawPointer(bitPattern: "isLeftButton".hashValue)!) as? Bool else { return }
        
        let eventType = isLeftButton ? "onLeftButtonPress" : "onRightButtonPress"
        triggerEvent(containerView, eventType: eventType, eventData: [:])
    }
    
    @objc private func defaultCloseButtonTapped(_ sender: UIBarButtonItem) {
        guard let containerView = objc_getAssociatedObject(sender, UnsafeRawPointer(bitPattern: "containerView".hashValue)!) as? UIView else { return }
        
        // Trigger close event - this will dismiss the modal
        triggerEvent(containerView, eventType: "onRequestClose", eventData: [:])
    }
}
