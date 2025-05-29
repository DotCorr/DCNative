import UIKit
import dcflight

class DCFContextMenuComponent: NSObject, DCFComponent {
    static let sharedInstance = DCFContextMenuComponent()
    
    // Store event handlers for context menu views
    static var contextMenuEventHandlers = [UIView: (String, [String], (String, String, [String: Any]) -> Void)]()
    
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        let containerView = UIView()
        
        // Apply StyleSheet properties
        containerView.applyStyles(props: props)
        
        // Setup context menu interaction
        if #available(iOS 13.0, *) {
            setupContextMenuInteraction(for: containerView, props: props)
        } else {
            // Fallback to long press gesture for older iOS versions
            setupLongPressGesture(for: containerView, props: props)
        }
        
        // Check if context menu should be shown immediately
        if let visible = props["visible"] as? Bool, visible {
            DispatchQueue.main.async {
                self.showContextMenu(for: containerView, props: props)
            }
        }
        
        return containerView
    }
    
    func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool {
        // Apply StyleSheet properties
        view.applyStyles(props: props)
        
        // Check visible prop to determine if context menu should be shown
        if let visible = props["visible"] as? Bool {
            if visible {
                showContextMenu(for: view, props: props)
            } else {
                hideContextMenu(for: view)
            }
        }
        
        // Update context menu configuration
        if #available(iOS 13.0, *) {
            setupContextMenuInteraction(for: view, props: props)
        } else {
            setupLongPressGesture(for: view, props: props)
        }
        
        return true
    }
    
    @available(iOS 13.0, *)
    private func setupContextMenuInteraction(for view: UIView, props: [String: Any]) {
        // Remove existing interactions
        view.interactions.removeAll { $0 is UIContextMenuInteraction }
        
        let interaction = UIContextMenuInteraction(delegate: self)
        
        // Store props for delegate methods
        objc_setAssociatedObject(
            view,
            UnsafeRawPointer(bitPattern: "contextMenuProps".hashValue)!,
            props,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        view.addInteraction(interaction)
        view.isUserInteractionEnabled = true
    }
    
    private func setupLongPressGesture(for view: UIView, props: [String: Any]) {
        // Remove existing long press gestures
        view.gestureRecognizers?.removeAll { $0 is UILongPressGestureRecognizer }
        
        let longPress = UILongPressGestureRecognizer(target: DCFContextMenuComponent.sharedInstance, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        
        // Store props for gesture handler
        objc_setAssociatedObject(
            view,
            UnsafeRawPointer(bitPattern: "contextMenuProps".hashValue)!,
            props,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        view.addGestureRecognizer(longPress)
        view.isUserInteractionEnabled = true
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let view = gesture.view!
        guard let props = objc_getAssociatedObject(
            view,
            UnsafeRawPointer(bitPattern: "contextMenuProps".hashValue)!
        ) as? [String: Any] else { return }
        
        // Present action sheet as fallback
        presentActionSheet(for: view, props: props)
    }
    
    private func presentActionSheet(for view: UIView, props: [String: Any]) {
        guard let actions = props["actions"] as? [[String: Any]] else { return }
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for actionData in actions {
            guard let title = actionData["title"] as? String else { continue }
            
            let style: UIAlertAction.Style
            if let destructive = actionData["destructive"] as? Bool, destructive {
                style = .destructive
            } else {
                style = .default
            }
            
            let action = UIAlertAction(title: title, style: style) { _ in
                // Trigger onPress event
                self.triggerEventIfRegistered(
                    view,
                    eventType: "onPress",
                    eventData: ["action": actionData]
                )
            }
            
            alertController.addAction(action)
        }
        
        // Add cancel action
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.triggerEventIfRegistered(
                view,
                eventType: "onCancel",
                eventData: [:]
            )
        })
        
        // Present the action sheet
        if let topViewController = UIApplication.shared.windows.first?.rootViewController {
            var presentingController = topViewController
            while let presented = presentingController.presentedViewController {
                presentingController = presented
            }
            
            // Configure popover for iPad
            if let popover = alertController.popoverPresentationController {
                popover.sourceView = view
                popover.sourceRect = view.bounds
            }
            
            presentingController.present(alertController, animated: true)
        }
    }
}

// MARK: - UIContextMenuInteractionDelegate

