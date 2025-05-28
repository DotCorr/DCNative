import UIKit
import dcflight

class DCFAlertComponent: NSObject, DCFComponent {
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        // Alert doesn't create a view - it's presented directly
        // We'll return a transparent view as a placeholder
        let placeholderView = UIView()
        placeholderView.isHidden = true
        placeholderView.alpha = 0
        
        // Trigger alert presentation after a small delay
        DispatchQueue.main.async {
            self.presentAlert(props: props)
        }
        
        return placeholderView
    }
    
    func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool {
        // For alerts, updates mean presenting a new alert
        presentAlert(props: props)
        return true
    }
    
    private func presentAlert(props: [String: Any]) {
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
                    // Trigger callback with action index
                    if let index = actionData["index"] as? Int {
                        self.triggerEvent(
                            viewId: props["viewId"] as? String ?? "",
                            eventType: "onPress",
                            data: ["actionIndex": index]
                        )
                    }
                }
                
                alertController.addAction(action)
            }
        }
        
        // Present the alert
        if let topViewController = UIApplication.shared.windows.first?.rootViewController {
            var presentingController = topViewController
            while let presented = presentingController.presentedViewController {
                presentingController = presented
            }
            presentingController.present(alertController, animated: true)
        }
    }
    
    private func triggerEvent(viewId: String, eventType: String, data: [String: Any]) {
        // Use the standard event triggering mechanism
        self.triggerEvent(
            on: UIView(), // Placeholder view
            eventType: eventType,
            eventData: data
        )
    }
}
