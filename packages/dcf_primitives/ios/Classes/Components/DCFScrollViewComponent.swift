import UIKit
import dcflight

class DCFScrollViewComponent: NSObject, DCFComponent, ComponentMethodHandler, UIScrollViewDelegate {
    // Keep singleton instance to prevent deallocation when scroll events are registered
    private static let sharedInstance = DCFScrollViewComponent()
    
    // Static storage for scroll event handlers
    private static var scrollEventHandlers = [UIScrollView: (String, (String, String, [String: Any]) -> Void)]()
    
    // Store strong reference to self when views are registered
    private static var registeredScrollViews = [UIScrollView: DCFScrollViewComponent]()
    
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        // Create a custom scroll view
        let scrollView = DCFAutoContentScrollView()
        scrollView.delegate = self
        
        // Apply initial styling
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.bounces = true
        
        // Apply props
        updateView(scrollView, withProps: props)
        
        return scrollView
    }
    
    func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool {
        guard let scrollView = view as? UIScrollView else { return false }
        
        // Set shows indicator if specified (fixed property name)
        if let showsScrollIndicator = props["showsScrollIndicator"] as? Bool {
            scrollView.showsVerticalScrollIndicator = showsScrollIndicator
            scrollView.showsHorizontalScrollIndicator = showsScrollIndicator
        }
        
        // Set scroll indicator color if specified
        if let scrollIndicatorColor = props["scrollIndicatorColor"] as? String {
            if #available(iOS 13.0, *) {
                scrollView.verticalScrollIndicatorInsets = UIEdgeInsets.zero
                scrollView.horizontalScrollIndicatorInsets = UIEdgeInsets.zero
                // Note: iOS doesn't directly support scroll indicator color customization
                // This would require a custom implementation
            }
        }
        
        // Set scroll indicator size if specified  
        if let scrollIndicatorSize = props["scrollIndicatorSize"] as? String {
            // iOS scroll indicators have fixed size, but we can store this for custom implementations
            objc_setAssociatedObject(scrollView, 
                                   UnsafeRawPointer(bitPattern: "scrollIndicatorSize".hashValue)!, 
                                   scrollIndicatorSize, 
                                   .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        // Set bounces if specified
        if let bounces = props["bounces"] as? Bool {
            scrollView.bounces = bounces
        }
        
        // Set horizontal if specified
        if let horizontal = props["horizontal"] as? Bool {
            // Configure for horizontal or vertical scrolling
            if horizontal {
                scrollView.alwaysBounceHorizontal = true
                scrollView.alwaysBounceVertical = false
                scrollView.showsHorizontalScrollIndicator = scrollView.showsHorizontalScrollIndicator
                scrollView.showsVerticalScrollIndicator = false
            } else {
                scrollView.alwaysBounceHorizontal = false
                scrollView.alwaysBounceVertical = true
                scrollView.showsHorizontalScrollIndicator = false
                scrollView.showsVerticalScrollIndicator = scrollView.showsVerticalScrollIndicator
            }
        }
        
        // Set paging enabled if specified
        if let pagingEnabled = props["pagingEnabled"] as? Bool {
            scrollView.isPagingEnabled = pagingEnabled
        }
        
        // Set scroll enabled if specified
        if let scrollEnabled = props["scrollEnabled"] as? Bool {
            scrollView.isScrollEnabled = scrollEnabled
        }
        
        // Set clipping if specified (default is true)
        if let clipsToBounds = props["clipsToBounds"] as? Bool {
            scrollView.clipsToBounds = clipsToBounds
        }
        
        // Apply standard styling
        if let backgroundColor = props["backgroundColor"] as? String {
            scrollView.backgroundColor = ColorUtilities.color(fromHexString: backgroundColor)
        }
        
        if let borderRadius = props["borderRadius"] as? CGFloat {
            scrollView.layer.cornerRadius = borderRadius
            scrollView.clipsToBounds = true  
        }
        
        if let borderWidth = props["borderWidth"] as? CGFloat {
            scrollView.layer.borderWidth = borderWidth
        }
        
        if let borderColor = props["borderColor"] as? String {
            scrollView.layer.borderColor = ColorUtilities.color(fromHexString: borderColor)?.cgColor
        }
        
        if let opacity = props["opacity"] as? CGFloat {
            scrollView.alpha = opacity
        }
        
        // Apply content offset if specified
        if let contentOffsetStart = props["contentOffsetStart"] as? CGFloat, contentOffsetStart > 0 {
            if let scrollView = scrollView as? DCFAutoContentScrollView {
                scrollView.extraTopPadding = contentOffsetStart
            }
        }
        
        // Apply content padding top
        if let contentPaddingTop = props["contentPaddingTop"] as? CGFloat, contentPaddingTop > 0 {
            if let scrollView = scrollView as? DCFAutoContentScrollView {
                scrollView.extraTopPadding = contentPaddingTop
            }
        }
        
        // After updating properties, recalculate content size if it's our custom scroll view
        if let customScrollView = scrollView as? DCFAutoContentScrollView {
            customScrollView.recalculateContentSize()
        }
        
        return true
    }
    
    // Custom layout for scroll view
    func applyLayout(_ view: UIView, layout: YGNodeLayout) {
        guard let scrollView = view as? UIScrollView else { return }
        
        // Set the frame of the scroll view
        scrollView.frame = CGRect(x: layout.left, y: layout.top, width: layout.width, height: layout.height)
        
        // Force layout of subviews first
        scrollView.layoutIfNeeded()
        
        // Update content size after layout completed
        if let customScrollView = scrollView as? DCFAutoContentScrollView {
            // Our custom subclass will handle this
            customScrollView.recalculateContentSize()
        } else {
            // For standard UIScrollView, calculate manually
            updateContentSize(scrollView)
        }
    }
    
    // Calculate and update content size based on subviews
    private func updateContentSize(_ scrollView: UIScrollView) {
        var maxWidth: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        // Get the farthest right and bottom edges of all subviews
        for subview in scrollView.subviews {
            let right = subview.frame.origin.x + subview.frame.size.width
            let bottom = subview.frame.origin.y + subview.frame.size.height
            
            maxWidth = max(maxWidth, right)
            maxHeight = max(maxHeight, bottom)
        }
        
        // Add padding to ensure content is fully scrollable
        maxWidth += 40
        maxHeight += 40
        
        // Ensure content size is at least as large as the scroll view bounds
        maxWidth = max(maxWidth, scrollView.bounds.width)
        maxHeight = max(maxHeight, scrollView.bounds.height)
        
        // Determine if this is horizontal or vertical scrolling
        let isHorizontal = scrollView.alwaysBounceHorizontal
        
        // Set different content sizes based on orientation
        if isHorizontal {
            scrollView.contentSize = CGSize(width: maxWidth, height: scrollView.bounds.height)
        } else {
            scrollView.contentSize = CGSize(width: scrollView.bounds.width, height: maxHeight)
        }
    }
    
    // Add a custom view hook for when new children are added
    func viewRegisteredWithShadowTree(_ view: UIView, nodeId: String) {
        // Store node ID on the view
        objc_setAssociatedObject(view, 
                               UnsafeRawPointer(bitPattern: "nodeId".hashValue)!, 
                               nodeId, 
                               .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Observe changes to the view hierarchy to update content size
        if let scrollView = view as? DCFAutoContentScrollView {
            scrollView.didRegisterWithNodeId(nodeId)
        }
    }
    
    // Handle scroll view delegate methods
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        triggerEvent(on: scrollView, eventType: "onScrollBeginDrag", eventData: [
            "contentOffset": [
                "x": scrollView.contentOffset.x,
                "y": scrollView.contentOffset.y
            ]
        ])
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        triggerEvent(on: scrollView, eventType: "onScrollEndDrag", eventData: [
            "contentOffset": [
                "x": scrollView.contentOffset.x,
                "y": scrollView.contentOffset.y
            ],
            "willDecelerate": decelerate
        ])
        
        if !decelerate {
            triggerEvent(on: scrollView, eventType: "onScrollEnd", eventData: [
                "contentOffset": [
                    "x": scrollView.contentOffset.x,
                    "y": scrollView.contentOffset.y
                ]
            ])
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        triggerEvent(on: scrollView, eventType: "onScrollEnd", eventData: [
            "contentOffset": [
                "x": scrollView.contentOffset.x,
                "y": scrollView.contentOffset.y
            ]
        ])
    }
    
    // Handle scroll events for continuous updates
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        triggerEvent(on: scrollView, eventType: "onScroll", eventData: [
            "contentOffset": [
                "x": scrollView.contentOffset.x,
                "y": scrollView.contentOffset.y
            ],
            "contentSize": [
                "width": scrollView.contentSize.width,
                "height": scrollView.contentSize.height
            ],
            "layoutMeasurement": [
                "width": scrollView.bounds.width,
                "height": scrollView.bounds.height
            ]
        ])
    }
    
    // Handle component methods
    func handleMethod(methodName: String, args: [String: Any], view: UIView) -> Bool {
        guard let scrollView = view as? UIScrollView else { return false }
        
        switch methodName {
        case "scrollToPosition":
            if let x = args["x"] as? CGFloat, let y = args["y"] as? CGFloat {
                let animated = args["animated"] as? Bool ?? true
                scrollView.setContentOffset(CGPoint(x: x, y: y), animated: animated)
                return true
            }
        case "scrollToTop":
            let animated = args["animated"] as? Bool ?? true
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: 0), animated: animated)
            return true
        case "scrollToBottom":
            let animated = args["animated"] as? Bool ?? true
            let bottomOffset = CGPoint(x: scrollView.contentOffset.x, 
                                     y: scrollView.contentSize.height - scrollView.bounds.height)
            scrollView.setContentOffset(bottomOffset, animated: animated)
            return true
        case "flashScrollIndicators":
            scrollView.flashScrollIndicators()
            return true
        default:
            return false
        }
        
        return false
    }
    
    // MARK: - Event Handling
    
    func addEventListeners(to view: UIView, viewId: String, eventTypes: [String], 
                          eventCallback: @escaping (String, String, [String: Any]) -> Void) {
        guard let scrollView = view as? UIScrollView else { 
            print("❌ Cannot add event listeners to non-scroll view")
            return 
        }
 
        // Ensure the delegate is set to sharedInstance for event handling
        scrollView.delegate = DCFScrollViewComponent.sharedInstance
        
        // Store event data with associated objects
        storeEventData(on: scrollView, viewId: viewId, eventTypes: eventTypes, callback: eventCallback)
        
        // Store strong reference to component instance to prevent deallocation
        DCFScrollViewComponent.registeredScrollViews[scrollView] = DCFScrollViewComponent.sharedInstance
        
        print("✅ Successfully added event handlers to scroll view \(viewId)")
    }
    
    // Store event data using multiple methods for redundancy
    private func storeEventData(on scrollView: UIScrollView, viewId: String, eventTypes: [String], 
                               callback: @escaping (String, String, [String: Any]) -> Void) {
        // Store the event information as associated objects - generic keys
        objc_setAssociatedObject(
            scrollView,
            UnsafeRawPointer(bitPattern: "viewId".hashValue)!,
            viewId,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        objc_setAssociatedObject(
            scrollView,
            UnsafeRawPointer(bitPattern: "eventTypes".hashValue)!,
            eventTypes,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        objc_setAssociatedObject(
            scrollView,
            UnsafeRawPointer(bitPattern: "eventCallback".hashValue)!,
            callback,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        // Additional redundant storage - scroll specific keys
        objc_setAssociatedObject(
            scrollView,
            UnsafeRawPointer(bitPattern: "scrollViewId".hashValue)!,
            viewId,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        objc_setAssociatedObject(
            scrollView,
            UnsafeRawPointer(bitPattern: "scrollCallback".hashValue)!,
            callback,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        // Store in static dictionary as additional backup
        DCFScrollViewComponent.scrollEventHandlers[scrollView] = (viewId, callback)
    }
    
    func removeEventListeners(from view: UIView, viewId: String, eventTypes: [String]) {
        guard let scrollView = view as? UIScrollView else { return }
        
        // Clean up all references
        cleanupEventReferences(from: scrollView, viewId: viewId)
        
        print("✅ Removed event listeners from scroll view: \(viewId)")
    }
    
    // Helper to clean up all event references
    private func cleanupEventReferences(from scrollView: UIScrollView, viewId: String) {
        // Remove from static handlers dictionary
        DCFScrollViewComponent.scrollEventHandlers.removeValue(forKey: scrollView)
        DCFScrollViewComponent.registeredScrollViews.removeValue(forKey: scrollView)
        
        // Clear all associated objects
        let keys = ["viewId", "eventTypes", "eventCallback", "scrollViewId", "scrollCallback"]
        for key in keys {
            objc_setAssociatedObject(
                scrollView,
                UnsafeRawPointer(bitPattern: key.hashValue)!,
                nil,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

// Custom scroll view that automatically manages its content size
class DCFAutoContentScrollView: UIScrollView {
    private var isUpdatingContentSize = false
    var extraTopPadding: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupScrollView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupScrollView()
    }
    
    private func setupScrollView() {
        clipsToBounds = true
        backgroundColor = .clear
        
        // Fix for safe area handling
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .automatic
        }
    }
    
    // Called when the scroll view is registered with a node ID
    func didRegisterWithNodeId(_ nodeId: String) {
        // Force an initial content size calculation
        DispatchQueue.main.async { [weak self] in
            self?.recalculateContentSize()
        }
    }
    
    // Public method to recalculate content size
    func recalculateContentSize() {
        guard !isUpdatingContentSize else { return }
        isUpdatingContentSize = true
        
        // Calculate based on subview frames
        var maxWidth: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for subview in subviews {
            let right = subview.frame.origin.x + subview.frame.size.width
            let bottom = subview.frame.origin.y + subview.frame.size.height
            
            maxWidth = max(maxWidth, right)
            maxHeight = max(maxHeight, bottom)
        }
        
        // Add padding to ensure content is fully scrollable
        maxWidth += 40
        maxHeight += 40
        
        // Add extra top padding if specified
        if extraTopPadding > 0 {
            // Apply different padding based on orientation
            if alwaysBounceHorizontal {
                maxWidth += extraTopPadding
            } else {
                maxHeight += extraTopPadding
                
                // Reposition existing subviews to add space at the top
                for subview in subviews {
                    if subview != self {
                        var frame = subview.frame
                        frame.origin.y += extraTopPadding
                        subview.frame = frame
                    }
                }
            }
        }
        
        // Set minimum content size to the scroll view's frame
        maxWidth = max(maxWidth, bounds.width)
        maxHeight = max(maxHeight, bounds.height)
        
        // Set based on scrolling direction
        let isHorizontal = alwaysBounceHorizontal
        
        // Use a meaningful minimum content size
        if isHorizontal {
            if maxWidth <= bounds.width {
                maxWidth = bounds.width + 1
            }
            contentSize = CGSize(width: maxWidth, height: bounds.height)
        } else {
            if maxHeight <= bounds.height {
                maxHeight = bounds.height + 1
            }
            contentSize = CGSize(width: bounds.width, height: maxHeight)
        }
        
        isUpdatingContentSize = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Recalculate after layout completes
        DispatchQueue.main.async { [weak self] in
            self?.recalculateContentSize()
        }
    }
    
    // Override content size setter for fixing edge cases
    override var contentSize: CGSize {
        didSet {
            if contentSize.width == 0 || contentSize.height == 0 {
                // Prevent zero content size
                if contentSize.width == 0 {
                    contentSize.width = max(1, bounds.width)
                }
                if contentSize.height == 0 {
                    contentSize.height = max(1, bounds.height)
                }
            }
        }
    }
    
    // Override the method that is called when a subview is added
    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        
        // Schedule content size update
        DispatchQueue.main.async { [weak self] in
            self?.recalculateContentSize()
        }
    }
    
    // Override method when frame changes
    override var frame: CGRect {
        didSet {
            if frame != oldValue {
                DispatchQueue.main.async { [weak self] in
                    self?.recalculateContentSize()
                }
            }
        }
    }
}