import UIKit
import dcflight
import CoreText

class DCFTextComponent: NSObject, DCFComponent, ComponentMethodHandler {
    // Dictionary to cache loaded fonts
    internal static var fontCache = [String: UIFont]()
    
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        // Create a label
        let label = UILabel()
        
        // Apply initial styling
        label.numberOfLines = 0
        label.textColor = UIColor.black
        
        // Apply props
        updateView(label, withProps: props)
        
        return label
    }
    
    func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool {
        guard let label = view as? UILabel else { return false }
        
        print("🔍 DCFTextComponent.updateView called with props: \(props.keys.sorted())")
        print("🔍 Current label font: \(label.font?.fontName ?? "nil") - \(label.font?.pointSize ?? 0)")
        print("🔍 Current label color: \(label.textColor?.description ?? "nil")")
        
        // Set content if specified
        if let content = props["content"] as? String {
            label.text = content
        }
        
        // CRITICAL: Get current font properties to preserve them
//        let currentFont = label.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
//        let currentFontSize = props["fontSize"] as? CGFloat ?? currentFont.pointSize
        
        // CRITICAL: Get current font properties to preserve them
        let currentFont = label.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
        let currentFontSize = props["fontSize"] as? CGFloat ?? currentFont.pointSize
        
        // Get font size (preserve current if not specified in props)
        let fontSize = props["fontSize"] as? CGFloat ?? currentFontSize
        
        // CRITICAL: Preserve current font weight if not specified in props
        var fontWeight = UIFont.Weight.regular
        if let fontWeightString = props["fontWeight"] as? String {
            fontWeight = fontWeightFromString(fontWeightString)
        } else {
            // Try to extract current font weight to preserve it
            if let currentDescriptor = currentFont.fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any],
               let currentWeight = currentDescriptor[.weight] as? UIFont.Weight {
                fontWeight = currentWeight
                print("🔍 Preserving current font weight: \(fontWeight)")
            }
        }
        
        // Check if font is from an asset (with isFontAsset flag)
        let isFontAsset = props["isFontAsset"] as? Bool ?? false
        
        // CRITICAL: Preserve current font family if not specified in props
        var fontFamilyToUse: String? = nil
        var shouldUpdateFont = false
        
        // Set font family if specified in props
        if let fontFamily = props["fontFamily"] as? String {
            fontFamilyToUse = fontFamily
            shouldUpdateFont = true
        } else if props.keys.contains("fontSize") || props.keys.contains("fontWeight") {
            // If fontSize or fontWeight changed, we need to rebuild font but preserve family
            fontFamilyToUse = currentFont.fontName
            shouldUpdateFont = true
        }
        
        // Only update font if necessary
        if shouldUpdateFont, let fontFamily = fontFamilyToUse {
            if isFontAsset {
                // Use the same asset resolution approach as SVG
                let key = sharedFlutterViewController?.lookupKey(forAsset: fontFamily)
                let mainBundle = Bundle.main
                let path = mainBundle.path(forResource: key, ofType: nil)
                
                print("🔤 Font asset lookup - key: \(String(describing: key)), path: \(String(describing: path))")
                
                loadFontFromAsset(fontFamily, path: path, fontSize: fontSize, weight: fontWeight) { font in
                    if let font = font {
                        label.font = font
                    } else {
                        // Fallback to system font if custom font loading fails
                        label.font = UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
                    }
                }
            } else {
                // Try to use a pre-installed font by name
                if let font = UIFont(name: fontFamily, size: fontSize) {
                    // Apply weight if needed
                    if fontWeight != .regular {
                        let descriptor = font.fontDescriptor.addingAttributes([
                            .traits: [UIFontDescriptor.TraitKey.weight: fontWeight]
                        ])
                        label.font = UIFont(descriptor: descriptor, size: fontSize)
                    } else {
                        label.font = font
                    }
                } else {
                    // Fallback to system font if font not found
                    label.font = UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
                }
            }
        } else {
            // Use system font with the specified size and weight
            label.font = UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
        }
        
        // Set text color if specified (preserve current color if not in props)
        if let color = props["color"] as? String {
            // Safely parse the color string - will use a default color if the string is invalid
            label.textColor = ColorUtilities.color(fromHexString:color)
        }
        // Note: Don't reset color if not specified in props - preserve current color
        
        // Set text alignment if specified (preserve current alignment if not in props)
        if let textAlign = props["textAlign"] as? String {
            switch textAlign {
            case "center":
                label.textAlignment = .center
            case "right":
                label.textAlignment = .right
            case "justify":
                label.textAlignment = .justified
            default:
                label.textAlignment = .left
            }
        }
        // Note: Don't reset alignment if not specified in props - preserve current alignment
        
        // Set number of lines if specified (preserve current numberOfLines if not in props)
        if let numberOfLines = props["numberOfLines"] as? Int {
            label.numberOfLines = numberOfLines
        }
        // Note: Don't reset numberOfLines if not specified in props - preserve current value
        
        print("🔍 After update - font: \(label.font?.fontName ?? "nil") - \(label.font?.pointSize ?? 0)")
        print("🔍 After update - color: \(label.textColor?.description ?? "nil")")
        
        return true
    }
    
    // Handle component methods
        func handleMethod(methodName: String, args: [String: Any], view: UIView) -> Bool {
            guard let label = view as? UILabel else { return false }
            
            switch methodName {
            case "setText":
                if let text = args["text"] as? String {
                    label.text = text
                    return true
                }
            default:
                return false
            }
            
            return false
        }

}



