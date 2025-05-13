import UIKit
import dcflight

/// Component that handles touchable opacity functionality
class DCFTouchableOpacityComponent: NSObject, DCFComponent, ComponentMethodHandler {
    // Keep singleton instance to prevent deallocation when touch targets are registered
    private static let sharedInstance = DCFTouchableOpacityComponent()
    
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        // Create view to handle touches
        let touchableView = TouchableView()
        touchableView.component = self
        
        // Apply props
        updateView(touchableView, withProps: props)
        
        return touchableView
    }
    
    func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool {
        guard let touchableView = view as? TouchableView else { return false }
        
        // Set active opacity
        if let activeOpacity = props["activeOpacity"] as? CGFloat {
            touchableView.activeOpacity = activeOpacity
        } else {
            touchableView.activeOpacity = 0.2 // Default
        }
        
        // Set disabled state
        if let disabled = props["disabled"] as? Bool {
            touchableView.isUserInteractionEnabled = !disabled
            // Apply disabled visual state if needed
            touchableView.alpha = disabled ? 0.5 : 1.0
        }
        
        // Set long press delay
        if let longPressDelay = props["longPressDelay"] as? Int {
            touchableView.longPressDelay = TimeInterval(longPressDelay) / 1000.0
        }
        
        return true
    }
    
    // MARK: - Event Handling
    
    func handleTouchDown(_ view: TouchableView) {
        // Animate to pressed state
        UIView.animate(withDuration: 0.1) {
            view.alpha = view.activeOpacity
        }
        
        // Trigger onPressIn event
        triggerEvent(on: view, eventType: "onPressIn", eventData: [:])
        
        // Set up long press timer
        view.startLongPressTimer()
    }
    
    func handleTouchUp(_ view: TouchableView, inside: Bool) {
        // Cancel long press timer
        view.cancelLongPressTimer()
        
        // Animate back to normal state
        UIView.animate(withDuration: 0.1) {
            view.alpha = 1.0
        }
        
        // Trigger events
        triggerEvent(on: view, eventType: "onPressOut", eventData: [:])
        
        if inside {
            triggerEvent(on: view, eventType: "onPress", eventData: [:])
        }
    }
    
    func handleLongPress(_ view: TouchableView) {
        // Trigger long press event
        triggerEvent(on: view, eventType: "onLongPress", eventData: [:])
    }
    
    // MARK: - Method Handling
    
    func handleMethod(methodName: String, args: [String: Any], view: UIView) -> Bool {
        switch methodName {
        case "setOpacity":
            if let opacity = args["opacity"] as? CGFloat {
                view.alpha = opacity
                return true
            }
        default:
            break
        }
        
        return false
    }
}

/// Custom view class for touchable opacity
class TouchableView: UIView {
    // Reference to component
    weak var component: DCFTouchableOpacityComponent?
    
    // Active opacity when pressed
    var activeOpacity: CGFloat = 0.2
    
    // Long press properties
    var longPressDelay: TimeInterval = 0.5
    var longPressTimer: Timer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        isUserInteractionEnabled = true
    }
    
    // Start long press timer
    func startLongPressTimer() {
        cancelLongPressTimer()
        
        longPressTimer = Timer.scheduledTimer(withTimeInterval: longPressDelay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.component?.handleLongPress(self)
        }
    }
    
    // Cancel long press timer
    func cancelLongPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = nil
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        component?.handleTouchDown(self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        // Check if touch is inside view
        if let touch = touches.first {
            let point = touch.location(in: self)
            let inside = bounds.contains(point)
            component?.handleTouchUp(self, inside: inside)
        } else {
            component?.handleTouchUp(self, inside: false)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        component?.handleTouchUp(self, inside: false)
    }
}
