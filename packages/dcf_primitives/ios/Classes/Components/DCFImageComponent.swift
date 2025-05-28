import UIKit
import dcflight

class DCFImageComponent: NSObject, DCFComponent, ComponentMethodHandler {
    // Thread-safe image cache using concurrent queue with barrier writes
    private static let cacheQueue = DispatchQueue(label: "com.dcf.imageCache", attributes: .concurrent)
    private static var _imageCache = [String: UIImage]()
    
    // Thread-safe cache accessors
    private static func getCachedImage(for key: String) -> UIImage? {
        return cacheQueue.sync {
            return _imageCache[key]
        }
    }
    
    private static func setCachedImage(_ image: UIImage, for key: String) {
        cacheQueue.async(flags: .barrier) {
            _imageCache[key] = image
        }
    }
    
    private static func removeCachedImage(for key: String) {
        cacheQueue.async(flags: .barrier) {
            _imageCache.removeValue(forKey: key)
        }
    }
    
    private static func clearAllCache() {
        cacheQueue.async(flags: .barrier) {
            _imageCache.removeAll()
        }
    }
    
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
        
        // Set image source if specified - with proper type checking
        if let sourceAny = props["source"] {
            let source: String
            
            // Handle different source types safely
            if let sourceString = sourceAny as? String {
                source = sourceString
            } else if let sourceNumber = sourceAny as? NSNumber {
                source = sourceNumber.stringValue
            } else {
                print("❌ Invalid source type: \(type(of: sourceAny))")
                triggerEvent(on: imageView, eventType: "onError", eventData: ["error": "Invalid source type"])
                return false
            }
            
            // Validate source is not empty
            guard !source.isEmpty else {
                print("❌ Empty source provided")
                triggerEvent(on: imageView, eventType: "onError", eventData: ["error": "Empty source"])
                return false
            }
            
            let key = sharedFlutterViewController?.lookupKey(forAsset: source)
            let mainBundle = Bundle.main
            let path = mainBundle.path(forResource: key, ofType: nil)
            
            if !source.hasPrefix("https://") && !source.hasPrefix("http://") {
                print("this image path is local")
                if let validPath = path {
                    loadImage(from: validPath, into: imageView, isLocal: true)
                } else {
                    loadImage(from: source, into: imageView, isLocal: true)
                }
            } else {
                loadImage(from: source, into: imageView, isLocal: false)
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
    
    // Load image from URL or resource with improved error handling and thread safety
    private func loadImage(from source: String, into imageView: UIImageView, isLocal: Bool = false) {
        // Validate source
        guard !source.isEmpty else {
            print("❌ Empty source provided to loadImage")
            triggerEvent(on: imageView, eventType: "onError", eventData: ["error": "Empty source"])
            return
        }
        
        // Create a safe cache key - ensure it's always a string
        let cacheKey = String(describing: source)
        
        // Check cache first - thread-safe
        if let cachedImage = DCFImageComponent.getCachedImage(for: cacheKey) {
            DispatchQueue.main.async {
                imageView.image = cachedImage
                self.triggerEvent(on: imageView, eventType: "onLoad", eventData: [:])
            }
            return
        }
        
        if !isLocal && (source.hasPrefix("http://") || source.hasPrefix("https://")) {
            // Load from URL
            guard let url = URL(string: source) else {
                print("❌ Invalid URL: \(source)")
                triggerEvent(on: imageView, eventType: "onError", eventData: ["error": "Invalid URL"])
                return
            }
            
            // Load image asynchronously
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                do {
                    let data = try Data(contentsOf: url)
                    guard let image = UIImage(data: data) else {
                        DispatchQueue.main.async {
                            print("❌ Failed to create image from data for URL: \(source)")
                            self.triggerEvent(on: imageView, eventType: "onError", eventData: ["error": "Failed to create image from data"])
                        }
                        return
                    }
                    
                    // Cache the image safely - thread-safe
                    DCFImageComponent.setCachedImage(image, for: cacheKey)
                    
                    DispatchQueue.main.async {
                        // Double-check that imageView still exists and hasn't been deallocated
                        guard imageView.superview != nil else { return }
                        
                        UIView.transition(with: imageView, duration: 0.3, options: .transitionCrossDissolve, animations: {
                            imageView.image = image
                        }, completion: { _ in
                            self.triggerEvent(on: imageView, eventType: "onLoad", eventData: [:])
                        })
                    }
                } catch {
                    DispatchQueue.main.async {
                        print("❌ Failed to load image from URL: \(source), error: \(error)")
                        self.triggerEvent(on: imageView, eventType: "onError", eventData: ["error": "Failed to load image from URL: \(error.localizedDescription)"])
                    }
                }
            }
        } else {
            // Handle local images
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                var image: UIImage?
                
                // Try different methods to load local image
                if FileManager.default.fileExists(atPath: source) {
                    image = UIImage(contentsOfFile: source)
                } else {
                    image = UIImage(named: source)
                }
                
                if let validImage = image {
                    // Cache the image safely - thread-safe
                    DCFImageComponent.setCachedImage(validImage, for: cacheKey)
                    
                    DispatchQueue.main.async {
                        // Double-check that imageView still exists
                        guard imageView.superview != nil else { return }
                        
                        imageView.image = validImage
                        self.triggerEvent(on: imageView, eventType: "onLoad", eventData: [:])
                    }
                } else {
                    print("❌ Failed to load local image: \(source)")
                    DispatchQueue.main.async {
                        self.triggerEvent(on: imageView, eventType: "onError", eventData: ["error": "Local image not found"])
                    }
                }
            }
        }
    }
    
    // Handle component methods
    func handleMethod(methodName: String, args: [String: Any], view: UIView) -> Bool {
        guard let imageView = view as? UIImageView else { return false }
        
        switch methodName {
        case "setImage":
            if let uriAny = args["uri"] {
                let uri: String
                
                // Handle different URI types safely
                if let uriString = uriAny as? String {
                    uri = uriString
                } else if let uriNumber = uriAny as? NSNumber {
                    uri = uriNumber.stringValue
                } else {
                    print("❌ Invalid URI type in setImage: \(type(of: uriAny))")
                    return false
                }
                
                guard !uri.isEmpty else {
                    print("❌ Empty URI provided to setImage")
                    return false
                }
                
                loadImage(from: uri, into: imageView)
                return true
            }
        case "reload":
            // Force reload the current image
            if imageView.image != nil {
                self.triggerEvent(on: imageView, eventType: "onLoad", eventData: [:])
                return true
            }
        case "clearCache":
            // Clear the entire image cache - thread-safe
            DCFImageComponent.clearAllCache()
            return true
        case "clearImageCache":
            // Clear cache for specific image - thread-safe
            if let sourceAny = args["source"] {
                let source = String(describing: sourceAny)
                DCFImageComponent.removeCachedImage(for: source)
                return true
            }
        default:
            return false
        }
        
        return false
    }
    
    // Safe event triggering
    internal func triggerEvent(on view: UIView, eventType: String, eventData: [String: Any]) {
        DispatchQueue.main.async {
            // Ensure we're on main thread for UI updates
            if let component = view.superview as? DCFComponent {
                self.triggerEvent(on: view, eventType: eventType, eventData: eventData)
                print("🔔 Triggering event: \(eventType) with data: \(eventData)")
            }
        }
    }
}
