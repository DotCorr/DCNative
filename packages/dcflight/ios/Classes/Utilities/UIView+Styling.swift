import UIKit

// UIView extension for generic style application
extension UIView {
    /// Apply common style properties to this view, driven only by explicit props.
    public func applyStyles(props: [String: Any]) {
        // Debug log for applied props
        // print("🎨 Applying generic styles to \(type(of: self)) [ID: \(self.accessibilityIdentifier ?? "nil")] : \(props.keys.joined(separator: ", "))")

        // Border Radius (Global)
        if let borderRadius = props["borderRadius"] as? CGFloat {
            layer.cornerRadius = borderRadius
            // Let the component decide if clipsToBounds/masksToBounds should be true.
        }

        // Per-corner Radius (Overrides global borderRadius if specific corners are set)
        var cornerMask: CACornerMask = []
        var customRadius: CGFloat? = nil // Use the first specified radius

        if let radius = props["borderTopLeftRadius"] as? CGFloat, radius >= 0 {
            cornerMask.insert(.layerMinXMinYCorner)
            customRadius = customRadius ?? radius
        }
        if let radius = props["borderTopRightRadius"] as? CGFloat, radius >= 0 {
            cornerMask.insert(.layerMaxXMinYCorner)
            customRadius = customRadius ?? radius
        }
        if let radius = props["borderBottomLeftRadius"] as? CGFloat, radius >= 0 {
            cornerMask.insert(.layerMinXMaxYCorner)
            customRadius = customRadius ?? radius
        }
        if let radius = props["borderBottomRightRadius"] as? CGFloat, radius >= 0 {
            cornerMask.insert(.layerMaxXMaxYCorner)
            customRadius = customRadius ?? radius
        }

        if !cornerMask.isEmpty {
            layer.maskedCorners = cornerMask
            if let radius = customRadius {
                layer.cornerRadius = radius // Apply the radius if specific corners are masked
                // Let the component decide if clipsToBounds/masksToBounds should be true.
            }
        } else if props["borderRadius"] == nil {
             // If no specific corners and no global radius, ensure mask is default (all corners)
             // Only reset if *none* of the radius props were set.
             if props["borderTopLeftRadius"] == nil && props["borderTopRightRadius"] == nil &&
                props["borderBottomLeftRadius"] == nil && props["borderBottomRightRadius"] == nil {
                 layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                 // Also reset cornerRadius if it wasn't explicitly set by borderRadius
                 if props["borderRadius"] == nil {
                     layer.cornerRadius = 0
                 }
             }
        }


        // Border color and width - Apply only if specified
        if let borderColorStr = props["borderColor"] as? String {
            layer.borderColor = ColorUtilities.color(fromHexString: borderColorStr)?.cgColor
        }
        // No default reset for borderColor

        if let borderWidth = props["borderWidth"] as? CGFloat {
            layer.borderWidth = borderWidth
        }
        // No default reset for borderWidth


        // Background color - Apply only if specified
        if let backgroundColorStr = props["backgroundColor"] as? String {
            self.backgroundColor = ColorUtilities.color(fromHexString: backgroundColorStr)
            // print("   - Applied backgroundColor: \(backgroundColorStr)")
        }
        // No default reset for backgroundColor


        // Opacity (Alpha) - Apply only if specified
        if let opacity = props["opacity"] as? CGFloat {
            self.alpha = opacity
            // print("   - Applied opacity: \(opacity)")
        }
        // No default reset for alpha


        // Shadow properties - Apply only if specified
        var needsMasksToBoundsFalse = false // Track if shadow requires masksToBounds = false
        if let shadowColorStr = props["shadowColor"] as? String {
            layer.shadowColor = ColorUtilities.color(fromHexString: shadowColorStr)?.cgColor
            needsMasksToBoundsFalse = true
        }
        // No default reset

        if let shadowOpacity = props["shadowOpacity"] as? Float {
            layer.shadowOpacity = shadowOpacity
            needsMasksToBoundsFalse = true
        }
        // No default reset

        if let shadowRadius = props["shadowRadius"] as? CGFloat {
            layer.shadowRadius = shadowRadius
            needsMasksToBoundsFalse = true
        }
        // No default reset

        if let shadowOffsetX = props["shadowOffsetX"] as? CGFloat,
           let shadowOffsetY = props["shadowOffsetY"] as? CGFloat {
            layer.shadowOffset = CGSize(width: shadowOffsetX, height: shadowOffsetY)
            needsMasksToBoundsFalse = true
        }
        // No default reset

        // Set masksToBounds based *only* on whether shadow properties were applied
        if needsMasksToBoundsFalse {
            layer.masksToBounds = false
        }
        // IMPORTANT: Do NOT set masksToBounds = true here. Components (like those with cornerRadius)
        // might need it to be false even without shadows, or true even with shadows (if clipping content).
        // The component's updateView should manage masksToBounds/clipsToBounds.


        // Transform - Apply only if specified
        if let transformProps = props["transform"] as? [[String: Any]] {
             var transformMatrix = CGAffineTransform.identity
             for transform in transformProps {
                 if let type = transform.keys.first, let value = transform[type] {
                     switch type {
                     case "translateX":
                         if let val = value as? CGFloat { transformMatrix = transformMatrix.translatedBy(x: val, y: 0) }
                     case "translateY":
                         if let val = value as? CGFloat { transformMatrix = transformMatrix.translatedBy(x: 0, y: val) }
                     case "scale":
                         if let val = value as? CGFloat { transformMatrix = transformMatrix.scaledBy(x: val, y: val) }
                     case "scaleX":
                         if let val = value as? CGFloat { transformMatrix = transformMatrix.scaledBy(x: val, y: 1) }
                     case "scaleY":
                         if let val = value as? CGFloat { transformMatrix = transformMatrix.scaledBy(x: 1, y: val) }
                     case "rotate", "rotateZ": // Treat rotate and rotateZ the same for 2D
                         if let val = value as? String {
                             // Handle degree values like "30deg"
                             if val.hasSuffix("deg"), let degrees = Double(val.dropLast(3)) {
                                 transformMatrix = transformMatrix.rotated(by: CGFloat(degrees * .pi / 180.0))
                             }
                         } else if let val = value as? CGFloat { // Handle raw radian values
                              transformMatrix = transformMatrix.rotated(by: val)
                         }
                     // Add cases for rotateX, rotateY if needed for 3D, requires CATransform3D
                     default:
                         print("   - Unsupported transform type: \(type)")
                     }
                 }
             }
             self.transform = transformMatrix
             // print("   - Applied transform")
        } else {
             // Reset transform only if the 'transform' key exists but is null/empty,
             // or if explicitly requested by another mechanism (not handled here).
             // Generally, avoid resetting unless explicitly told to.
             // self.transform = .identity // Avoid automatic reset
        }


        // Accessibility properties - Apply only if specified
        if let accessible = props["accessible"] as? Bool {
            self.isAccessibilityElement = accessible
        }
        // No default setting

        if let label = props["accessibilityLabel"] as? String {
            self.accessibilityLabel = label
        }

        if let testID = props["testID"] as? String {
            self.accessibilityIdentifier = testID // Used for view lookup and testing
        }

        // Pointer Events - Apply only if specified
        if let pointerEvents = props["pointerEvents"] as? String {
            switch pointerEvents {
            case "none":
                self.isUserInteractionEnabled = false
                // print("   - Applied pointerEvents: none")
            case "box-none":
                // View itself doesn't receive events, but children can.
                self.isUserInteractionEnabled = false // Correct for the view itself
                // print("   - Applied pointerEvents: box-none (view interaction disabled)")
            case "box-only":
                // View receives events, children do not (UIKit default handles this if children are disabled).
                self.isUserInteractionEnabled = true
                // print("   - Applied pointerEvents: box-only (view interaction enabled)")
            case "auto", "all":
                fallthrough
            default:
                self.isUserInteractionEnabled = true
                // print("   - Applied pointerEvents: auto/all (view interaction enabled)")
            }
        }
        // No default setting for isUserInteractionEnabled - rely on UIKit defaults.
    }
}