@available(iOS 13.0, *)
extension DCFContextMenuComponent: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let view = interaction.view!
        
        guard let props = objc_getAssociatedObject(
            view,
            UnsafeRawPointer(bitPattern: "contextMenuProps".hashValue)!
        ) as? [String: Any] else { return nil }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: {
            return self.createPreviewViewController(for: view, props: props)
        }) { _ in
            return self.createContextMenu(for: view, props: props)
        }
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        let view = interaction.view!
        
        // Trigger onPreviewTap event
        self.triggerEventIfRegistered(
            view,
            eventType: "onPreviewTap",
            eventData: [:]
        )
    }
    
    private func createPreviewViewController(for view: UIView, props: [String: Any]) -> UIViewController? {
        guard let previewType = props["previewType"] as? String else { return nil }
        
        if previewType == "none" { return nil }
        
        let previewVC = UIViewController()
        let previewView = UIView()
        
        // Configure preview appearance
        if let backgroundColor = props["previewBackgroundColor"] as? String {
            previewView.backgroundColor = ColorUtilities.color(fromHexString: backgroundColor)
        } else {
            previewView.backgroundColor = UIColor.systemBackground
        }
        
        if let borderRadius = props["previewBorderRadius"] as? CGFloat {
            previewView.layer.cornerRadius = borderRadius
        }
        
        previewVC.view = previewView
        previewVC.preferredContentSize = view.frame.size
        
        return previewVC
    }
    
    private func createContextMenu(for view: UIView, props: [String: Any]) -> UIMenu {
        guard let actions = props["actions"] as? [[String: Any]] else {
            return UIMenu(title: "", children: [])
        }
        
        let menuActions = actions.compactMap { actionData -> UIAction? in
            guard let title = actionData["title"] as? String else { return nil }
            
            var attributes: UIAction.Attributes = []
            if let destructive = actionData["destructive"] as? Bool, destructive {
                attributes.insert(.destructive)
            }
            
            var image: UIImage?
            if let systemIcon = actionData["systemIcon"] as? String {
                image = UIImage(systemName: systemIcon)
            }
            
            return UIAction(title: title, image: image, attributes: attributes) { _ in
                // Trigger onPress event
                self.triggerEventIfRegistered(
                    view,
                    eventType: "onPress",
                    eventData: ["action": actionData]
                )
            }
        }
        
        return UIMenu(title: "", children: menuActions)
    }
    
    // Trigger event if the view has been registered for that event type
    private func triggerEventIfRegistered(_ view: UIView, eventType: String, eventData: [String: Any]) {
        // Try handlers dictionary first
        if let (viewId, eventTypes, callback) = DCFContextMenuComponent.contextMenuEventHandlers[view] {
            if eventTypes.contains(eventType) {
                print("✅ Triggering ContextMenu event: \(eventType) for view \(viewId)")
                callback(viewId, eventType, eventData)
                return
            }
        }
        
        // Fallback to associated objects
        guard let eventTypes = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!) as? [String],
              let callback = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!) as? (String, String, [String: Any]) -> Void,
              let viewId = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "viewId".hashValue)!) as? String else {
            print("📋 ContextMenu event not registered - no handlers found for \(eventType)")
            return
        }
        
        if eventTypes.contains(eventType) {
            print("✅ Triggering ContextMenu event (fallback): \(eventType) for view \(viewId)")
            callback(viewId, eventType, eventData)
        } else {
            print("📋 ContextMenu event \(eventType) not in registered types: \(eventTypes)")
        }
    }
}

// MARK: - Event Handling Implementation
extension DCFContextMenuComponent {
    func addEventListeners(to view: UIView, viewId: String, eventTypes: [String], 
                          eventCallback: @escaping (String, String, [String: Any]) -> Void) {
        print("📋 Adding ContextMenu event listeners to view \(viewId): \(eventTypes)")
        
        // Store event registration info
        DCFContextMenuComponent.contextMenuEventHandlers[view] = (viewId, eventTypes, eventCallback)
        
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
        
        print("✅ Successfully registered ContextMenu event handlers for view \(viewId)")
    }
    
    func removeEventListeners(from view: UIView, viewId: String, eventTypes: [String]) {
        print("📋 Removing ContextMenu event listeners from view \(viewId): \(eventTypes)")
        
        // Remove from handlers dictionary
        DCFContextMenuComponent.contextMenuEventHandlers.removeValue(forKey: view)
        
        // Clean up associated objects
        objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "viewId".hashValue)!, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        print("✅ Removed ContextMenu event handlers for view \(viewId)")
    }
}

// MARK: - Programmatic Context Menu Control

extension DCFContextMenuComponent {
    private func showContextMenu(for view: UIView, props: [String: Any]) {
        // For iOS 13+ with UIContextMenuInteraction
        if #available(iOS 13.0, *) {
            // Context menus are typically shown on user interaction
            // For programmatic showing, we can trigger the menu items selection directly
            self.triggerEventIfRegistered(
                view,
                eventType: "onShow",
                eventData: [:]
            )
        } else {
            // For older iOS versions, show a custom action sheet
            showActionSheet(for: view, props: props)
        }
    }
    
    private func hideContextMenu(for view: UIView) {
        // Context menus auto-hide when dismissed
        // Trigger hide event
        self.triggerEventIfRegistered(
            view,
            eventType: "onHide",
            eventData: [:]
        )
    }
    
    private func showActionSheet(for view: UIView, props: [String: Any]) {
        guard let items = props["items"] as? [[String: Any]] else { return }
        
        let alertController = UIAlertController(title: props["title"] as? String, 
                                              message: nil, 
                                              preferredStyle: .actionSheet)
        
        for (index, item) in items.enumerated() {
            let title = item["title"] as? String ?? "Item \(index)"
            let action = UIAlertAction(title: title, style: .default) { _ in
                self.triggerEventIfRegistered(
                    view,
                    eventType: "onItemPress",
                    eventData: [
                        "index": index,
                        "title": title
                    ]
                )
            }
            alertController.addAction(action)
        }
        
        // Add cancel action
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Present the action sheet
        if let topViewController = UIApplication.shared.windows.first?.rootViewController {
            var presentingController = topViewController
            while let presented = presentingController.presentedViewController {
                presentingController = presented
            }
            presentingController.present(alertController, animated: true)
        }
    }
}
