import UIKit
import yoga

/// Shadow tree for layout calculations using Yoga
class YogaShadowTree {
    // Singleton instance
    static let shared = YogaShadowTree()
    
    // Root node of the shadow tree
    private var rootNode: YGNodeRef?
    
    // Map of node IDs to yoga nodes
    internal var nodes = [String: YGNodeRef]()
    
    // Map of child-parent relationships
    internal var nodeParents = [String: String]()
    
    // Map for storing component types
    private var nodeTypes = [String: String]()
    
    // Private initializer for singleton
    private init() {
        // Create root node
        rootNode = YGNodeNew()
        
        // Configure default root properties
        if let root = rootNode {
            YGNodeStyleSetDirection(root, YGDirection.LTR)
            YGNodeStyleSetFlexDirection(root, YGFlexDirection.column)
            YGNodeStyleSetWidth(root, Float(UIScreen.main.bounds.width))
            YGNodeStyleSetHeight(root, Float(UIScreen.main.bounds.height))
            
            // Store root node
            nodes["root"] = root
            nodeTypes["root"] = "View"
        }
        
        print("YogaShadowTree initialized with root node")
    }
    
    // Create a new node in the shadow tree
    func createNode(id: String, componentType: String) {
        print("Creating shadow node: \(id) of type \(componentType)")
        
        // Create new node
        let node = YGNodeNew()
        
        if let node = node {
            // Store node
            nodes[id] = node
            nodeTypes[id] = componentType
        }
    }
    
    // Add a child node to a parent node
    func addChildNode(parentId: String, childId: String, index: Int? = nil) {
        guard let parentNode = nodes[parentId], let childNode = nodes[childId] else {
            print("Cannot add child: parent or child node not found")
            return
        }
        
        // First, remove child from any existing parent
        if let oldParentId = nodeParents[childId], let oldParentNode = nodes[oldParentId] {
            YGNodeRemoveChild(oldParentNode, childNode)
        }
        
        // Then add to new parent
        if let index = index {
            // Add at specific index
            let childCount = Int(YGNodeGetChildCount(parentNode))
            if index < childCount {
                YGNodeInsertChild(parentNode, childNode, Int(Int32(index)))
            } else {
                YGNodeInsertChild(parentNode, childNode, Int(Int32(childCount)))
            }
        } else {
            // Add at the end
            let childCount = Int(YGNodeGetChildCount(parentNode))
            YGNodeInsertChild(parentNode, childNode, Int(Int32(childCount)))
        }
        
        // Update parent reference
        nodeParents[childId] = parentId
    }
    
    // Remove a node from the shadow tree
    func removeNode(nodeId: String) {
        guard let node = nodes[nodeId] else {
            return
        }
        
        // Remove from parent if any
        if let parentId = nodeParents[nodeId], let parentNode = nodes[parentId] {
            YGNodeRemoveChild(parentNode, node)
        }
        
        // Clean up children
        let childCount = YGNodeGetChildCount(node)
        for i in 0..<childCount {
            let childNode = YGNodeGetChild(node, 0) // Always remove the first one
            YGNodeRemoveChild(node, childNode)
        }
        
        // Free memory
        YGNodeFree(node)
        
        // Remove references
        nodes.removeValue(forKey: nodeId)
        nodeParents.removeValue(forKey: nodeId)
        nodeTypes.removeValue(forKey: nodeId)
    }
    
    // Update a node's layout properties
    func updateNodeLayoutProps(nodeId: String, props: [String: Any]) {
        guard let node = nodes[nodeId] else {
            print("Cannot update layout: node not found for ID \(nodeId)")
            return
        }
        
        // Process each property
        for (key, value) in props {
            applyLayoutProp(node: node, key: key, value: value)
        }
        
        // Validate layout configuration to prevent crashes
        validateNodeLayoutConfig(nodeId: nodeId)
    }
    
