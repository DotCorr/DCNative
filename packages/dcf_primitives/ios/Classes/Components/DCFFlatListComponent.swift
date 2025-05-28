import UIKit
import dcflight

class DCFFlatListComponent: NSObject, DCFComponent {
    private static var listInstances: [UIView: DCFFlatListView] = [:]
    
    required override init() {
        super.init()
    }
    
    func createView(props: [String: Any]) -> UIView {
        let flatListView = DCFFlatListView()
        
        // Store reference
        DCFFlatListComponent.listInstances[flatListView] = flatListView
        
        // Apply initial properties
        updateView(flatListView, withProps: props)
        
        return flatListView
    }
    
    func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool {
        guard let flatListView = view as? DCFFlatListView else { return false }
        
        flatListView.updateWithProps(props)
        return true
    }
}

// MARK: - High-Performance FlatList View

class DCFFlatListView: UIView {
    private var collectionView: UICollectionView!
    private var flowLayout: UICollectionViewFlowLayout!
    
    // Performance optimization properties
    private var estimatedItemSize: CGFloat = 50
    private var itemCount: Int = 0
    private var orientation: String = "vertical"
    private var inverted: Bool = false
    
    // FlashList-inspired optimizations
    private var initialNumToRender: Int = 10
    private var maxToRenderPerBatch: Int = 10
    private var windowSize: Int = 21
    private var removeClippedSubviews: Bool = true
    
    // Scroll properties
    private var showsVerticalScrollIndicator: Bool = true
    private var showsHorizontalScrollIndicator: Bool = true
    private var bounces: Bool = true
    private var pagingEnabled: Bool = false
    private var snapToInterval: CGFloat?
    
    // Item sizing
    private var itemSizeCache: [Int: CGSize] = [:]
    private var averageItemSize: CGSize = CGSize(width: 50, height: 50)
    
    // Recycling optimization
    private var visibleRange: Range<Int> = 0..<0
    private var renderRange: Range<Int> = 0..<0
    
    // Event handlers
    private var onScroll: ((CGFloat, CGFloat) -> Void)?
    private var onEndReached: (() -> Void)?
    private var onViewableItemsChanged: (([Int]) -> Void)?
    
    // Threshold for onEndReached
    private var onEndReachedThreshold: CGFloat = 0.1
    private var hasTriggeredEndReached: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCollectionView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        // Create flow layout
        flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        
        // Create collection view
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        
        // Register cell
        collectionView.register(DCFFlatListCell.self, forCellWithReuseIdentifier: "DCFFlatListCell")
        
        addSubview(collectionView)
        
        // Setup constraints
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func updateWithProps(_ props: [String: Any]) {
        // Update data count
        if let count = props["data"] as? Int {
            let oldCount = itemCount
            itemCount = count
            
            if oldCount != count {
                updateCollectionView()
            }
        }
        
        // Update orientation
        if let newOrientation = props["orientation"] as? String {
            if orientation != newOrientation {
                orientation = newOrientation
                flowLayout.scrollDirection = orientation == "horizontal" ? .horizontal : .vertical
                collectionView.reloadData()
            }
        }
        
        // Update inverted
        if let newInverted = props["inverted"] as? Bool {
            if inverted != newInverted {
                inverted = newInverted
                updateInvertedTransform()
            }
        }
        
        // Update performance properties
        if let initialNum = props["initialNumToRender"] as? Int {
            initialNumToRender = initialNum
        }
        
        if let maxBatch = props["maxToRenderPerBatch"] as? Int {
            maxToRenderPerBatch = maxBatch
        }
        
        if let window = props["windowSize"] as? Int {
            windowSize = window
        }
        
        if let removeClipped = props["removeClippedSubviews"] as? Bool {
            removeClippedSubviews = removeClipped
        }
        
        // Update scroll indicators
        if let showsVertical = props["showsVerticalScrollIndicator"] as? Bool {
            showsVerticalScrollIndicator = showsVertical
            collectionView.showsVerticalScrollIndicator = showsVertical
        }
        
        if let showsHorizontal = props["showsHorizontalScrollIndicator"] as? Bool {
            showsHorizontalScrollIndicator = showsHorizontal
            collectionView.showsHorizontalScrollIndicator = showsHorizontal
        }
        
        // Update bounces
        if let newBounces = props["bounces"] as? Bool {
            bounces = newBounces
            collectionView.bounces = bounces
        }
        
        // Update paging
        if let newPaging = props["pagingEnabled"] as? Bool {
            pagingEnabled = newPaging
            collectionView.isPagingEnabled = pagingEnabled
        }
        
        // Update snap to interval
        if let interval = props["snapToInterval"] as? CGFloat {
            snapToInterval = interval
        }
        
        // Update estimated item size
        if let size = props["estimatedItemSize"] as? CGFloat {
            estimatedItemSize = size
            averageItemSize = CGSize(width: size, height: size)
        }
        
        // Update end reached threshold
        if let threshold = props["onEndReachedThreshold"] as? CGFloat {
            onEndReachedThreshold = threshold
        }
        
        // Store event callbacks
        storeEventCallbacks(props)
    }
    
    private func storeEventCallbacks(_ props: [String: Any]) {
        // Store event handlers (simplified - in real implementation, these would be connected to the bridge)
        // This is where we'd connect to the DCFlight event system
    }
    
