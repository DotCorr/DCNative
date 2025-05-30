import UIKit
import dcflight

// Modal container view - always hidden, zero-size container
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
        frame = CGRect.zero
    }
}

// Enhanced modal presentation controller for iOS 15+ features
@available(iOS 15.0, *)
class DCFSheetPresentationController: UISheetPresentationController {
    weak var modalComponent: DCFModalComponent?
    weak var modalContainerView: UIView?  // Renamed to avoid property override conflict
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        // Notify modal component of presentation start
        if let modalContainerView = modalContainerView {
            modalComponent?.triggerEvent(modalContainerView, eventType: "onShow", eventData: [:])
        }
    }
}

// Modal transition delegate for enhanced control
class DCFModalTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    weak var modalComponent: DCFModalComponent?
    weak var modalContainerView: UIView?  // Renamed to avoid conflicts
    var configuration: [String: Any] = [:]
    
    func presentationController(forPresented presented: UIViewController,
                              presenting: UIViewController?,
                              source: UIViewController) -> UIPresentationController? {
        
        if #available(iOS 15.0, *) {
            let controller = DCFSheetPresentationController(presentedViewController: presented, presenting: presenting)
            controller.modalComponent = modalComponent
            controller.modalContainerView = modalContainerView
            
            // Configure sheet detents
            configureSheetDetents(controller)
            
            // Configure other properties
            configureSheetProperties(controller)
            
            return controller
        } else {
            // Fallback for older iOS versions
            return UIPresentationController(presentedViewController: presented, presenting: presenting)
        }
    }
    
    @available(iOS 15.0, *)
    private func configureSheetDetents(_ controller: DCFSheetPresentationController) {
        var detents: [UISheetPresentationController.Detent] = []
        
        if let detentsConfig = configuration["detents"] as? [String] {
            for detentName in detentsConfig {
                switch detentName {
                case "small":
                    if #available(iOS 16.0, *) {
                        detents.append(.custom(resolver: { _ in return 200 }))
                    } else {
                        detents.append(.medium())
                    }
                case "medium":
                    detents.append(.medium())
                case "large":
                    detents.append(.large())
                case "custom":
                    if let customHeight = configuration["customDetentHeight"] as? CGFloat {
                        if #available(iOS 16.0, *) {
                            detents.append(.custom(resolver: { _ in return customHeight }))
                        } else {
                            detents.append(.medium())
                        }
                    }
                default:
                    detents.append(.large())
                }
            }
        }
        
        controller.detents = detents.isEmpty ? [.large()] : detents
        
        // Set initial selected detent
        if let selectedDetent = configuration["selectedDetent"] as? String {
            switch selectedDetent {
            case "medium":
                controller.selectedDetentIdentifier = .medium
            case "large":
                controller.selectedDetentIdentifier = .large
            default:
                break
            }
        }
    }
    
    @available(iOS 15.0, *)
    private func configureSheetProperties(_ controller: DCFSheetPresentationController) {
        // Configure dismissal behavior - KEY FIX: Allow native dismissal by default
        if let isDismissible = configuration["isDismissible"] as? Bool {
            controller.presentedViewController.isModalInPresentation = !isDismissible
        } else {
            controller.presentedViewController.isModalInPresentation = false // Allow native dismissal by default
        }
        
        // Configure drag indicator
        if let showDragIndicator = configuration["showDragIndicator"] as? Bool {
            controller.prefersGrabberVisible = showDragIndicator
        } else {
            controller.prefersGrabberVisible = true // Show by default
        }
        
        // Configure scrolling expansion
        if let prefersScrollingExpands = configuration["prefersScrollingExpandsWhenScrolledToEdge"] as? Bool {
            controller.prefersScrollingExpandsWhenScrolledToEdge = prefersScrollingExpands
        }
        
        // Configure edge attachment
        if let prefersEdgeAttached = configuration["prefersEdgeAttachedInCompactHeight"] as? Bool {
            controller.prefersEdgeAttachedInCompactHeight = prefersEdgeAttached
        }
        
        // Configure corner radius
        if let cornerRadius = configuration["cornerRadius"] as? CGFloat {
            controller.preferredCornerRadius = cornerRadius
        }
    }
}