    // Calculate and apply layout
    func calculateAndApplyLayout(width: CGFloat, height: CGFloat) -> Bool {
        print("Layout calculation started with dimensions: \(width)×\(height)")
        
        // Make sure root node exists
        guard let root = nodes["root"] else {
            print("Root node not found. Cannot calculate layout")
            return false
        }
        
        // Set proper width and height on root
        YGNodeStyleSetWidth(root, Float(width))
        YGNodeStyleSetHeight(root, Float(height))
        
        // Pre-validate all nodes to prevent Yoga crashes
        for (nodeId, _) in nodes {
            validateNodeLayoutConfig(nodeId: nodeId)
        }
        
        // Calculate layout with error handling
        do {
            // Use try-catch to handle potential Yoga exceptions
            try {
                YGNodeCalculateLayout(root, Float(width), Float(height), YGDirection.LTR)
            }()
            
            // Apply layout to all views
            for (nodeId, _) in nodes {
                if let layout = getNodeLayout(nodeId: nodeId) {
                    applyLayoutToView(viewId: nodeId, frame: layout)
                }
            }
            return true
        } catch {
            print("❌ Layout calculation failed with error: \(error.localizedDescription)")
            
            // Emergency fallback - try to fix most common issues and retry once
            fixLayoutErrors()
            
            // Try again with fixed layout
            do {
                try {
                    YGNodeCalculateLayout(root, Float(width), Float(height), YGDirection.LTR)
                }()
                
                // Apply layout to all views after recovery
                for (nodeId, _) in nodes {
                    if let layout = getNodeLayout(nodeId: nodeId) {
                        applyLayoutToView(viewId: nodeId, frame: layout)
                    }
                }
                print("✅ Layout recovered after fixing errors")
                return true
            } catch {
                print("❌ Layout calculation failed even after recovery attempt: \(error)")
                return false
            }
        }
    }
    
    // Get layout for a node
    func getNodeLayout(nodeId: String) -> CGRect? {
        guard let node = nodes[nodeId] else { return nil }
        
        // Get layout values
        let left = CGFloat(YGNodeLayoutGetLeft(node))
        let top = CGFloat(YGNodeLayoutGetTop(node))
        let width = CGFloat(YGNodeLayoutGetWidth(node))
        let height = CGFloat(YGNodeLayoutGetHeight(node))
        
        return CGRect(x: left, y: top, width: width, height: height)
    }
    
    // Check and fix any invalid layout configuration issues
    private func validateNodeLayoutConfig(nodeId: String) {
        guard let node = nodes[nodeId] else { return }
        
        // Check if height is undefined and node has children
        if YGNodeGetChildCount(node) > 0 && 
           YGNodeStyleGetHeight(node).unit == YGUnit.undefined {
            
            // Prevent "availableHeight is indefinite" error by setting height sizing mode
            // to YGMeasureModeAtMost when necessary
            YGNodeStyleSetHeightAuto(node)
            
            print("⚠️ Layout Warning: Node \(nodeId) has children but undefined height, defaulting to height:auto")
        }
    }
    
