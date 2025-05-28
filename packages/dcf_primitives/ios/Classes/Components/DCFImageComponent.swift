import UIKit
import dcflight

class DCFImageComponent: NSObject, DCFComponent, ComponentMethodHandler {
    // Dictionary to cache loaded images
    private static var imageCache = [String: UIImage]()
    
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        // Create an image view
        let imageView = UIImageView()
        
        // Apply initial styling
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        // Apply props
        updateView(imageView, withProps: props)
        
        return imageView
    }
    
    func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool {
        guard let imageView = view as? UIImageView else { return false }
        
        // Set image source if specified
        if let source = props["source"] as? String {
            let key = sharedFlutterViewController?.lookupKey(forAsset: source)
            let mainBundle = Bundle.main
            let path = mainBundle.path(forResource: key, ofType: nil)
            

            if (source.hasPrefix("https://")==false){
                print("this image path is local")
                loadImage(from: path!, into: imageView)
            }else{
                loadImage(from: source, into: imageView)
            }
            
        }
        
        // Set resize mode if specified
        if let resizeMode = props["resizeMode"] as? String {
            switch resizeMode {
            case "cover":
                imageView.contentMode = .scaleAspectFill
            case "contain":
                imageView.contentMode = .scaleAspectFit
            case "stretch":
                imageView.contentMode = .scaleToFill
            case "center":
                imageView.contentMode = .center
            default:
                imageView.contentMode = .scaleAspectFill
            }
        }
        
        return true
    }
    
    // Load image from URL or resource
    private func loadImage(from source: String, into imageView: UIImageView) {
        // Check cache first
        if let cachedImage = DCFImageComponent.imageCache[source] {
            imageView.image = cachedImage
            triggerEvent(on: imageView, eventType: "onLoad", eventData: [:])
            return
        }
        
        
        
        // Check if it's a URL
        if source.hasPrefix("http://") || source.hasPrefix("https://") {
            // Load from URL
            if let url = URL(string: source) {
                // Load image asynchronously
              
                    if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        // Cache the image
                        DCFImageComponent.imageCache[source] = image
                        
                        DispatchQueue.main.async {
                            UIView.transition(with: imageView, duration: 0.3, options: .transitionCrossDissolve, animations: {
                                imageView.image = image
                            }, completion: { _ in
                                // Trigger onLoad event
                                self.triggerEvent(on: imageView, eventType: "onLoad", eventData: [:])
                            })
                        }
                    } else if(source.hasPrefix("https://")==false){
                 
                        if let image = UIImage(contentsOfFile: source) {
                                // Cache the image
                                DCFImageComponent.imageCache[source] = image
                                
                                // Set the image
                                imageView.image = image
                                
                                // Trigger onLoad event
                            self.triggerEvent(on: imageView, eventType: "onLoad", eventData: [:])
                           
                            } else {
                                print("❌ Failed to load image from resolved path: \(source)")
                                self.triggerEvent(on: imageView, eventType: "onError", eventData: ["error": "Image not found at resolved path"])
                                return
                            }
                    }else {
                        // Trigger onError event
                        DispatchQueue.main.async {
                            self.triggerEvent(on: imageView, eventType: "onError", eventData: ["error": "Failed to load image from URL"])
                        }
                    }
                }
                return
            
        } else {
            // Try to load from bundle directly
            if let image = UIImage(named: source) {
                // Cache the image
                DCFImageComponent.imageCache[source] = image
                
                // Set the image
                imageView.image = image
                
                // Trigger onLoad event
                triggerEvent(on: imageView, eventType: "onLoad", eventData: [:])
                return
            }
        }
        
        // If we reach here, the image couldn't be loaded
        print("❌ Failed to load image: \(source)")
        triggerEvent(on: imageView, eventType: "onError", eventData: ["error": "Image not found"])
    }
    
    // Handle component methods
    func handleMethod(methodName: String, args: [String: Any], view: UIView) -> Bool {
        guard let imageView = view as? UIImageView else { return false }
        
        switch methodName {
        case "setImage":
            if let uri = args["uri"] as? String {
                // Use the same loading logic
                loadImage(from: uri, into: imageView)
                return true
            }
        case "reload":
            // Force reload the current image
            if let image = imageView.image {
                // Just trigger the onLoad event again
                self.triggerEvent(on: imageView, eventType: "onLoad", eventData: [:])
                return true
            }
        default:
            return false
        }
        
        return false
    }
}
