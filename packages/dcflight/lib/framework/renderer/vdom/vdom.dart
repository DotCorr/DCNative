import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:dcflight/framework/renderer/interface/interface.dart' show PlatformInterface;
import 'package:dcflight/framework/renderer/vdom/component/component.dart';
import 'package:dcflight/framework/renderer/vdom/component/error_boundary.dart';
export 'package:dcflight/framework/renderer/vdom/component/store.dart';
import 'package:dcflight/framework/renderer/vdom/vdom_element.dart';
import 'package:dcflight/framework/renderer/vdom/vdom_node.dart';
import 'package:dcflight/framework/renderer/vdom/component/fragment.dart';

/// Virtual DOM implementation with efficient reconciliation and state handling
class VDom {
  /// Native bridge for UI operations
  final PlatformInterface _nativeBridge;
  
  /// Whether the VDom is ready for use
  final Completer<void> _readyCompleter = Completer<void>();

  /// Counter for generating unique view IDs
  int _viewIdCounter = 1;
  
  /// Map of view IDs to their associated VDomNodes
  final Map<String, VDomNode> _nodesByViewId = {};
  
  /// Map to track component instances by their instance ID
  final Map<String, StatefulComponent> _statefulComponents = {};
  
  /// Map to track components by their instance ID
  final Map<String, StatelessComponent> _statelessComponents = {};
  
  /// Map to track previous rendered nodes for components (for proper reconciliation)
  final Map<String, VDomNode> _previousRenderedNodes = {};
  
  /// Pending component updates for batching
  final Set<String> _pendingUpdates = {};
  
  /// Flag to track if an update batch is scheduled
  bool _isUpdateScheduled = false;

  /// Flag to track batch updates in progress
  bool _batchUpdateInProgress = false;
  
  /// Root component for the application
  VDomNode? rootComponent;
  
  /// Error boundary registry
  final Map<String, ErrorBoundary> _errorBoundaries = {};

  /// Create a new VDom instance with the provided native bridge
  VDom(this._nativeBridge) {
    _initialize();
  }

  /// Initialize the VDom with the native bridge
  Future<void> _initialize() async {
    try {
      // Initialize bridge
      final success = await _nativeBridge.initialize();
      if (!success) {
        throw Exception('Failed to initialize native bridge');
      }
      
      // Register event handler
      _nativeBridge.setEventHandler(_handleNativeEvent);
      
      // Mark as ready
      _readyCompleter.complete();
      
      if (kDebugMode) {
        developer.log('VDOM initialized successfully', name: 'VDOM');
      }
    } catch (e) {
      _readyCompleter.completeError(e);
      if (kDebugMode) {
        developer.log('Failed to initialize VDom: $e', name: 'VDom', error: e);
      }
    }
  }

  /// Future that completes when VDom is ready
  Future<void> get isReady => _readyCompleter.future;

  /// Generate a unique view ID
  String _generateViewId() {
    return (_viewIdCounter++).toString();
  }
  
  /// Register a component in the VDOM
  void registerComponent(VDomNode component) {
    if (component is StatefulComponent) {
      _statefulComponents[component.instanceId] = component;
      component.scheduleUpdate = () => _scheduleComponentUpdate(component);
    } else if (component is StatelessComponent) {
      _statelessComponents[component.instanceId] = component;
    }
    
    // Register error boundary if applicable
    if (component is ErrorBoundary) {
      _errorBoundaries[component.instanceId] = component;
    }
  }
  
  /// Handle a native event by finding the appropriate component and calling its handler
  void _handleNativeEvent(
      String viewId, String eventType, Map<String, dynamic> eventData) {
    final node = _nodesByViewId[viewId];
    if (node == null) {
      if (kDebugMode) {
        developer.log('⚠️ No node found for viewId: $viewId', name: 'VDom');
      }
      return;
    }

    if (node is VDomElement) {
      // Try direct event handler match
      if (node.props.containsKey(eventType) && node.props[eventType] is Function) {
        _executeEventHandler(node.props[eventType], eventData);
        return;
      }

      // Try canonical "onEventName" format
      final propName = 'on${eventType[0].toUpperCase()}${eventType.substring(1)}';
      
      if (node.props.containsKey(propName) && node.props[propName] is Function) {
        _executeEventHandler(node.props[propName], eventData);
      }
    }
  }

