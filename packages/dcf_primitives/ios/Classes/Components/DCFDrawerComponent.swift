import UIKit
import dcflight

class DCFDrawerComponent: NSObject, DCFComponent {
    private static var activeDrawers: [UIView: DrawerViewController] = [:]
    
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.clear
        
        // Create drawer setup
        setupDrawer(for: containerView, props: props)
        
        return containerView
    }
    
    func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool {
        if let open = props["open"] as? Bool {
            if open {
                openDrawer(for: view, props: props)
            } else {
                closeDrawer(for: view)
            }
        }
        
        return true
    }
    
    private func setupDrawer(for view: UIView, props: [String: Any]) {
        // Create drawer view controller if it doesn't exist
        if DCFDrawerComponent.activeDrawers[view] == nil {
            let drawerVC = DrawerViewController()
            DCFDrawerComponent.activeDrawers[view] = drawerVC
            
            // Configure drawer properties
            updateDrawerProperties(drawerVC, props: props)
        }
    }
    
    private func updateDrawerProperties(_ drawerVC: DrawerViewController, props: [String: Any]) {
        // Set drawer position
        if let position = props["position"] as? String {
            drawerVC.position = mapDrawerPosition(position)
        }
        
        // Set drawer width
        if let width = props["drawerWidth"] as? CGFloat {
            drawerVC.drawerWidth = width
        }
        
        // Set background color
        if let backgroundColor = props["drawerBackgroundColor"] as? String {
            drawerVC.drawerBackgroundColor = ColorUtilities.color(fromHexString: backgroundColor)
        }
        
        // Set swipe enabled
        if let swipeEnabled = props["swipeEnabled"] as? Bool {
            drawerVC.swipeEnabled = swipeEnabled
        }
        
        // Set edge width for swipe gesture
        if let edgeWidth = props["edgeWidth"] as? CGFloat {
            drawerVC.edgeWidth = edgeWidth
        }
    }
    
    private func openDrawer(for view: UIView, props: [String: Any]) {
        guard let drawerVC = DCFDrawerComponent.activeDrawers[view] else { return }
        
        updateDrawerProperties(drawerVC, props: props)
        
        if let topViewController = UIApplication.shared.windows.first?.rootViewController {
            var presentingController = topViewController
            while let presented = presentingController.presentedViewController {
                presentingController = presented
            }
            
            drawerVC.present(from: presentingController) {
                // Trigger onDrawerOpen event
                DCFComponent.triggerEvent(
                    from: view,
                    eventType: "onDrawerOpen",
                    eventData: [:]
                )
            }
        }
    }
    
    private func closeDrawer(for view: UIView) {
        guard let drawerVC = DCFDrawerComponent.activeDrawers[view] else { return }
        
        drawerVC.dismiss {
            // Trigger onDrawerClose event
            DCFComponent.triggerEvent(
                from: view,
                eventType: "onDrawerClose",
                eventData: [:]
            )
        }
    }
    
    private func mapDrawerPosition(_ position: String) -> DrawerPosition {
        switch position {
        case "right":
            return .right
        case "top":
            return .top
        case "bottom":
            return .bottom
        default:
            return .left
        }
    }
}

// MARK: - Drawer Position Enum

enum DrawerPosition {
    case left, right, top, bottom
}

// MARK: - Drawer View Controller

class DrawerViewController: UIViewController {
    var position: DrawerPosition = .left
    var drawerWidth: CGFloat = 280
    var drawerBackgroundColor: UIColor = UIColor.white
    var swipeEnabled: Bool = true
    var edgeWidth: CGFloat = 20
    
    private var drawerView: UIView!
    private var overlayView: UIView!
    private var panGesture: UIPanGestureRecognizer!
    private var edgePanGesture: UIScreenEdgePanGestureRecognizer!
    private var isPresented: Bool = false
    