    // Apply a layout property to a node
    private func applyLayoutProp(node: YGNodeRef, key: String, value: Any) {
        switch key {
        case "width":
            if let width = convertToFloat(value) {
                YGNodeStyleSetWidth(node, width)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetWidthPercent(node, percentValue)
            }
        case "height":
            if let height = convertToFloat(value) {
                YGNodeStyleSetHeight(node, height)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetHeightPercent(node, percentValue)
            }
        case "minWidth":
            if let minWidth = convertToFloat(value) {
                YGNodeStyleSetMinWidth(node, minWidth)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetMinWidthPercent(node, percentValue)
            }
        case "maxWidth":
            if let maxWidth = convertToFloat(value) {
                YGNodeStyleSetMaxWidth(node, maxWidth)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetMaxWidthPercent(node, percentValue)
            }
        case "minHeight":
            if let minHeight = convertToFloat(value) {
                YGNodeStyleSetMinHeight(node, minHeight)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetMinHeightPercent(node, percentValue)
            }
        case "maxHeight":
            if let maxHeight = convertToFloat(value) {
                YGNodeStyleSetMaxHeight(node, maxHeight)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetMaxHeightPercent(node, percentValue)
            }
        case "margin":
            if let margin = convertToFloat(value) {
                YGNodeStyleSetMargin(node, YGEdge.all, margin)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetMarginPercent(node, YGEdge.all, percentValue)
            }
        case "marginTop":
            if let marginTop = convertToFloat(value) {
                YGNodeStyleSetMargin(node, YGEdge.top, marginTop)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetMarginPercent(node, YGEdge.top, percentValue)
            }
        case "marginRight":
            if let marginRight = convertToFloat(value) {
                YGNodeStyleSetMargin(node, YGEdge.right, marginRight)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetMarginPercent(node, YGEdge.right, percentValue)
            }
        case "marginBottom":
            if let marginBottom = convertToFloat(value) {
                YGNodeStyleSetMargin(node, YGEdge.bottom, marginBottom)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetMarginPercent(node, YGEdge.bottom, percentValue)
            }
        case "marginLeft":
            if let marginLeft = convertToFloat(value) {
                YGNodeStyleSetMargin(node, YGEdge.left, marginLeft)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetMarginPercent(node, YGEdge.left, percentValue)
            }
        case "padding":
            if let padding = convertToFloat(value) {
                YGNodeStyleSetPadding(node, YGEdge.all, padding)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetPaddingPercent(node, YGEdge.all, percentValue)
            }
        case "paddingTop":
            if let paddingTop = convertToFloat(value) {
                YGNodeStyleSetPadding(node, YGEdge.top, paddingTop)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetPaddingPercent(node, YGEdge.top, percentValue)
            }
        case "paddingRight":
            if let paddingRight = convertToFloat(value) {
                YGNodeStyleSetPadding(node, YGEdge.right, paddingRight)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetPaddingPercent(node, YGEdge.right, percentValue)
            }
        case "paddingBottom":
            if let paddingBottom = convertToFloat(value) {
                YGNodeStyleSetPadding(node, YGEdge.bottom, paddingBottom)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetPaddingPercent(node, YGEdge.bottom, percentValue)
            }
        case "paddingLeft":
            if let paddingLeft = convertToFloat(value) {
                YGNodeStyleSetPadding(node, YGEdge.left, paddingLeft)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetPaddingPercent(node, YGEdge.left, percentValue)
            }
        case "position":
            if let position = value as? String {
                switch position {
                case "absolute":
                    YGNodeStyleSetPositionType(node, YGPositionType.absolute)
                case "relative":
                    YGNodeStyleSetPositionType(node, YGPositionType.relative)
                default:
                    break
                }
            }
        case "left":
            if let left = convertToFloat(value) {
                YGNodeStyleSetPosition(node, YGEdge.left, left)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetPositionPercent(node, YGEdge.left, percentValue)
            }
        case "top":
            if let top = convertToFloat(value) {
                YGNodeStyleSetPosition(node, YGEdge.top, top)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetPositionPercent(node, YGEdge.top, percentValue)
            }
        case "right":
            if let right = convertToFloat(value) {
                YGNodeStyleSetPosition(node, YGEdge.right, right)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetPositionPercent(node, YGEdge.right, percentValue)
            }
        case "bottom":
            if let bottom = convertToFloat(value) {
                YGNodeStyleSetPosition(node, YGEdge.bottom, bottom)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetPositionPercent(node, YGEdge.bottom, percentValue)
            }
        case "flexDirection":
            if let direction = value as? String {
                switch direction {
                case "row":
                    YGNodeStyleSetFlexDirection(node, YGFlexDirection.row)
                case "column":
                    YGNodeStyleSetFlexDirection(node, YGFlexDirection.column)
                case "rowReverse":
                    YGNodeStyleSetFlexDirection(node, YGFlexDirection.rowReverse)
                case "columnReverse":
                    YGNodeStyleSetFlexDirection(node, YGFlexDirection.columnReverse)
                default:
                    break
                }
            }
        case "justifyContent":
            if let justify = value as? String {
                switch justify {
                case "flexStart":
                    YGNodeStyleSetJustifyContent(node, YGJustify.flexStart)
                case "center":
                    YGNodeStyleSetJustifyContent(node, YGJustify.center)
                case "flexEnd":
                    YGNodeStyleSetJustifyContent(node, YGJustify.flexEnd)
                case "spaceBetween":
                    YGNodeStyleSetJustifyContent(node, YGJustify.spaceBetween)
                case "spaceAround":
                    YGNodeStyleSetJustifyContent(node, YGJustify.spaceAround)
                case "spaceEvenly":
                    YGNodeStyleSetJustifyContent(node, YGJustify.spaceEvenly)
                default:
                    break
                }
            }
        case "alignItems":
            if let align = value as? String {
                switch align {
                case "auto":
                    YGNodeStyleSetAlignItems(node, YGAlign.auto)
                case "flexStart":
                    YGNodeStyleSetAlignItems(node, YGAlign.flexStart)
                case "center":
                    YGNodeStyleSetAlignItems(node, YGAlign.center)
                case "flexEnd":
                    YGNodeStyleSetAlignItems(node, YGAlign.flexEnd)
                case "stretch":
                    YGNodeStyleSetAlignItems(node, YGAlign.stretch)
                case "baseline":
                    YGNodeStyleSetAlignItems(node, YGAlign.baseline)
                case "spaceBetween":
                    YGNodeStyleSetAlignItems(node, YGAlign.spaceBetween)
                case "spaceAround":
                    YGNodeStyleSetAlignItems(node, YGAlign.spaceAround)
                default:
                    break
                }
            }
        case "alignSelf":
            if let align = value as? String {
                switch align {
                case "auto":
                    YGNodeStyleSetAlignSelf(node, YGAlign.auto)
                case "flexStart":
                    YGNodeStyleSetAlignSelf(node, YGAlign.flexStart)
                case "center":
                    YGNodeStyleSetAlignSelf(node, YGAlign.center)
                case "flexEnd":
                    YGNodeStyleSetAlignSelf(node, YGAlign.flexEnd)
                case "stretch":
                    YGNodeStyleSetAlignSelf(node, YGAlign.stretch)
                case "baseline":
                    YGNodeStyleSetAlignSelf(node, YGAlign.baseline)
                case "spaceBetween":
                    YGNodeStyleSetAlignSelf(node, YGAlign.spaceBetween)
                case "spaceAround":
                    YGNodeStyleSetAlignSelf(node, YGAlign.spaceAround)
                default:
                    break
                }
            }
        case "flexWrap":
            if let wrap = value as? String {
                switch wrap {
                case "nowrap":
                    YGNodeStyleSetFlexWrap(node, YGWrap.noWrap)
                case "wrap":
                    YGNodeStyleSetFlexWrap(node, YGWrap.wrap)
                case "wrapReverse":
                    YGNodeStyleSetFlexWrap(node, YGWrap.wrapReverse)
                default:
                    break
                }
            }
        case "flex":
            if let flex = convertToFloat(value) {
                YGNodeStyleSetFlex(node, flex)
            }
        case "flexGrow":
            if let flexGrow = convertToFloat(value) {
                YGNodeStyleSetFlexGrow(node, flexGrow)
            }
        case "flexShrink":
            if let flexShrink = convertToFloat(value) {
                YGNodeStyleSetFlexShrink(node, flexShrink)
            }
        case "flexBasis":
            if let flexBasis = convertToFloat(value) {
                YGNodeStyleSetFlexBasis(node, flexBasis)
            } else if let strValue = value as? String, strValue.hasSuffix("%"),
                     let percentValue = Float(strValue.dropLast()) {
                YGNodeStyleSetFlexBasisPercent(node, percentValue)
            }
        case "display":
            if let display = value as? String {
                switch display {
                case "flex":
                    YGNodeStyleSetDisplay(node, YGDisplay.flex)
                case "none":
                    YGNodeStyleSetDisplay(node, YGDisplay.none)
                default:
                    break
                }
            }
        case "overflow":
            if let overflow = value as? String {
                switch overflow {
                case "visible":
                    YGNodeStyleSetOverflow(node, YGOverflow.visible)
                case "hidden":
                    YGNodeStyleSetOverflow(node, YGOverflow.hidden)
                case "scroll":
                    YGNodeStyleSetOverflow(node, YGOverflow.scroll)
                default:
                    break
                }
            }
        case "direction":
            if let direction = value as? String {
                switch direction {
                case "inherit":
                    YGNodeStyleSetDirection(node, YGDirection.inherit)
                case "ltr":
                    YGNodeStyleSetDirection(node, YGDirection.LTR)
                case "rtl":
                    YGNodeStyleSetDirection(node, YGDirection.RTL)
                default:
                    break
                }
            }
        case "borderWidth":
            if let borderWidth = convertToFloat(value) {
                YGNodeStyleSetBorder(node, YGEdge.all, borderWidth)
            }
        case "aspectRatio":
            if let aspectRatio = convertToFloat(value) {
                YGNodeStyleSetAspectRatio(node, aspectRatio)
            }
        case "gap":
            if let gap = convertToFloat(value) {
                YGNodeStyleSetGap(node, YGGutter.all, gap)
            }
        case "rowGap":
            if let rowGap = convertToFloat(value) {
                YGNodeStyleSetGap(node, YGGutter.row, rowGap)
            }
        case "columnGap":
            if let columnGap = convertToFloat(value) {
                YGNodeStyleSetGap(node, YGGutter.column, columnGap)
            }
        default:
            break
        }
    }
    