    private func updateCollectionView() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.updateVisibleRange()
        }
    }
    
    private func updateInvertedTransform() {
        if inverted {
            if orientation == "horizontal" {
                collectionView.transform = CGAffineTransform(scaleX: -1, y: 1)
            } else {
                collectionView.transform = CGAffineTransform(scaleX: 1, y: -1)
            }
        } else {
            collectionView.transform = CGAffineTransform.identity
        }
    }
    
    private func updateVisibleRange() {
        let visibleRect = collectionView.bounds
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        
        if !visibleIndexPaths.isEmpty {
            let visibleIndices = visibleIndexPaths.map { $0.item }.sorted()
            let newVisibleRange = visibleIndices.first!..<(visibleIndices.last! + 1)
            
            if newVisibleRange != visibleRange {
                visibleRange = newVisibleRange
                
                // Calculate render range with window size
                let windowBuffer = windowSize / 2
                let renderStart = max(0, visibleRange.lowerBound - windowBuffer)
                let renderEnd = min(itemCount, visibleRange.upperBound + windowBuffer)
                renderRange = renderStart..<renderEnd
                
                // Trigger viewable items changed
                onViewableItemsChanged?(Array(visibleRange))
                
                // Trigger end reached if necessary
                checkEndReached()
                
                // Optimize memory by removing clipped subviews
                if removeClippedSubviews {
                    optimizeMemoryUsage()
                }
            }
        }
    }
    
    private func checkEndReached() {
        guard !hasTriggeredEndReached else { return }
        
        let scrollOffset = orientation == "horizontal" ? 
            collectionView.contentOffset.x : collectionView.contentOffset.y
        let contentSize = orientation == "horizontal" ? 
            collectionView.contentSize.width : collectionView.contentSize.height
        let frameSize = orientation == "horizontal" ? 
            collectionView.frame.width : collectionView.frame.height
        
        let distanceFromEnd = contentSize - (scrollOffset + frameSize)
        let threshold = frameSize * onEndReachedThreshold
        
        if distanceFromEnd <= threshold {
            hasTriggeredEndReached = true
            onEndReached?()
            
            // Reset flag after a delay to allow for new content loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.hasTriggeredEndReached = false
            }
        }
    }
    
    private func optimizeMemoryUsage() {
        // This would implement aggressive memory optimization
        // by recycling cells that are far outside the render range
        let visibleCells = collectionView.visibleCells
        
        for cell in visibleCells {
            if let indexPath = collectionView.indexPath(for: cell) {
                if !renderRange.contains(indexPath.item) {
                    // Mark cell for recycling optimization
                    cell.prepareForReuse()
                }
            }
        }
    }
    
    private func estimateItemSize(for index: Int) -> CGSize {
        // Return cached size if available
        if let cachedSize = itemSizeCache[index] {
            return cachedSize
        }
        
        // Use estimated size for performance
        return averageItemSize
    }
    
    private func cacheItemSize(_ size: CGSize, for index: Int) {
        itemSizeCache[index] = size
        
        // Update average size for better estimates
        let totalCachedSizes = itemSizeCache.values.reduce(CGSize.zero) { result, size in
            return CGSize(width: result.width + size.width, height: result.height + size.height)
        }
        
        let count = CGFloat(itemSizeCache.count)
        averageItemSize = CGSize(
            width: totalCachedSizes.width / count,
            height: totalCachedSizes.height / count
        )
    }
}

// MARK: - Collection View Data Source

extension DCFFlatListView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DCFFlatListCell", for: indexPath) as! DCFFlatListCell
        
        // Configure cell for index
        cell.configureForIndex(indexPath.item, inverted: inverted, orientation: orientation)
        
        return cell
    }
}

// MARK: - Collection View Delegate & Flow Layout

extension DCFFlatListView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return estimateItemSize(for: indexPath.item)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Cache actual cell size after display
        cacheItemSize(cell.frame.size, for: indexPath.item)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateVisibleRange()
        
        // Trigger scroll event
        onScroll?(scrollView.contentOffset.x, scrollView.contentOffset.y)
        
        // Trigger scroll events to bridge
        DCFComponent.triggerEvent(
            from: self,
            eventType: "onScroll",
            eventData: [
                "contentOffset": [
                    "x": scrollView.contentOffset.x,
                    "y": scrollView.contentOffset.y
                ],
                "contentSize": [
                    "width": scrollView.contentSize.width,
                    "height": scrollView.contentSize.height
                ]
            ]
        )
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        DCFComponent.triggerEvent(
            from: self,
            eventType: "onScrollBeginDrag",
            eventData: [:]
        )
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        DCFComponent.triggerEvent(
            from: self,
            eventType: "onScrollEndDrag",
            eventData: ["decelerate": decelerate]
        )
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        DCFComponent.triggerEvent(
            from: self,
            eventType: "onMomentumScrollBegin",
            eventData: [:]
        )
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        DCFComponent.triggerEvent(
            from: self,
            eventType: "onMomentumScrollEnd",
            eventData: [:]
        )
    }
}

// MARK: - Collection View Data Source Prefetching

extension DCFFlatListView: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        // Implement prefetching logic for performance
        // This would typically involve preparing data for upcoming cells
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        // Cancel prefetching operations that are no longer needed
    }
}

// MARK: - High-Performance Collection View Cell

class DCFFlatListCell: UICollectionViewCell {
    private var itemIndex: Int = 0
    private var isInverted: Bool = false
    private var orientation: String = "vertical"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    private func setupCell() {
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
    }
    
    func configureForIndex(_ index: Int, inverted: Bool, orientation: String) {
        itemIndex = index
        isInverted = inverted
        self.orientation = orientation
        
        // Apply inverted transform to individual cells if needed
        if inverted {
            if orientation == "horizontal" {
                contentView.transform = CGAffineTransform(scaleX: -1, y: 1)
            } else {
                contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
            }
        } else {
            contentView.transform = CGAffineTransform.identity
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset cell state for optimal recycling
        contentView.transform = CGAffineTransform.identity
        contentView.subviews.forEach { $0.removeFromSuperview() }
    }
}
