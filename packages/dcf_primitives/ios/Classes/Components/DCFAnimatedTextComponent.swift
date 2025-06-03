import UIKit
import dcflight

/// Component that implements animated text
class DCFAnimatedTextComponent: NSObject, DCFComponent, ComponentMethodHandler {
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        // Create animated label
        let animatedLabel = AnimatedLabel()
        
        // Apply props
        updateView(animatedLabel, withProps: props)
        
        return animatedLabel
    }
    
    func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool {
        guard let animatedLabel = view as? AnimatedLabel else { return false }
        
        // Apply text properties
        if let content = props["content"] as? String {
            animatedLabel.text = content
        }
        
        // Get font size (default to system font size if not specified)
        let fontSize = props["fontSize"] as? CGFloat ?? UIFont.systemFontSize
        
        // Determine font weight using centralized utility
        var fontWeight = UIFont.Weight.regular
        if let fontWeightString = props["fontWeight"] as? String {
            fontWeight = fontWeightFromString(fontWeightString)
        }
        
        // Check if font is from an asset (with isFontAsset flag)
        let isFontAsset = props["isFontAsset"] as? Bool ?? false
        
        // Set font family if specified
        if let fontFamily = props["fontFamily"] as? String {
            if isFontAsset {
                // Use font from asset
                if let fontCached = DCFTextComponent.fontCache[fontFamily] {
                    animatedLabel.font = fontCached
                } else if let customFont = UIFont(name: fontFamily, size: fontSize) {
                    DCFTextComponent.fontCache[fontFamily] = customFont
                    animatedLabel.font = customFont
                } else {
                    animatedLabel.font = UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
                }
            } else {
                // Use system font with family
                animatedLabel.font = UIFont(name: fontFamily, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
            }
        } else {
            // Use system font
            animatedLabel.font = UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
        }
        
        // Set text color if specified
        if let color = props["color"] as? String {
            animatedLabel.textColor = ColorUtilities.color(fromHexString: color)
        }
        
        // Set text alignment if specified
        if let textAlign = props["textAlign"] as? String {
            switch textAlign.lowercased() {
            case "center":
                animatedLabel.textAlignment = .center
            case "right":
                animatedLabel.textAlignment = .right
            case "justify":
                animatedLabel.textAlignment = .justified
            default:
                animatedLabel.textAlignment = .left
            }
        }
        
        // Set number of lines if specified
        if let numberOfLines = props["numberOfLines"] as? Int {
            animatedLabel.numberOfLines = numberOfLines
        }
        
        // Apply animation properties
        if let duration = props["animationDuration"] as? Int {
            animatedLabel.animationDuration = TimeInterval(duration) / 1000.0
        }
        
        if let curve = props["animationCurve"] as? String {
            animatedLabel.animationCurve = getCurve(from: curve)
        }
        
        if let delay = props["animationDelay"] as? Int {
            animatedLabel.animationDelay = TimeInterval(delay) / 1000.0
        }
        
        if let animRepeat = props["animationRepeat"] as? Bool {
            animatedLabel.animationRepeat = animRepeat
        }
        
        // Store target values for animation
        if let toScale = props["toScale"] as? CGFloat {
            animatedLabel.targetScale = toScale
        }
        
        if let toOpacity = props["toOpacity"] as? CGFloat {
            animatedLabel.targetOpacity = toOpacity
        }
        
        if let toTranslateX = props["toTranslateX"] as? CGFloat {
            animatedLabel.targetTranslationX = toTranslateX
        }
        
        if let toTranslateY = props["toTranslateY"] as? CGFloat {
            animatedLabel.targetTranslationY = toTranslateY
        }
        
        // Automatically start animation after layout
        animatedLabel.needsAnimation = true
        
        return true
    }
    
    // MARK: - Animation Helpers
    
    private func getCurve(from name: String) -> UIView.AnimationOptions {
        switch name.lowercased() {
        case "linear":
            return .curveLinear
        case "easein":
            return .curveEaseIn
        case "easeout":
            return .curveEaseOut
        case "easeinout":
            return .curveEaseInOut
        default:
            return .curveEaseInOut
        }
    }
    
    // MARK: - Method Handling
    
    func handleMethod(methodName: String, args: [String: Any], view: UIView) -> Bool {
        guard let animatedLabel = view as? AnimatedLabel else { return false }
        
        switch methodName {
        case "setText":
            if let text = args["text"] as? String {
                let duration = args["duration"] as? TimeInterval ?? animatedLabel.animationDuration
                let curve = args["curve"] as? String
                
                // Animate text change
                animatedLabel.setText(text, duration: duration, curve: curve.map { getCurve(from: $0) })
                return true
            }
            
        case "animate":
            // Set animation properties from method args
            if let duration = args["duration"] as? Int {
                animatedLabel.animationDuration = TimeInterval(duration) / 1000.0
            }
            
            if let curve = args["curve"] as? String {
                animatedLabel.animationCurve = getCurve(from: curve)
            }
            
            if let toScale = args["toScale"] as? CGFloat {
                animatedLabel.targetScale = toScale
            }
            
            if let toOpacity = args["toOpacity"] as? CGFloat {
                animatedLabel.targetOpacity = toOpacity
            }
            
            if let toTranslateX = args["toTranslateX"] as? CGFloat {
                animatedLabel.targetTranslationX = toTranslateX
            }
            
            if let toTranslateY = args["toTranslateY"] as? CGFloat {
                animatedLabel.targetTranslationY = toTranslateY
            }
            
            // Start animation
            animatedLabel.animate()
            return true
            
        default:
            return false
        }
        
        return false
    }
    
    // MARK: - View Registration
    
    func viewRegisteredWithShadowTree(_ view: UIView, nodeId: String) {
        if let animatedLabel = view as? AnimatedLabel {
            // Trigger onViewId event
            triggerEvent(on: animatedLabel, eventType: "onViewId", eventData: ["id": nodeId])
        }
    }
    
    // MARK: - Event Handling
    
    func addEventListeners(to view: UIView, viewId: String, eventTypes: [String], 
                          eventCallback: @escaping (String, String, [String: Any]) -> Void) {
        guard let animatedLabel = view as? AnimatedLabel else { return }
        
        print("🎭 Adding event listeners to animated text \(viewId): \(eventTypes)")
        
        // Store the event callback and view ID using associated objects
        objc_setAssociatedObject(view, 
                               UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!, 
                               eventCallback, 
                               .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        objc_setAssociatedObject(view, 
                               UnsafeRawPointer(bitPattern: "viewId".hashValue)!, 
                               viewId, 
                               .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Store the registered event types
        objc_setAssociatedObject(view, 
                               UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!,
                               eventTypes,
                               .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func removeEventListeners(from view: UIView, viewId: String, eventTypes: [String]) {
        guard let animatedLabel = view as? AnimatedLabel else { return }
        
        print("🚫 Removing event listeners from animated text: \(viewId)")
        
        // Clear associated objects if all event types are removed
        if let existingTypes = objc_getAssociatedObject(view, UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!) as? [String],
           Set(existingTypes).isSubset(of: Set(eventTypes)) {
            
            objc_setAssociatedObject(view, 
                                   UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!, 
                                   nil, 
                                   .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            objc_setAssociatedObject(view, 
                                   UnsafeRawPointer(bitPattern: "viewId".hashValue)!, 
                                   nil, 
                                   .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            objc_setAssociatedObject(view, 
                                   UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!,
                                   nil,
                                   .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

/// Custom animated label class
class AnimatedLabel: UILabel {
    // Animation properties
    var animationDuration: TimeInterval = 0.3
    var animationDelay: TimeInterval = 0.0
    var animationCurve: UIView.AnimationOptions = .curveEaseInOut
    var animationRepeat: Bool = false
    
    // Target values
    var targetScale: CGFloat?
    var targetOpacity: CGFloat?
    var targetTranslationX: CGFloat?
    var targetTranslationY: CGFloat?
    
    // Initial values
    private var initialTransform = CGAffineTransform.identity
    private var initialAlpha: CGFloat = 1.0
    
    // Flag for animation on layout
    var needsAnimation = false
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLabel()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLabel()
    }
    
    private func setupLabel() {
        // Ensure proper text wrapping
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Trigger animation after layout if needed
        if needsAnimation {
            needsAnimation = false
            // Small delay to ensure layout is complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.animate()
            }
        }
    }
    
    // Animate text change
    func setText(_ newText: String, duration: TimeInterval, curve: UIView.AnimationOptions? = nil) {
        // Store initial state
        let currentText = text
        
        // Trigger animation start event through associated object
        if let viewId = objc_getAssociatedObject(self, UnsafeRawPointer(bitPattern: "viewId".hashValue)!) as? String,
           let callback = objc_getAssociatedObject(self, UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!) as? (String, String, [String: Any]) -> Void {
            callback(viewId, "onAnimationStart", [:])
        }
        
        // Fade out with current text
        UIView.animate(withDuration: duration / 2, delay: 0, options: curve ?? animationCurve, animations: { [weak self] in
            self?.alpha = 0
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            
            // Update text while invisible
            self.text = newText
            
            // Fade back in with new text
            UIView.animate(withDuration: duration / 2, delay: 0, options: curve ?? self.animationCurve, animations: {
                self.alpha = 1
            }, completion: { [weak self] finished in
                guard let self = self, finished else { return }
                
                // Trigger animation end event through associated object
                if let viewId = objc_getAssociatedObject(self, UnsafeRawPointer(bitPattern: "viewId".hashValue)!) as? String,
                   let callback = objc_getAssociatedObject(self, UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!) as? (String, String, [String: Any]) -> Void {
                    callback(viewId, "onAnimationEnd", [:])
                }
            })
        })
    }
    
    // Animate the label with current properties
    func animate() {
        // Store initial state
        initialTransform = transform
        initialAlpha = alpha
        
        // Trigger animation start event through associated object
        if let viewId = objc_getAssociatedObject(self, UnsafeRawPointer(bitPattern: "viewId".hashValue)!) as? String,
           let callback = objc_getAssociatedObject(self, UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!) as? (String, String, [String: Any]) -> Void {
            callback(viewId, "onAnimationStart", [:])
        }
        
        // Start animation
        UIView.animate(withDuration: animationDuration, delay: animationDelay, options: animationCurve, animations: { [weak self] in
            guard let self = self else { return }
            
            // Apply scale transform
            if let scale = self.targetScale {
                let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
                self.transform = self.transform.concatenating(scaleTransform)
            }
            
            // Apply translation transform
            if let translateX = self.targetTranslationX, let translateY = self.targetTranslationY {
                let translationTransform = CGAffineTransform(translationX: translateX, y: translateY)
                self.transform = self.transform.concatenating(translationTransform)
            } else if let translateX = self.targetTranslationX {
                let translationTransform = CGAffineTransform(translationX: translateX, y: 0)
                self.transform = self.transform.concatenating(translationTransform)
            } else if let translateY = self.targetTranslationY {
                let translationTransform = CGAffineTransform(translationX: 0, y: translateY)
                self.transform = self.transform.concatenating(translationTransform)
            }
            
            // Apply opacity
            if let opacity = self.targetOpacity {
                self.alpha = opacity
            }
            
        }, completion: { [weak self] finished in
            guard let self = self, finished else { return }
            
            // Trigger animation end event through associated object
            if let viewId = objc_getAssociatedObject(self, UnsafeRawPointer(bitPattern: "viewId".hashValue)!) as? String,
               let callback = objc_getAssociatedObject(self, UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!) as? (String, String, [String: Any]) -> Void {
                callback(viewId, "onAnimationEnd", [:])
            }
            
            // Handle repeat if needed
            if self.animationRepeat {
                self.reset()
                self.animate()
            }
        })
    }
    
    // Reset the label to its initial state
    func reset() {
        layer.removeAllAnimations()
        transform = initialTransform
        alpha = initialAlpha
    }
}