    // Fix common layout errors that cause crashes
    private func fixLayoutErrors() {
        print("🔧 Attempting to fix layout errors...")
        
        for (nodeId, node) in nodes {
            // Fix 1: Set auto height for nodes with children but undefined height
            if YGNodeGetChildCount(node) > 0 && YGNodeStyleGetHeight(node).unit == YGUnit.undefined {
                print("🔧 Setting auto height for node \(nodeId) to prevent availableHeight crash")
                YGNodeStyleSetHeightAuto(node)
            }
            
            // Fix 2: If a leaf node with no width/height, set reasonable defaults
            if YGNodeGetChildCount(node) == 0 && 
               YGNodeStyleGetHeight(node).unit == YGUnit.undefined &&
               YGNodeStyleGetWidth(node).unit == YGUnit.undefined {
                print("🔧 Setting minimum dimensions for leaf node \(nodeId)")
                YGNodeStyleSetMinHeight(node, 1)
                YGNodeStyleSetMinWidth(node, 1)
            }
            
            // Fix 3: If node has flex but no defined dimensions, set flex basis auto
            if YGNodeStyleGetFlex(node) != 0 && 
               YGNodeStyleGetHeight(node).unit == YGUnit.undefined &&
               YGNodeStyleGetWidth(node).unit == YGUnit.undefined {
                print("🔧 Setting flexBasis:auto for flex node \(nodeId)")
                YGNodeStyleSetFlexBasisAuto(node)
            }
            
            // Fix 4: For rows with undefined height, set height:auto
            if YGNodeStyleGetFlexDirection(node) == YGFlexDirection.row &&
               YGNodeStyleGetHeight(node).unit == YGUnit.undefined {
                print("🔧 Setting height:auto for row container \(nodeId)")
                YGNodeStyleSetHeightAuto(node)
            }
        }
    }