  /// Execute an event handler with proper error handling
  void _executeEventHandler(Function handler, Map<String, dynamic> eventData) {
    try {
      if (handler is Function(Map<String, dynamic>)) {
        handler(eventData);
      } else if (handler is Function()) {
        handler();
      } else {
        Function.apply(handler, [], {});
      }
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log('❌ Error executing event handler: $e', 
            name: 'VDom', error: e, stackTrace: stack);
      }
    }
  }

  /// Schedule a component update when state changes
  /// This is a key method that triggers UI updates after state changes
  void _scheduleComponentUpdate(StatefulComponent component) {
    if (kDebugMode) {
      print('Scheduling update for component: ${component.instanceId} (${component.runtimeType})');
    }
    
    // Verify component is still registered
    if (!_statefulComponents.containsKey(component.instanceId)) {
      if (kDebugMode) {
        print('Warning: Attempting to update unregistered component: ${component.instanceId}');
      }
      // Re-register the component to ensure it's tracked
      registerComponent(component);
    }
    
    // Add to the pending updates queue
    _pendingUpdates.add(component.instanceId);
    
    // Find the root component from this component
    VDomNode? rootComponentCandidate = component;
    while (rootComponentCandidate != null && rootComponentCandidate.parent != null) {
      rootComponentCandidate = rootComponentCandidate.parent;
    }
    
    // If this is a top-level fragment, make sure the entire app updates
    if (rootComponent != null && rootComponentCandidate == rootComponent) {
      if (kDebugMode) {
        print('Adding global app update to ensure full reconciliation');
      }
    }
    
    // Add the direct container component to ensure proper reconciliation
    VDomNode? parent = component.parent;
    while (parent != null) {
      // Update parent components to propagate the changes up the tree
      if (parent is StatefulComponent) {
        if (kDebugMode) {
          print('  Adding parent component to update queue: ${parent.instanceId} (${parent.runtimeType})');
        }
        _pendingUpdates.add(parent.instanceId);
      } 
      // Continue walking up the tree to find all affected components
      parent = parent.parent;
    }

    // Only schedule a new update if one isn't already scheduled
    if (!_isUpdateScheduled) {
      _isUpdateScheduled = true;

      // Schedule updates asynchronously to batch multiple updates
      // Use a very short delay to allow multiple state changes to be batched together
      // but maintain responsiveness
      Future.microtask(_processPendingUpdates);
    }
  }

  /// Process all pending component updates in a batch
  Future<void> _processPendingUpdates() async {
    // Prevent re-entry during batch processing
    if (_batchUpdateInProgress) {
      return;
    }
    
    _batchUpdateInProgress = true;
    
    try {
      if (_pendingUpdates.isEmpty) {
        _isUpdateScheduled = false;
        _batchUpdateInProgress = false;
        return;
      }

      if (kDebugMode) {
        print('Processing ${_pendingUpdates.length} pending updates');
      }

      // Copy the pending updates to allow for new ones during processing
      final updates = Set<String>.from(_pendingUpdates);
      _pendingUpdates.clear();
      
      // Start batch update in native layer
      await _nativeBridge.startBatchUpdate();
      
      try {
        // Process each component update
        for (final componentId in updates) {
          await _updateComponentById(componentId);
        }
        
        // Commit all batched updates at once
        await _nativeBridge.commitBatchUpdate();
        
        // Calculate layout at the end for all updates at once
        await calculateAndApplyLayout();
      } catch (e) {
        // Cancel batch if there's an error
        await _nativeBridge.cancelBatchUpdate();
        rethrow;
      }

      // Check if new updates were scheduled during processing
      if (_pendingUpdates.isNotEmpty) {
        // Process new updates in next microtask
        if (kDebugMode) {
          print('Scheduling another update batch for ${_pendingUpdates.length} components');
        }
        Future.microtask(_processPendingUpdates);
      } else {
        _isUpdateScheduled = false;
      }
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log('Error processing updates: $e', 
            name: 'VDom', error: e, stackTrace: stack);
      }
    } finally {
      _batchUpdateInProgress = false;
    }
  }

  /// Update a component by its ID
  Future<void> _updateComponentById(String componentId) async {
    final component = _statefulComponents[componentId] ?? _statelessComponents[componentId];
    if (component == null) {
      if (kDebugMode) {
        print('⚠️ Cannot update component - not found: $componentId');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('Updating component: $componentId (${component.runtimeType})');
      }
      
      // Perform component-specific update preparation
      if (component is StatefulComponent) {
        component.prepareForRender();
      }

      // Store the previous rendered node before re-rendering
      final oldRenderedNode = component.renderedNode;
      
      // Store a reference to the old rendered node for proper reconciliation
      if (oldRenderedNode != null) {
        _previousRenderedNodes[componentId] = oldRenderedNode;
      }
      
      // Force re-render by clearing cached rendered node
      component.renderedNode = null;
      final newRenderedNode = component.renderedNode;
      
      if (newRenderedNode == null) {
        if (kDebugMode) {
          developer.log('Component rendered null: $componentId', name: 'VDom');
        }
        return;
      }

      // Set parent relationship for the new rendered node
      newRenderedNode.parent = component;
      
      // Reconcile trees to apply minimal changes
      final previousRenderedNode = _previousRenderedNodes[componentId];
      if (previousRenderedNode != null) {
        // Find parent native view ID and index for replacement
        final parentViewId = _findParentViewId(component);
        
        if (kDebugMode) {
          print('Reconciling from old node (${previousRenderedNode.runtimeType}): ' +
              '${previousRenderedNode.effectiveNativeViewId} to new node (${newRenderedNode.runtimeType})');
        }
        
        if (previousRenderedNode.effectiveNativeViewId == null || parentViewId == null) {
          // For problematic components or when we don't have required IDs, use standard reconciliation
          await _reconcile(previousRenderedNode, newRenderedNode);
          
          // Update contentViewId reference from old to new
          if (previousRenderedNode.effectiveNativeViewId != null) {
            component.contentViewId = previousRenderedNode.effectiveNativeViewId;
          }
        } else {
          // Reconcile to preserve structure and update props efficiently
          await _reconcile(previousRenderedNode, newRenderedNode);
          
          // Update contentViewId reference
          component.contentViewId = previousRenderedNode.effectiveNativeViewId;
        }
        
        // Clean up the stored previous rendered node
        _previousRenderedNodes.remove(componentId);
      } else {
        // No previous rendering, create from scratch
        final parentViewId = _findParentViewId(component);
        if (parentViewId != null) {
          if (kDebugMode) {
            print('Creating new rendered node for component with parent: $parentViewId');
          }
          final newViewId = await renderToNative(newRenderedNode, parentViewId: parentViewId);
          if (newViewId != null) {
            component.contentViewId = newViewId;
          }
        } else if (kDebugMode) {
          print('Cannot create new rendered node: parent viewId not found');
        }
      }

      // Run lifecycle methods
      if (component is StatefulComponent) {
        component.componentDidUpdate({});
        component.runEffectsAfterRender();
      }
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log('Error updating component: $e', 
            name: 'VDom', error: e, stackTrace: stack);
      }
    }
  }

  /// Calculate and apply layout
  Future<void> calculateAndApplyLayout({double? width, double? height}) async {
    await isReady;
    final success = await _nativeBridge.calculateLayout();
    if (!success && kDebugMode) {
      developer.log('⚠️ Layout calculation failed', name: 'VDom');
    }
  }

  /// Render a node to native UI
  Future<String?> renderToNative(VDomNode node,
      {String? parentViewId, int? index}) async {
    await isReady;

    try {
      // Handle Fragment nodes
      if (node is Fragment) {
        // Render children directly to parent
        int childIndex = index ?? 0;
        final childIds = <String>[];
        
        for (final child in node.children) {
          final childId = await renderToNative(
            child,
            parentViewId: parentViewId,
            index: childIndex++,
          );
          
          if (childId != null && childId.isNotEmpty) {
            childIds.add(childId);
          }
        }
        
        return null; // Fragments don't have their own ID
      }

      // Handle Component nodes
      if (node is StatefulComponent || node is StatelessComponent) {
        try {
          // Register the component
          registerComponent(node);
          
          // Get the rendered content
          final renderedNode = node.renderedNode;
          if (renderedNode == null) {
            throw Exception('Component rendered null');
          }
          
          // Set parent relationship
          renderedNode.parent = node;

          // Render the content
          final viewId = await renderToNative(renderedNode, parentViewId: parentViewId, index: index);
          
          // Store the view ID
          node.contentViewId = viewId;
          
          // Call lifecycle method if not already mounted
          if (node is StatefulComponent && !node.isMounted) {
            node.componentDidMount();
          } else if (node is StatelessComponent && !node.isMounted) {
            node.componentDidMount();
          }
          
          // Run effects for stateful components
          if (node is StatefulComponent) {
            node.runEffectsAfterRender();
          }
          
          return viewId;
        } catch (error, stackTrace) {
          // Try to find nearest error boundary
          final errorBoundary = _findNearestErrorBoundary(node);
          if (errorBoundary != null) {
            errorBoundary.handleError(error, stackTrace);
            return null; // Error handled by boundary
          }
          
          // No error boundary, propagate error
          rethrow;
        }
      } 
      // Handle Element nodes
      else if (node is VDomElement) {
        return await _renderElementToNative(node, parentViewId: parentViewId, index: index);
      } 
      // Handle EmptyVDomNode
      else if (node is EmptyVDomNode) {
        return null; // Empty nodes don't create native views
      }

      return null;
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log('Error rendering node: $e', 
            name: 'VDom', error: e, stackTrace: stack);
      }
      return null;
    }
  }

  /// Render an element to native UI
  Future<String?> _renderElementToNative(VDomElement element,
      {String? parentViewId, int? index}) async {
    // Use existing view ID or generate a new one
    final viewId = element.nativeViewId ?? _generateViewId();

    // Store map from view ID to node
    _nodesByViewId[viewId] = element;
    element.nativeViewId = viewId;

    // Create the view
    final success = await _nativeBridge.createView(viewId, element.type, element.props);
    if (!success) {
      if (kDebugMode) {
        developer.log('Failed to create view: $viewId of type ${element.type}',
            name: 'VDom');
      }
      return null;
    }

    // If parent is specified, attach to parent
    if (parentViewId != null) {
      await _nativeBridge.attachView(viewId, parentViewId, index ?? 0);
    }

    // Register event listeners
    final eventTypes = element.eventTypes;
    if (eventTypes.isNotEmpty) {
      await _nativeBridge.addEventListeners(viewId, eventTypes);
    }

    // Render children
    final childIds = <String>[];

    for (var i = 0; i < element.children.length; i++) {
      final childId = await renderToNative(element.children[i], parentViewId: viewId, index: i);
      if (childId != null && childId.isNotEmpty) {
        childIds.add(childId);
      }
    }

    // Set children order
    if (childIds.isNotEmpty) {
      await _nativeBridge.setChildren(viewId, childIds);
    }

    return viewId;
  }

  /// Reconcile two nodes by efficiently updating only what changed
  Future<void> _reconcile(VDomNode oldNode, VDomNode newNode) async {
    // Transfer important parent reference first
    newNode.parent = oldNode.parent;
    
    if (kDebugMode) {
      print('Reconciling ${oldNode.runtimeType} to ${newNode.runtimeType}');
    }

    // If the node types are completely different, replace the node entirely
    if (oldNode.runtimeType != newNode.runtimeType) {
      if (kDebugMode) {
        print('Different node types: ${oldNode.runtimeType} -> ${newNode.runtimeType}');
      }
      await _replaceNode(oldNode, newNode);
      return;
    }

    // Handle different node types
    if (oldNode is VDomElement && newNode is VDomElement) {
      // If different element types, we need to replace it
      if (oldNode.type != newNode.type) {
        await _replaceNode(oldNode, newNode);
      } else {
        // Same element type - update props and children only
        await _reconcileElement(oldNode, newNode);
      }
    } 
    // Handle component nodes
    else if (oldNode is StatefulComponent && newNode is StatefulComponent) {
      // Transfer important properties between nodes
      newNode.nativeViewId = oldNode.nativeViewId;
      newNode.contentViewId = oldNode.contentViewId;
      
      // Update component tracking
      _statefulComponents[newNode.instanceId] = newNode;
      newNode.scheduleUpdate = oldNode.scheduleUpdate;
      
      // Register the new component instance
      registerComponent(newNode);
      
      // Handle reconciliation of the rendered trees
      final oldRenderedNode = oldNode.renderedNode;
      final newRenderedNode = newNode.renderedNode;
      
      if (oldRenderedNode != null && newRenderedNode != null) {
        // Standard reconciliation for components
        await _reconcile(oldRenderedNode, newRenderedNode);
      } else if (newRenderedNode != null) {
        // Old rendered node is null but new one exists - create from scratch
        final parentViewId = _findParentViewId(newNode);
        if (parentViewId != null) {
          final newViewId = await renderToNative(newRenderedNode, parentViewId: parentViewId);
          if (newViewId != null) {
            newNode.contentViewId = newViewId;
          }
        }
      }
    }
    // Handle stateless components
    else if (oldNode is StatelessComponent && newNode is StatelessComponent) {
      // Transfer IDs
      newNode.nativeViewId = oldNode.nativeViewId;
      newNode.contentViewId = oldNode.contentViewId;
      
      // Handle reconciliation of the rendered trees
      final oldRenderedNode = oldNode.renderedNode;
      final newRenderedNode = newNode.renderedNode;
      
      if (oldRenderedNode != null && newRenderedNode != null) {
        await _reconcile(oldRenderedNode, newRenderedNode);
      }
    }
    // Handle Fragment nodes
    else if (oldNode is Fragment && newNode is Fragment) {
      // Transfer children relationships
      newNode.parent = oldNode.parent;
      
      // Reconcile fragment children directly since fragments don't have native view IDs
      if (oldNode.children.isNotEmpty || newNode.children.isNotEmpty) {
        // Find the parent view ID to reconcile children against
        final parentViewId = _findParentViewId(oldNode);
        if (parentViewId != null) {
          await _reconcileFragmentChildren(parentViewId, oldNode.children, newNode.children);
        }
      }
    }
    // Handle empty nodes
    else if (oldNode is EmptyVDomNode && newNode is EmptyVDomNode) {
      // Nothing to do for empty nodes
      return;
    }
  }
  
  // No special handling for specific component types - all components are treated equally
  
  /// Replace a node entirely
  Future<void> _replaceNode(VDomNode oldNode, VDomNode newNode) async {
    // Can't replace if the old node has no view ID
    if (oldNode.effectiveNativeViewId == null) {
      return;
    }

    // Find parent info for placing the new node
    final parentViewId = _findParentViewId(oldNode);
    if (parentViewId == null) {
      if (kDebugMode) {
        developer.log('Failed to find parent ID for node replacement', name: 'VDom');
      }
      return;
    }

    // Find index of node in parent
    final index = _findNodeIndexInParent(oldNode);

    // Delete the old view
    await _nativeBridge.deleteView(oldNode.effectiveNativeViewId!);
    _nodesByViewId.remove(oldNode.effectiveNativeViewId);
    
    // Create the new view
    final newViewId = await renderToNative(newNode, parentViewId: parentViewId, index: index);
    
    // Update references
    if (newViewId != null && newViewId.isNotEmpty) {
      newNode.nativeViewId = newViewId;
      _nodesByViewId[newViewId] = newNode;
    }
  }

  /// Find a node's parent view ID
  String? _findParentViewId(VDomNode node) {
    VDomNode? current = node.parent;
    
    // Find the first parent with a native view ID
    while (current != null) {
      final viewId = current.effectiveNativeViewId;
      if (viewId != null && viewId.isNotEmpty) {
        return viewId;
      }
      current = current.parent;
    }
    
    // Default to root if no parent found
    return "root";
  }

  /// Find a node's index in its parent's children
  int _findNodeIndexInParent(VDomNode node) {
    // Can't determine index without parent
    if (node.parent == null) return 0;
    
    // Only element parents can have indexed children
    if (node.parent is! VDomElement) return 0;
    
    final parent = node.parent as VDomElement;
    return parent.children.indexOf(node);
  }

  /// Reconcile an element - update props and children
  Future<void> _reconcileElement(VDomElement oldElement, VDomElement newElement) async {
    // Update properties if the element has a native view
    if (oldElement.nativeViewId != null) {
      // Copy native view ID to new element for tracking
      newElement.nativeViewId = oldElement.nativeViewId;
      
      // Find changed props using proper diffing algorithm
      final changedProps = _diffProps(oldElement.props, newElement.props);
      
      // Update props if there are changes
      if (changedProps.isNotEmpty) {
        if (kDebugMode) {
          print('Updating props for ${oldElement.type} (${oldElement.nativeViewId}): $changedProps');
        }
        
        // First ensure old element is in tracking map with updated ID
        _nodesByViewId[oldElement.nativeViewId!] = newElement;
        
        // Update the native view
        await _nativeBridge.updateView(oldElement.nativeViewId!, changedProps);
      }
      
      // Now reconcile children with the most efficient algorithm
      await _reconcileChildren(oldElement, newElement);
    }
  }

  /// Compute differences between two prop maps
  Map<String, dynamic> _diffProps(Map<String, dynamic> oldProps, Map<String, dynamic> newProps) {
    final changedProps = <String, dynamic>{};
    
    // Find added or changed props
    for (final entry in newProps.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Skip function handlers - they're managed separately by event system
      if (value is Function) continue;
      
      // Add to changes if prop is new or has different value
      if (!oldProps.containsKey(key) || oldProps[key] != value) {
        changedProps[key] = value;
      }
    }
    
    // Find removed props (set to null to delete)
    for (final key in oldProps.keys) {
      if (!newProps.containsKey(key) && oldProps[key] is! Function) {
        changedProps[key] = null;
      }
    }
    
    // Handle event handlers - preserve them if not changed
    for (final key in oldProps.keys) {
      if (key.startsWith('on') && 
          oldProps[key] is Function &&
          !newProps.containsKey(key)) {
        changedProps[key] = oldProps[key];
      }
    }
    
    return changedProps;
  }

  /// Reconcile children with keyed optimization
  Future<void> _reconcileChildren(VDomElement oldElement, VDomElement newElement) async {
    final oldChildren = oldElement.children;
    final newChildren = newElement.children;
    
    // Fast path: no children
    if (oldChildren.isEmpty && newChildren.isEmpty) return;
    
    // Check if children have keys for optimized reconciliation
    final hasKeys = _childrenHaveKeys(newChildren);
    
    if (hasKeys) {
      await _reconcileKeyedChildren(
        oldElement.nativeViewId!, 
        oldChildren, 
        newChildren
      );
    } else {
      await _reconcileSimpleChildren(
        oldElement.nativeViewId!, 
        oldChildren, 
        newChildren
      );
    }
  }

  /// Check if any children have explicit keys
  bool _childrenHaveKeys(List<VDomNode> children) {
    if (children.isEmpty) return false;
    
    for (var child in children) {
      if (child.key != null) return true;
    }
    
    return false;
  }

  /// Reconcile fragment children directly without a container element
  Future<void> _reconcileFragmentChildren(String parentViewId, 
      List<VDomNode> oldChildren, List<VDomNode> newChildren) async {
    // Use the same reconciliation logic as elements but for fragment children
    final hasKeys = _childrenHaveKeys(newChildren);
    
    if (hasKeys) {
      await _reconcileKeyedChildren(parentViewId, oldChildren, newChildren);
    } else {
      await _reconcileSimpleChildren(parentViewId, oldChildren, newChildren);
    }
  }

  /// Reconcile children with keys for optimal reordering
  Future<void> _reconcileKeyedChildren(String parentViewId, 
      List<VDomNode> oldChildren, List<VDomNode> newChildren) async {
    // Create map of old children by key for O(1) lookup
    final oldChildrenMap = <String?, VDomNode>{};
    for (int i = 0; i < oldChildren.length; i++) {
      final oldChild = oldChildren[i];
      final key = oldChild.key ?? i.toString(); // Use index for null keys
      oldChildrenMap[key] = oldChild;
    }
    
    // Track children that need to be in final list
    final updatedChildIds = <String>[];
    final processedOldChildren = <VDomNode>{};
    
    // Process each new child
    for (int i = 0; i < newChildren.length; i++) {
      final newChild = newChildren[i];
      final key = newChild.key ?? i.toString();
      final oldChild = oldChildrenMap[key];
      
      String? childViewId;
      
      if (oldChild != null) {
        // Mark as processed
        processedOldChildren.add(oldChild);
        
        // Update existing child
        await _reconcile(oldChild, newChild);
        
        // Get the view ID (which might come from different sources)
        childViewId = oldChild.effectiveNativeViewId;
        
        // Update position if needed
        if (childViewId != null) {
          await _moveChild(childViewId, parentViewId, i);
        }
      } else {
        // Create new child
        childViewId = await renderToNative(newChild, parentViewId: parentViewId, index: i);
      }
      
      // Add to updated children list
      if (childViewId != null) {
        updatedChildIds.add(childViewId);
      }
    }
    
    // Remove old children that aren't in the new list
    for (var oldChild in oldChildren) {
      if (!processedOldChildren.contains(oldChild)) {
        final viewId = oldChild.effectiveNativeViewId;
        if (viewId != null) {
          await _nativeBridge.deleteView(viewId);
          _nodesByViewId.remove(viewId);
        }
      }
    }
    
    // Ensure children are in correct order
    if (updatedChildIds.isNotEmpty) {
      await _nativeBridge.setChildren(parentViewId, updatedChildIds);
    }
  }

  /// Reconcile children without keys (simpler algorithm)
  Future<void> _reconcileSimpleChildren(String parentViewId, 
      List<VDomNode> oldChildren, List<VDomNode> newChildren) async {
    final updatedChildIds = <String>[];
    final commonLength = math.min(oldChildren.length, newChildren.length);
    
    // Update common children
    for (int i = 0; i < commonLength; i++) {
      final oldChild = oldChildren[i];
      final newChild = newChildren[i];
      
      // Reconcile the child
      await _reconcile(oldChild, newChild);
      
      // Add to updated children
      final childViewId = oldChild.effectiveNativeViewId;
      if (childViewId != null) {
        updatedChildIds.add(childViewId);
      }
    }
    
    // Handle length differences
    if (newChildren.length > oldChildren.length) {
      // Add any extra new children
      for (int i = commonLength; i < newChildren.length; i++) {
        final childViewId = await renderToNative(
          newChildren[i], 
          parentViewId: parentViewId, 
          index: i
        );
        
        if (childViewId != null) {
          updatedChildIds.add(childViewId);
        }
      }
    } else if (oldChildren.length > newChildren.length) {
      // Remove any extra old children
      for (int i = commonLength; i < oldChildren.length; i++) {
        final viewId = oldChildren[i].effectiveNativeViewId;
        if (viewId != null) {
          await _nativeBridge.deleteView(viewId);
          _nodesByViewId.remove(viewId);
        }
      }
    }
    
    // Ensure children are in correct order
    if (updatedChildIds.isNotEmpty) {
      await _nativeBridge.setChildren(parentViewId, updatedChildIds);
    }
  }

  /// Move a child to a specific index in its parent
  Future<void> _moveChild(String childId, String parentId, int index) async {
    // Detach and then attach again at the right position
    await _nativeBridge.detachView(childId);
    await _nativeBridge.attachView(childId, parentId, index);
  }

  /// Find the nearest error boundary
  ErrorBoundary? _findNearestErrorBoundary(VDomNode node) {
    VDomNode? current = node;
    
    while (current != null) {
      if (current is ErrorBoundary) {
        return current;
      }
      current = current.parent;
    }
    
    return null;
  }

  /// Create the root component for the application
  Future<void> createRoot(VDomNode component) async {
    rootComponent = component;
    
    // Register the component with this VDOM
    registerComponent(component);
    
    // Render to native
    await renderToNative(component, parentViewId: "root");
    
    // Calculate layout
    await calculateAndApplyLayout();
    
    if (kDebugMode) {
      print('VDOM is ready to calculate');
    }
  }
}
