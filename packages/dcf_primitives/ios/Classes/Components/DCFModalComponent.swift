import UIKit
import dcflight

class DCFModalComponent: NSObject, DCFComponent {
    private static var activeModals: [UIView: UIViewController] = [:]
    
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        // Modal container view
        let containerView = UIView()
        containerView.backgroundColor = UIColor.clear
        
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
        
        return true
    }
    
    private func presentModal(for view: UIView, props: [String: Any]) {
        // Don't present if already presented
        if DCFModalComponent.activeModals[view] != nil { return }
        
        let modalViewController = UIViewController()
        let modalView = UIView()
        
        // Configure modal view
        if let backgroundColor = props["backgroundColor"] as? String {
            modalView.backgroundColor = ColorUtilities.color(fromHexString: backgroundColor)
        } else if let transparent = props["transparent"] as? Bool, transparent {
            modalView.backgroundColor = UIColor.clear
        } else {
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
        
        // Store reference
        DCFModalComponent.activeModals[view] = modalViewController
        
        // Present modal
        if let topViewController = UIApplication.shared.windows.first?.rootViewController {
            var presentingController = topViewController
            while let presented = presentingController.presentedViewController {
                presentingController = presented
            }
            
            presentingController.present(modalViewController, animated: true) {
                // Trigger onShow event
                self.triggerEvent(view: view, eventType: "onShow", data: [:])
            }
        }
    }
    
    private func dismissModal(for view: UIView) {
        guard let modalViewController = DCFModalComponent.activeModals[view] else { return }
        
        modalViewController.dismiss(animated: true) {
            // Clean up reference
            DCFModalComponent.activeModals.removeValue(forKey: view)
            
            // Trigger onDismiss event
            self.triggerEvent(view: view, eventType: "onDismiss", data: [:])
        }
    }
    
    private func triggerEvent(view: UIView, eventType: String, data: [String: Any]) {
        self.triggerEvent(
            on: view,
            eventType: eventType,
            eventData: data
        )
    }
}