    // Helper to convert input values to Float
    private func convertToFloat(_ value: Any) -> Float? {
        if let num = value as? Float {
            return num
        } else if let num = value as? Double {
            return Float(num)
        } else if let num = value as? Int {
            return Float(num)
        } else if let num = value as? CGFloat {
            return Float(num)
        } else if let str = value as? String, let num = Float(str) {
            return num
        }
        return nil
    }
    
    // Set a custom measure function for nodes that need to self-measure
    func setCustomMeasureFunction(nodeId: String, measureFunc: @escaping YGMeasureFunc) {
        guard let node = nodes[nodeId] else { return }
        
        // Make sure node has no children before setting measure function
        if YGNodeGetChildCount(node) == 0 {
            YGNodeSetMeasureFunc(node, measureFunc)
        }
    }
    
    // Apply layout to a view
    private func applyLayoutToView(viewId: String, frame: CGRect) {
        // Get the view from the layout manager
        guard let view = DCFLayoutManager.shared.getView(withId: viewId) else {
            return
        }
        
        // Apply layout using layout manager
        DispatchQueue.main.async {
            DCFLayoutManager.shared.applyLayout(
                to: viewId,
                left: frame.origin.x,
                top: frame.origin.y,
                width: frame.width,
                height: frame.height
            )
        }
    }
    
    // Cleanup
    deinit {
        // Free all nodes
        for (_, node) in nodes {
            YGNodeFree(node)
        }
    }
}