    private var onDismiss: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDrawer()
    }
    
    private func setupDrawer() {
        // Create overlay
        overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.alpha = 0
        view.addSubview(overlayView)
        
        // Create drawer
        drawerView = UIView()
        drawerView.backgroundColor = drawerBackgroundColor
        view.addSubview(drawerView)
        
        // Setup gestures
        setupGestures()
        
        // Position drawer off-screen initially
        positionDrawerOffScreen()
    }
    
    private func setupGestures() {
        // Pan gesture for drawer
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        drawerView.addGestureRecognizer(panGesture)
        
        // Edge pan gesture for opening
        edgePanGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
        edgePanGesture.edges = getEdgeForPosition()
        view.addGestureRecognizer(edgePanGesture)
        
        // Tap gesture for overlay
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOverlayTap))
        overlayView.addGestureRecognizer(tapGesture)
    }
    
    private func getEdgeForPosition() -> UIRectEdge {
        switch position {
        case .left:
            return .left
        case .right:
            return .right
        case .top:
            return .top
        case .bottom:
            return .bottom
        }
    }
    
    private func positionDrawerOffScreen() {
        let screenBounds = view.bounds
        
        switch position {
        case .left:
            drawerView.frame = CGRect(x: -drawerWidth, y: 0, width: drawerWidth, height: screenBounds.height)
        case .right:
            drawerView.frame = CGRect(x: screenBounds.width, y: 0, width: drawerWidth, height: screenBounds.height)
        case .top:
            drawerView.frame = CGRect(x: 0, y: -drawerWidth, width: screenBounds.width, height: drawerWidth)
        case .bottom:
            drawerView.frame = CGRect(x: 0, y: screenBounds.height, width: screenBounds.width, height: drawerWidth)
        }
    }
    
    func present(from viewController: UIViewController, completion: (() -> Void)? = nil) {
        viewController.present(self, animated: false) {
            self.animateIn(completion: completion)
        }
    }
    
    func dismiss(completion: (() -> Void)? = nil) {
        onDismiss = completion
        animateOut {
            self.dismiss(animated: false, completion: completion)
        }
    }
    
    private func animateIn(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.overlayView.alpha = 1
            self.positionDrawerOnScreen()
        }) { _ in
            self.isPresented = true
            completion?()
        }
    }
    
    private func animateOut(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.overlayView.alpha = 0
            self.positionDrawerOffScreen()
        }) { _ in
            self.isPresented = false
            completion?()
        }
    }
    
    private func positionDrawerOnScreen() {
        let screenBounds = view.bounds
        
        switch position {
        case .left:
            drawerView.frame = CGRect(x: 0, y: 0, width: drawerWidth, height: screenBounds.height)
        case .right:
            drawerView.frame = CGRect(x: screenBounds.width - drawerWidth, y: 0, width: drawerWidth, height: screenBounds.height)
        case .top:
            drawerView.frame = CGRect(x: 0, y: 0, width: screenBounds.width, height: drawerWidth)
        case .bottom:
            drawerView.frame = CGRect(x: 0, y: screenBounds.height - drawerWidth, width: screenBounds.width, height: drawerWidth)
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        if !swipeEnabled { return }
        
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            updateDrawerPosition(with: translation)
        case .ended:
            let shouldDismiss = shouldDismissBasedOnVelocity(velocity) || shouldDismissBasedOnPosition()
            if shouldDismiss {
                dismiss()
            } else {
                animateIn()
            }
        default:
            break
        }
    }
    
    @objc private func handleEdgePan(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if !swipeEnabled { return }
        
        let translation = gesture.translation(in: view)
        
        switch gesture.state {
        case .changed:
            updateDrawerPosition(with: translation)
        case .ended:
            let velocity = gesture.velocity(in: view)
            let shouldOpen = shouldOpenBasedOnVelocity(velocity) || shouldOpenBasedOnPosition()
            if shouldOpen {
                animateIn()
            } else {
                animateOut()
            }
        default:
            break
        }
    }
    
    @objc private func handleOverlayTap() {
        dismiss()
    }
    
    private func updateDrawerPosition(with translation: CGPoint) {
        // Implementation depends on drawer position
        // This is a simplified version
        switch position {
        case .left:
            let newX = min(0, max(-drawerWidth, translation.x - drawerWidth))
            drawerView.frame.origin.x = newX
        case .right:
            let newX = max(view.bounds.width - drawerWidth, min(view.bounds.width, view.bounds.width - drawerWidth + translation.x))
            drawerView.frame.origin.x = newX
        default:
            break
        }
        
        // Update overlay alpha based on drawer position
        let progress = calculateProgress()
        overlayView.alpha = progress
    }
    
    private func calculateProgress() -> CGFloat {
        switch position {
        case .left:
            return 1.0 - abs(drawerView.frame.origin.x) / drawerWidth
        case .right:
            return 1.0 - (drawerView.frame.origin.x - (view.bounds.width - drawerWidth)) / drawerWidth
        default:
            return 1.0
        }
    }
    
    private func shouldDismissBasedOnVelocity(_ velocity: CGPoint) -> Bool {
        switch position {
        case .left:
            return velocity.x < -500
        case .right:
            return velocity.x > 500
        case .top:
            return velocity.y < -500
        case .bottom:
            return velocity.y > 500
        }
    }
    
    private func shouldDismissBasedOnPosition() -> Bool {
        return calculateProgress() < 0.5
    }
    
    private func shouldOpenBasedOnVelocity(_ velocity: CGPoint) -> Bool {
        switch position {
        case .left:
            return velocity.x > 500
        case .right:
            return velocity.x < -500
        case .top:
            return velocity.y > 500
        case .bottom:
            return velocity.y < -500
        }
    }
    
    private func shouldOpenBasedOnPosition() -> Bool {
        return calculateProgress() > 0.5
    }
}
