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
                self.triggerEvent(view: view, eventType: "onShow", eventData: [:])
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
            self.triggerEvent(view: view, eventType: "onDismiss", eventData: [:])
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
    
    // Trigger event using the same pattern as TouchableOpacity - directly call callback
    private func triggerEvent(view: UIView, eventType: String, eventData: [String: Any]) {
        // Try to get callback using the registered event data
        if let callback = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!) as? (String, String, [String: Any]) -> Void,
           let viewId = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "viewId".hashValue)!) as? String,
           let eventTypes = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!) as? [String] {
            
            if eventTypes.contains(eventType) {
                print("✅ Triggering modal event: \(eventType) for view \(viewId)")
                callback(viewId, eventType, eventData)
            } else {
                print("📱 Modal event \(eventType) not in registered types: \(eventTypes)")
            }
        } else {
            print("📱 Modal event not registered - no handlers found for \(eventType)")
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
            triggerEvent(view: containerView, eventType: "onRequestClose", eventData: [:])
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
            triggerEvent(view: containerView, eventType: "onDismiss", eventData: [:])
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
            // Add default close button on the left
            let closeButton = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(defaultCloseButtonTapped(_:)))
            
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
        
        let button = UIBarButtonItem(title: title, style: style, target: self, action: #selector(headerButtonTapped(_:)))
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
        triggerEvent(view: containerView, eventType: eventType, eventData: [:])
    }
    
    @objc private func defaultCloseButtonTapped(_ sender: UIBarButtonItem) {
        guard let containerView = objc_getAssociatedObject(sender, UnsafeRawPointer(bitPattern: "containerView".hashValue)!) as? UIView else { return }
        
        // Trigger close event - this will dismiss the modal
        triggerEvent(view: containerView, eventType: "onRequestClose", eventData: [:])
    }
}