class DCFModalComponent: NSObject, DCFComponent, UIAdaptivePresentationControllerDelegate {
    private static var activeModals: [UIView: (UIViewController, UIView)] = [:]
    private static var transitionDelegates: [UIView: DCFModalTransitioningDelegate] = [:]
    private static let sharedInstance = DCFModalComponent()
    
    // Static storage for modal event handlers
    private static var modalEventHandlers = [UIView: (String, (String, String, [String: Any]) -> Void)]()
    
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        // Create zero-size hidden container view
        let containerView = DCFModalContainerView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Enforce zero size constraints
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
        
        // Create modal content view with proper layout support
        let modalView = createModalContentView(props: props)
        let modalViewController = createModalViewController(modalView: modalView, props: props, containerView: view)
        
        // Configure presentation style and advanced features
        configureModalPresentation(modalViewController, props: props, containerView: view)
        
        // Store reference
        DCFModalComponent.activeModals[view] = (modalViewController, modalView)
        
        // Move children from container to modal
        moveChildrenToModal(from: view, to: modalView)
        
        // Present modal
        presentModalViewController(modalViewController, containerView: view)
    }
    
    private func createModalContentView(props: [String: Any]) -> UIView {
        let modalView = UIView()
        
        // Configure background - direct property application, NOT applyStyles
        if let transparent = props["transparent"] as? Bool, transparent {
            modalView.backgroundColor = UIColor.clear
        } else if let bgColor = props["backgroundColor"] as? String {
            modalView.backgroundColor = ColorUtilities.color(fromHexString: bgColor)
        } else {
            modalView.backgroundColor = UIColor.systemBackground
        }
        
        // Apply border radius directly - NOT through applyStyles
        if let borderRadius = props["borderRadius"] as? Double {
            modalView.layer.cornerRadius = CGFloat(borderRadius)
            modalView.layer.masksToBounds = true
        }
        
        // Ensure modal view fills its container properly
        modalView.translatesAutoresizingMaskIntoConstraints = false
        
        return modalView
    }
    
    private func createModalViewController(modalView: UIView, props: [String: Any], containerView: UIView) -> UIViewController {
        let modalViewController: UIViewController
        
        // Check if header is specified
        if let headerProps = props["header"] as? [String: Any] {
            // Create navigation controller with header
            let contentViewController = UIViewController()
            contentViewController.view = modalView
            
            let navigationController = UINavigationController(rootViewController: contentViewController)
            
            // Apply border radius to navigation controller if specified
            if let borderRadius = props["borderRadius"] as? Double {
                navigationController.view.layer.cornerRadius = CGFloat(borderRadius)
                navigationController.view.layer.masksToBounds = true
            }
            
            // Configure header
            setupModalHeader(navigationController: navigationController,
                           contentViewController: contentViewController,
                           headerProps: headerProps,
                           containerView: containerView)
            
            modalViewController = navigationController
        } else {
            // Plain view controller
            let plainViewController = UIViewController()
            plainViewController.view = modalView
            modalViewController = plainViewController
        }
        
        // Store container view reference for callbacks
        objc_setAssociatedObject(modalViewController,
                               UnsafeRawPointer(bitPattern: "containerView".hashValue)!,
                               containerView,
                               .OBJC_ASSOCIATION_ASSIGN)
        
        return modalViewController
    }
    
    private func configureModalPresentation(_ modalViewController: UIViewController, props: [String: Any], containerView: UIView) {
        // Configure basic presentation style
        if let presentationStyle = props["presentationStyle"] as? String {
            switch presentationStyle {
            case "fullScreen":
                modalViewController.modalPresentationStyle = .fullScreen
            case "pageSheet":
                modalViewController.modalPresentationStyle = .pageSheet
                
                // Use enhanced features for pageSheet on iOS 15+
                if #available(iOS 15.0, *) {
                    setupEnhancedPageSheet(modalViewController, props: props, containerView: containerView)
                }
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
        
        // Configure dismissal behavior - KEY FIX: Allow native dismissal by default
        if let isDismissible = props["isDismissible"] as? Bool {
            modalViewController.isModalInPresentation = !isDismissible
        } else {
            modalViewController.isModalInPresentation = false // Allow dismissal by default
        }
    }
    
    @available(iOS 15.0, *)
    private func setupEnhancedPageSheet(_ modalViewController: UIViewController, props: [String: Any], containerView: UIView) {
        let transitionDelegate = DCFModalTransitioningDelegate()
        transitionDelegate.modalComponent = self
        transitionDelegate.modalContainerView = containerView
        
        // Build configuration from props
        var config: [String: Any] = [:]
        
        // Extract sheet configuration
        if let sheetConfig = props["sheetConfiguration"] as? [String: Any] {
            config = sheetConfig
        }
        
        // Add other relevant props to config
        if let isDismissible = props["isDismissible"] as? Bool {
            config["isDismissible"] = isDismissible
        }
        
        if let borderRadius = props["borderRadius"] as? Double {
            config["cornerRadius"] = CGFloat(borderRadius)
        }
        
        transitionDelegate.configuration = config
        modalViewController.transitioningDelegate = transitionDelegate
        
        // Store delegate to prevent deallocation
        DCFModalComponent.transitionDelegates[containerView] = transitionDelegate
    }
    
    private func presentModalViewController(_ modalViewController: UIViewController, containerView: UIView) {
        guard let topViewController = UIApplication.shared.windows.first?.rootViewController else { return }
        
        var presentingController = topViewController
        while let presented = presentingController.presentedViewController {
            presentingController = presented
        }
        
        presentingController.present(modalViewController, animated: true) {
            // Set up presentation controller delegate
            modalViewController.presentationController?.delegate = DCFModalComponent.sharedInstance
            
            // Trigger onShow event
            self.triggerEvent(containerView, eventType: "onShow", eventData: [:])
        }
    }
    
    private func dismissModal(for view: UIView) {
        guard let (modalViewController, modalView) = DCFModalComponent.activeModals[view] else { return }
        
        // Move children back to container
        moveChildrenBackToContainer(from: modalView, to: view)
        
        // Ensure container stays hidden
        view.isHidden = true
        view.alpha = 0
        view.frame = CGRect.zero
        
        // Mark as programmatic dismissal
        objc_setAssociatedObject(modalViewController,
                               UnsafeRawPointer(bitPattern: "programmaticDismissal".hashValue)!,
                               true,
                               .OBJC_ASSOCIATION_RETAIN)
        
        modalViewController.dismiss(animated: true) {
            // Clean up references
            DCFModalComponent.activeModals.removeValue(forKey: view)
            DCFModalComponent.transitionDelegates.removeValue(forKey: view)
            
            // Trigger onDismiss event
            self.triggerEvent(view, eventType: "onDismiss", eventData: [:])
        }
    }
    
    // Move children ensuring proper layout constraints
    private func moveChildrenToModal(from containerView: UIView, to modalView: UIView) {
        let children = containerView.subviews
        for child in children {
            child.removeFromSuperview()
            modalView.addSubview(child)
            
            // Ensure child fills modal view if it has flex: 1 or similar layout
            if child.translatesAutoresizingMaskIntoConstraints == false {
                // Re-establish constraints relative to modal view
                NSLayoutConstraint.activate([
                    child.topAnchor.constraint(equalTo: modalView.safeAreaLayoutGuide.topAnchor),
                    child.leadingAnchor.constraint(equalTo: modalView.leadingAnchor),
                    child.trailingAnchor.constraint(equalTo: modalView.trailingAnchor),
                    child.bottomAnchor.constraint(equalTo: modalView.bottomAnchor)
                ])
            } else {
                // For frame-based layout, ensure it fills the modal
                child.frame = modalView.bounds
                child.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            }
        }
        
        print("📱 Moved \(children.count) children to modal view with proper layout")
    }
    
    private func moveChildrenBackToContainer(from modalView: UIView, to containerView: UIView) {
        let children = modalView.subviews
        for child in children {
            child.removeFromSuperview()
            containerView.addSubview(child)
        }
        
        // Container stays hidden
        containerView.isHidden = true
        containerView.alpha = 0
        containerView.frame = CGRect.zero
        
        print("📱 Moved \(children.count) children back to container view")
    }
    
    // Trigger event using multiple backup methods
    func triggerEvent(_ view: UIView, eventType: String, eventData: [String: Any]) {
        if tryDirectHandling(view, eventType: eventType, eventData: eventData) ||
           tryStaticDictionaryHandling(view, eventType: eventType, eventData: eventData) ||
           tryAssociatedObjectHandling(view, eventType: eventType, eventData: eventData) {
            // Success
        } else {
            print("📱 Modal event \(eventType) not registered - no callback found")
        }
    }
    
    private func tryDirectHandling(_ view: UIView, eventType: String, eventData: [String: Any]) -> Bool {
        if let viewId = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "modalViewId".hashValue)!) as? String,
           let callback = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "modalCallback".hashValue)!) as? (String, String, [String: Any]) -> Void {
            callback(viewId, eventType, eventData)
            return true
        }
        return false
    }
    
    private func tryStaticDictionaryHandling(_ view: UIView, eventType: String, eventData: [String: Any]) -> Bool {
        if let (viewId, callback) = DCFModalComponent.modalEventHandlers[view] {
            callback(viewId, eventType, eventData)
            return true
        }
        return false
    }
    
    private func tryAssociatedObjectHandling(_ view: UIView, eventType: String, eventData: [String: Any]) -> Bool {
        let key = "modal_callback_\(eventType)"
        if let callback = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: key.hashValue)!) as? (String, String, [String: Any]) -> Void,
           let viewId = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "modal_viewId".hashValue)!) as? String {
            callback(viewId, eventType, eventData)
            return true
        }
        return false
    }
    
    // MARK: - Event Handling Implementation
    
    func addEventListeners(to view: UIView, viewId: String, eventTypes: [String],
                           eventCallback: @escaping (String, String, [String: Any]) -> Void) {
        storeEventData(on: view, viewId: viewId, eventTypes: eventTypes, callback: eventCallback)
    }
    
    private func storeEventData(on view: UIView, viewId: String, eventTypes: [String],
                               callback: @escaping (String, String, [String: Any]) -> Void) {
        // Store individual callbacks
        for eventType in eventTypes {
            let key = "modal_callback_\(eventType)"
            objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: key.hashValue)!, callback, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        // Store view ID
        objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "modal_viewId".hashValue)!, viewId, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "modalViewId".hashValue)!, viewId, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: "modalCallback".hashValue)!, callback, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Store in static dictionary
        DCFModalComponent.modalEventHandlers[view] = (viewId, callback)
    }
    
    func removeEventListeners(from view: UIView, viewId: String, eventTypes: [String]) {
        cleanupEventReferences(from: view)
    }
    
    private func cleanupEventReferences(from view: UIView) {
        DCFModalComponent.modalEventHandlers.removeValue(forKey: view)
        
        let keys = ["modal_viewId", "modalViewId", "modalCallback",
                   "modal_callback_onShow", "modal_callback_onDismiss",
                   "modal_callback_onRequestClose", "modal_callback_onLeftButtonPress",
                   "modal_callback_onRightButtonPress"]
        for key in keys {
            objc_setAssociatedObject(view, UnsafeRawPointer(bitPattern: key.hashValue)!, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension DCFModalComponent {
    
    // Called when user tries to dismiss modal with gesture
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        guard let containerView = objc_getAssociatedObject(
            presentationController.presentedViewController,
            UnsafeRawPointer(bitPattern: "containerView".hashValue)!
        ) as? UIView else { return true }
        
        // Check if dismissal is explicitly disabled
        if let transitionDelegate = DCFModalComponent.transitionDelegates[containerView],
           let isDismissible = transitionDelegate.configuration["isDismissible"] as? Bool,
           !isDismissible {
            // Trigger onRequestClose but prevent dismissal
            triggerEvent(containerView, eventType: "onRequestClose", eventData: [:])
            return false
        }
        
        // Allow native dismissal by default (this fixes the swipe-to-dismiss issue)
        return true
    }
    
    // Called when modal is actually dismissed
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard let containerView = objc_getAssociatedObject(
            presentationController.presentedViewController,
            UnsafeRawPointer(bitPattern: "containerView".hashValue)!
        ) as? UIView else { return }
        
        // Check if this was programmatic dismissal
        let wasProgrammaticDismissal = objc_getAssociatedObject(
            presentationController.presentedViewController,
            UnsafeRawPointer(bitPattern: "programmaticDismissal".hashValue)!
        ) as? Bool ?? false
        
        // Clean up references
        DCFModalComponent.activeModals.removeValue(forKey: containerView)
        DCFModalComponent.transitionDelegates.removeValue(forKey: containerView)
        
        // Move children back
        if let modalView = presentationController.presentedViewController.view {
            moveChildrenBackToContainer(from: modalView, to: containerView)
        }
        
        // Only trigger onDismiss if this was NOT programmatic
        if !wasProgrammaticDismissal {
            triggerEvent(containerView, eventType: "onDismiss", eventData: [:])
        }
        
        // Clean up dismissal flag
        objc_setAssociatedObject(
            presentationController.presentedViewController,
            UnsafeRawPointer(bitPattern: "programmaticDismissal".hashValue)!,
            nil,
            .OBJC_ASSOCIATION_RETAIN
        )
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
        
        // Configure title
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
                
                let weight = fontWeightFromString(fontWeight)
                let font = UIFont.systemFont(ofSize: currentSize, weight: weight)
                
                attributes[.font] = font
                navigationBar.titleTextAttributes = attributes
            }
        }
        
        // Configure left button
        if let leftButtonProps = headerProps["leftButton"] as? [String: Any] {
            let leftButton = createHeaderButton(buttonProps: leftButtonProps, containerView: containerView, isLeftButton: true)
            contentViewController.navigationItem.leftBarButtonItem = leftButton
        } else if let showCloseButton = headerProps["showCloseButton"] as? Bool, showCloseButton {
            let closeButton = UIBarButtonItem(title: "Close", style: .plain, target: DCFModalComponent.sharedInstance, action: #selector(defaultCloseButtonTapped(_:)))
            
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
        default:
            style = .plain
        }
        
        let button = UIBarButtonItem(title: title, style: style, target: DCFModalComponent.sharedInstance, action: #selector(headerButtonTapped(_:)))
        button.isEnabled = enabled
        
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
        
        triggerEvent(containerView, eventType: "onRequestClose", eventData: [:])
    }
}

// MARK: - Utility Functions

extension DCFModalComponent {
    
    private func fontWeightFromString(_ fontWeight: String) -> UIFont.Weight {
        switch fontWeight.lowercased() {
        case "ultralight", "100":
            return .ultraLight
        case "thin", "200":
            return .thin
        case "light", "300":
            return .light
        case "regular", "normal", "400":
            return .regular
        case "medium", "500":
            return .medium
        case "semibold", "600":
            return .semibold
        case "bold", "700":
            return .bold
        case "heavy", "800":
            return .heavy
        case "black", "900":
            return .black
        default:
            return .regular
        }
    }
}
