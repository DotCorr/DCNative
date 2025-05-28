import UIKit
import dcflight

class DCFContextMenuComponent: NSObject, DCFComponent {
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        let containerView = UIView()
        
        // Setup context menu interaction
        if #available(iOS 13.0, *) {
            setupContextMenuInteraction(for: containerView, props: props)
        } else {
            // Fallback to long press gesture for older iOS versions
            setupLongPressGesture(for: containerView, props: props)
        }
        
        return containerView
    }
    
    func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool {
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
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
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
                DCFComponent.triggerEvent(
                    from: view,
                    eventType: "onPress",
                    eventData: ["action": actionData]
                )
            }
            
            alertController.addAction(action)
        }
        
        // Add cancel action
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            DCFComponent.triggerEvent(
                from: view,
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
        DCFComponent.triggerEvent(
            from: view,
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
            
            let attributes: UIAction.Attributes = []
            if let destructive = actionData["destructive"] as? Bool, destructive {
                attributes.insert(.destructive)
            }
            
            var image: UIImage?
            if let systemIcon = actionData["systemIcon"] as? String {
                image = UIImage(systemName: systemIcon)
            }
            
            return UIAction(title: title, image: image, attributes: attributes) { _ in
                // Trigger onPress event
                DCFComponent.triggerEvent(
                    from: view,
                    eventType: "onPress",
                    eventData: ["action": actionData]
                )
            }
        }
        
        return UIMenu(title: "", children: menuActions)
    }
}
