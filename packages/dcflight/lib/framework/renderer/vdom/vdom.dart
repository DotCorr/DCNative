import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:dcflight/framework/renderer/interface/interface.dart' show NativeBridgeFactory, PlatformInterface;
import 'package:dcflight/framework/renderer/vdom/component/component.dart';
import 'package:dcflight/framework/renderer/vdom/component/error_boundary.dart';
export 'package:dcflight/framework/renderer/vdom/component/store.dart';
import 'package:dcflight/framework/renderer/vdom/vdom_element.dart';
import '../../constants/layout_properties.dart';
import 'vdom_node.dart';
import 'component/fragment.dart';

/// Helper class to store parent information
class _ParentInfo {
  final String parentId;
  final int index;

  _ParentInfo(this.parentId, this.index);
}

/// Performance monitoring for VDOM operations
class PerformanceMonitor {
  /// Map of timers by name
  final Map<String, _Timer> _timers = {};

  /// Map of metrics by name
  final Map<String, _Metric> _metrics = {};

  /// Critical operations that we want to monitor
  static const List<String> _criticalOperations = [
    'vdom_initialize',
    'reconcile',
    'batch_update',
    'native_layout_calculation',
    'render_to_native'
  ];

  /// Start a timer with the given name
  void startTimer(String name) {
    // Only time critical operations
    if (_criticalOperations.contains(name)) {
      _timers[name] = _Timer(DateTime.now());
    }
  }

  /// End a timer with the given name
  void endTimer(String name) {
    // Only process critical operations
    if (!_criticalOperations.contains(name)) return;
    
    final timer = _timers[name];
    if (timer == null) return;

    final duration = DateTime.now().difference(timer.startTime);

    // Update or create the metric
    final metric = _metrics[name] ?? _Metric(name);
    metric.count++;
    metric.totalDuration += duration.inMicroseconds;
    metric.maxDuration = duration.inMicroseconds > metric.maxDuration
        ? duration.inMicroseconds
        : metric.maxDuration;
    metric.minDuration =
        metric.minDuration == 0 || duration.inMicroseconds < metric.minDuration
            ? duration.inMicroseconds
            : metric.minDuration;

    _metrics[name] = metric;

    // Remove the timer
    _timers.remove(name);
  }

  /// Get a metrics report as a map
  Map<String, dynamic> getMetricsReport() {
    final report = <String, dynamic>{};

    for (final metric in _metrics.values) {
      report[metric.name] = {
        'count': metric.count,
        'totalMs': metric.totalDuration / 1000.0,
        'avgMs': metric.count > 0
            ? (metric.totalDuration / metric.count) / 1000.0
            : 0,
        'maxMs': metric.maxDuration / 1000.0,
        'minMs': metric.minDuration / 1000.0,
      };
    }

    return report;
  }

  /// Reset all metrics
  void reset() {
    _timers.clear();
    _metrics.clear();
  }
}

/// Internal timer class
class _Timer {
  final DateTime startTime;
  _Timer(this.startTime);
}

/// Internal metric class
class _Metric {
  final String name;
  int count = 0;
  int totalDuration = 0;
  int maxDuration = 0;
  int minDuration = 0;

  _Metric(this.name);
}

/// Represents an instance of a component
class _ComponentInstance {
  /// The component node
  final VDomNode component;

  /// Previous rendered tree
  VDomNode? previousNode;

  /// Whether component is mounted
  bool isMounted = false;

  _ComponentInstance({
    required this.component,
  });
}

/// Virtual DOM implementation
class VDom {
  /// Native bridge for UI operations
  late final PlatformInterface _nativeBridge;

  /// Whether the VDom is ready for use
  final Completer<void> _readyCompleter = Completer<void>();

  /// Counter for generating view IDs
  int _viewIdCounter = 1;

  /// Map of components by ID
  final Map<String, VDomNode> _components = {};

  /// Enriched component instances with additional tracking
  final Map<String, _ComponentInstance> _componentInstances = {};

  /// Map of view IDs to VDomNodes
  final Map<String, VDomNode> _nodesByViewId = {};

  // Removed the detached nodes cache
  
  /// Performance monitoring
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  /// Current batch update
  final Set<String> _pendingUpdates = {};

  /// Whether an update is scheduled
  bool _isUpdateScheduled = false;

  /// Error boundaries
  final Map<String, ErrorBoundary> _errorBoundaries = {};

  /// Root component (for main application)
  VDomNode? rootComponent;

  /// Create a new VDom instance
  VDom() {
    _initialize();
  }

  /// Initialize the VDom
  Future<void> _initialize() async {
    try {
      _performanceMonitor.startTimer('vdom_initialize');

      // Create native bridge
      _nativeBridge = NativeBridgeFactory.create();

      // Initialize bridge
      final success = await _nativeBridge.initialize();

      if (!success) {
        throw Exception('Failed to initialize native bridge');
      }

      // Register event handler
      _nativeBridge.setEventHandler(_handleNativeEvent);

      // Mark as ready
      _readyCompleter.complete();

      developer.log('VDom initialized', name: 'VDom');
      _performanceMonitor.endTimer('vdom_initialize');
    } catch (e) {
      _readyCompleter.completeError(e);
      developer.log('Failed to initialize VDom: $e', name: 'VDom', error: e);
    }
  }

  /// Future that completes when VDom is ready
  Future<void> get isReady => _readyCompleter.future;

  /// Generate a unique view ID
  String _generateViewId() {
    return (_viewIdCounter++).toString();
  }

  /// Register a component in the VDOM
  VDomNode registerComponent(VDomNode component) {
    String instanceId;
    
    // Get the instanceId based on the component type
    if (component is StatefulComponent) {
      instanceId = component.instanceId;
      component.scheduleUpdate = () => _scheduleComponentUpdate(component);
    } else if (component is StatelessComponent) {
      instanceId = component.instanceId;
    } else {
      throw ArgumentError('Component must be StatefulComponent or StatelessComponent');
    }

    // Store component by ID
    _components[instanceId] = component;

    // Create and register a component instance
    _componentInstances[instanceId] = _ComponentInstance(
      component: component,
    );

    return component;
  }

  /// Handle a native event
  void _handleNativeEvent(
      String viewId, String eventType, Map<String, dynamic> eventData) {
    _performanceMonitor.startTimer('handle_native_event');

    final node = _nodesByViewId[viewId];
    if (node == null) {
      developer.log('⚠️ No node found for viewId: $viewId', name: 'VDom');
      _performanceMonitor.endTimer('handle_native_event');
      return;
    }

    if (node is VDomElement) {
      // First try direct event matching (used by many native components)
      if (node.props.containsKey(eventType) && node.props[eventType] is Function) {
        _executeEventHandler(node.props[eventType], eventData);
        _performanceMonitor.endTimer('handle_native_event');
        return;
      }

      // Then try canonical "onEventName" format
      final propName =
          'on${eventType[0].toUpperCase()}${eventType.substring(1)}';

      // Call the handler if it exists
      if (node.props.containsKey(propName) &&
          node.props[propName] is Function) {
        _executeEventHandler(node.props[propName], eventData);
      }
    }
    
    _performanceMonitor.endTimer('handle_native_event');
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
      developer.log('❌ Error executing event handler: $e', 
          name: 'VDom', error: e, stackTrace: stack);
    }
  }

  /// Create a new element
  VDomElement createElement(
    String type, {
    Map<String, dynamic>? props,
    List<VDomNode>? children,
    String? key,
  }) {
    return VDomElement(
      type: type,
      props: props ?? {},
      children: children ?? [],
      key: key,
    );
  }

  /// Render a node to native UI
  Future<String?> renderToNative(VDomNode node,
      {String? parentId, int? index}) async {
    await isReady;

    _performanceMonitor.startTimer('render_to_native');
    try {
      // Handle Fragment nodes
      if (node is Fragment) {
        // Just render children directly to parent
        final childIds = <String>[];
        int childIndex = index ?? 0;

        for (final child in node.children) {
          final childId = await renderToNative(
            child,
            parentId: parentId,
            index: childIndex++,
          );

          if (childId != null && childId.isNotEmpty) {
            childIds.add(childId);
          }
        }

        return ""; // Fragments don't have their own ID
      }

      if (node is StatefulComponent || node is StatelessComponent) {
        try {
          return await _renderComponentToNative(node,
              parentId: parentId, index: index);
        } catch (error, stackTrace) {
          // Try to find nearest error boundary
          final errorBoundary = _findNearestErrorBoundary(node);
          if (errorBoundary != null) {
            errorBoundary.handleError(error, stackTrace);
            return ""; // Error handled by boundary
          }

          // No error boundary, propagate error
          rethrow;
        }
      } else if (node is VDomElement) {
        return await _renderElementToNative(node,
            parentId: parentId, index: index);
      }

      return null;
    } finally {
      _performanceMonitor.endTimer('render_to_native');
    }
  }

  /// Get component ID regardless of component type
  String _getComponentId(VDomNode component) {
    if (component is StatefulComponent) {
      return component.instanceId;
    } else if (component is StatelessComponent) {
      return component.instanceId;
    }
    throw ArgumentError('Component must be StatefulComponent or StatelessComponent');
  }
  
  /// Get the rendered result from a component
  VDomNode _getRenderResult(VDomNode component) {
    if (component is StatefulComponent || component is StatelessComponent) {
      final renderedNode = component.renderedNode;
      if (renderedNode == null) {
        throw Exception('Component rendered null');
      }
      return renderedNode;
    }
    throw ArgumentError('Component must be StatefulComponent or StatelessComponent');
  }

  /// Render a component to native UI
  Future<String?> _renderComponentToNative(VDomNode component,
      {String? parentId, int? index}) async {
    // Get component ID and instance
    final instanceId = _getComponentId(component);
    final componentInstance = _componentInstances[instanceId];
    
    // Handle specific component type preparations
    if (component is StatefulComponent) {
      // Set the update function
      component.scheduleUpdate = () => _scheduleComponentUpdate(component);
      
      // Reset hook state before render for stateful components
      component.prepareForRender();
    }

    // Render the component
    final renderedNode = _getRenderResult(component);

    // Set parent-child relationship
    component.renderedNode = renderedNode;
    renderedNode.parent = component;

    // Render the rendered node
    final viewId =
        await renderToNative(renderedNode, parentId: parentId, index: index);

    // Store the view ID
    component.contentViewId = viewId;

    // Mark as mounted if not already (common lifecycle handling)
    if (componentInstance != null && !componentInstance.isMounted) {
      // Call lifecycle method
      component.componentDidMount();
      componentInstance.isMounted = true;
    }

    // Register error boundary if applicable
    if (component is ErrorBoundary) {
      _errorBoundaries[instanceId] = component;
    }

    // Run effects after render for stateful components
    if (component is StatefulComponent &&
        componentInstance?.isMounted == true) {
      component.runEffectsAfterRender();
    }

    return viewId;
  }

  /// Render an element to native UI
  Future<String?> _renderElementToNative(VDomElement element,
      {String? parentId, int? index}) async {
    // Use existing view ID or generate a new one
    String? viewId = element.nativeViewId ?? _generateViewId();

    // Store map from node to view ID
    _nodesByViewId[viewId] = element;
    element.nativeViewId = viewId;

    // Create the view
    _performanceMonitor.startTimer('create_native_view');
    final success =
        await _nativeBridge.createView(viewId, element.type, element.props);
    _performanceMonitor.endTimer('create_native_view');

    if (!success) {
      developer.log('Failed to create view: $viewId of type ${element.type}',
          name: 'VDom');
      return null;
    }

    // If parent is specified, attach to parent
    if (parentId != null) {
      await attachView(viewId, parentId, index ?? 0);
    }

    // Register event listeners
    final eventTypes = element.eventTypes;
    if (eventTypes.isNotEmpty) {
      await _nativeBridge.addEventListeners(viewId, eventTypes);
    }

    // Render children
    final childIds = <String>[];

    for (var i = 0; i < element.children.length; i++) {
      final childId =
          await renderToNative(element.children[i], parentId: viewId, index: i);

      if (childId != null && childId.isNotEmpty) {
        childIds.add(childId);
      }
    }

    // Set children order
    if (childIds.isNotEmpty) {
      await _nativeBridge.setChildren(viewId, childIds);
    }

    // Call lifecycle methods after full rendering
    _callLifecycleMethodsIfNeeded(element);

    return viewId;
  }
  
  // Removed reconcileChildrenForReusedView method

  /// Calculate and apply layout
  Future<void> calculateAndApplyLayout({double? width, double? height}) async {
    _performanceMonitor.startTimer('native_layout_calculation');
    final success = await _nativeBridge.calculateLayout();
    _performanceMonitor.endTimer('native_layout_calculation');

    if (!success) {
      developer.log('⚠️ Native layout calculation failed', name: 'VDom');
    }
  }

  /// Schedule a component update for batching
  /// 
  /// When component state changes, this method is called to schedule an update.
  /// Updates are batched and processed asynchronously to improve performance.
  /// This is the entry point for all state-driven UI updates.
  ///
  /// @param component The component that needs updating
  void _scheduleComponentUpdate(StatefulComponent component) {
    // Add to the pending updates queue
    _pendingUpdates.add(component.instanceId);

    // Only schedule a new update if one isn't already pending
    if (_isUpdateScheduled) return;
    _isUpdateScheduled = true;

    // Schedule updates to run in the next microtask to batch multiple updates
    // This improves performance by avoiding redundant renders
    Future.microtask(() {
      _processPendingUpdates();
    });
  }

  /// Process all pending component updates
  Future<void> _processPendingUpdates() async {
    if (_pendingUpdates.isEmpty) {
      _isUpdateScheduled = false;
      return;
    }

    _performanceMonitor.startTimer('batch_update');

    // Copy the pending updates to allow for new ones during processing
    final updates = Set<String>.from(_pendingUpdates);
    _pendingUpdates.clear();

    // Process each pending component update
    for (final instanceId in updates) {
      final component = _findComponentById(instanceId);
      if (component != null) {
        await _updateComponent(component.instanceId);
      }
    }

    _performanceMonitor.endTimer('batch_update');

    // Check if new updates were added during processing
    if (_pendingUpdates.isNotEmpty) {
      // Process new updates in next microtask to avoid deep recursion
      Future.microtask(() {
        _processPendingUpdates();
      });
    } else {
      _isUpdateScheduled = false;
    }
  }

  /// Find a component by its ID
  StatefulComponent? _findComponentById(String instanceId) {
    for (final entry in _components.entries) {
      if (entry.key == instanceId && entry.value is StatefulComponent) {
        return entry.value as StatefulComponent;
      }
    }
    return null;
  }

  /// Update a component
  Future<void> _updateComponent(String componentId) async {
    if (!_components.containsKey(componentId)) {
      return;
    }

    final component = _components[componentId]!;

    // Handle stateful components
    if (component is StatefulComponent) {
      // Reset hook state before render but preserve values
      component.prepareForRender();
    }

    // Re-render the component
    final oldRenderedNode = component.renderedNode;
    final newRenderedNode = _getRenderResult(component);

    // Update the rendered node
    component.renderedNode = newRenderedNode;
    newRenderedNode.parent = component;

    // Reconcile nodes
    if (oldRenderedNode != null) {
      _performanceMonitor.startTimer('reconcile');
      await _reconcile(oldRenderedNode, newRenderedNode);
      _performanceMonitor.endTimer('reconcile');
    } else if (component.contentViewId != null) {
      // If no previous node but we have a content view ID, this might be a special case
      // Handle by re-rendering to native
      final parentId = _findParentViewId(component);
      if (parentId != null) {
        await renderToNative(newRenderedNode, parentId: parentId, index: 0);
      }
    }

    // Update component lifecycle
    if (component is StatefulComponent) {
      component.componentDidUpdate({});
      component.runEffectsAfterRender();
    }
  }

  /// Reconcile two nodes by efficiently updating only what changed
  /// 
  /// This is the core diff algorithm that compares the old and new virtual DOM nodes
  /// and applies minimal changes to the native UI. It handles different node types
  /// appropriately, either replacing completely different nodes or updating similar ones.
  ///
  /// @param oldNode The previous virtual DOM node
  /// @param newNode The new virtual DOM node that will replace it
  Future<void> _reconcile(VDomNode oldNode, VDomNode newNode) async {
    // If the node types are different, replace the old node completely
    if (oldNode.runtimeType != newNode.runtimeType) {
      await _replaceNode(oldNode, newNode);
      return;
    }

    // For elements, reconcile props and children
    if (oldNode is VDomElement && newNode is VDomElement) {
      // Same element type? (e.g., both are "div" or "text")
      if (oldNode.type == newNode.type) {
        // Same key or both null? If keys are different they should be replaced, not updated
        if (oldNode.key == newNode.key) {
          // Update the element with new props and reconcile children
          await _reconcileElement(oldNode, newNode);
          return;
        }
      }
      // Different type or key - replacement needed
      await _replaceNode(oldNode, newNode);
    } 
    // For stateful components
    else if (oldNode is StatefulComponent && newNode is StatefulComponent) {
      // Update the component if it's the same type
      if (oldNode.runtimeType == newNode.runtimeType) {
        // Copy over native view IDs for proper tracking
        newNode.nativeViewId = oldNode.nativeViewId;
        newNode.contentViewId = oldNode.contentViewId;
        
        // Update the component
        await _updateComponent(oldNode.instanceId);
      } else {
        // Different component type - replacement needed
        await _replaceNode(oldNode, newNode);
      }
    } 
    // For stateless components
    else if (oldNode is StatelessComponent && newNode is StatelessComponent) {
      // Update the component if it's the same type
      if (oldNode.runtimeType == newNode.runtimeType) {
        // Copy over native view IDs for proper tracking
        newNode.nativeViewId = oldNode.nativeViewId;
        newNode.contentViewId = oldNode.contentViewId;
        
        // Update the component
        await _updateComponent(oldNode.instanceId);
      } else {
        // Different component type - replacement needed
        await _replaceNode(oldNode, newNode);
      }
    }
    
    // Always trigger layout calculation at the root level
    if (newNode == rootComponent?.renderedNode) {
      // Defer to next frame to avoid multiple recalculations in a single frame
      Future.microtask(() => calculateAndApplyLayout());
    }
  }

  /// Replace an old node with a new node entirely
  /// 
  /// When nodes cannot be efficiently updated (different types or keys),
  /// this method completely removes the old node and creates a new one.
  /// This is more expensive than reconciliation but necessary for substantial changes.
  ///
  /// @param oldNode The existing node to be removed
  /// @param newNode The new node to be created in its place
  Future<void> _replaceNode(VDomNode oldNode, VDomNode newNode) async {
    // Skip if the old node doesn't have a native view to replace
    if (oldNode.nativeViewId == null) {
      return;
    }
    
    // Get parent info for insertion
    final parentInfo = _getParentInfo(oldNode);
    if (parentInfo == null) {
      developer.log('Failed to find parent info for node replacement',
          name: 'VDom');
      return;
    }
    
    final parentId = parentInfo.parentId;
    final index = parentInfo.index;
    
    // Delete the old node
    await deleteView(oldNode.nativeViewId!);
    
    // Create the new node under the same parent
    final newNodeId = await renderToNative(newNode, parentId: parentId, index: index);
    
    // Update references
    newNode.nativeViewId = newNodeId;
    if (oldNode.nativeViewId != null) {
      removeNodeFromTree(oldNode.nativeViewId!);
    }
    
    if (newNodeId != null && newNodeId.isNotEmpty) {
      addNodeToTree(newNodeId, newNode);
    }
  }
  
  /// Get parent information for a node
  _ParentInfo? _getParentInfo(VDomNode node) {
    // The node must have a parent to get parent info
    if (node.parent == null) {
      return null;
    }

    final parent = node.parent!;
    // Check if parent is an element with a native view
    if (parent is! VDomElement || parent.nativeViewId == null) {
      return null;
    }

    // Find index of node in parent's children
    final index = parent.children.indexOf(node);
    if (index < 0) return null;

    return _ParentInfo(parent.nativeViewId!, index);
  }

  /// Reconcile two elements by updating props and children
  /// 
  /// Updates an existing element with new props and reconciles its children.
  /// This avoids recreating the entire subtree and preserves state in children.
  ///
  /// @param oldElement The existing element in the DOM
  /// @param newElement The new element with updated props/children
  Future<void> _reconcileElement(VDomElement oldElement, VDomElement newElement) async {
    // Update the properties of the old element if it already has a native view
    if (oldElement.nativeViewId != null) {
      // Copy the native view ID to the new element for tracking
      newElement.nativeViewId = oldElement.nativeViewId;
      
      // Find changed props with generic diffing
      final changedProps = <String, dynamic>{};
      
      // Check for props that have changed or been added
      for (final entry in newElement.props.entries) {
        final key = entry.key;
        final value = entry.value;
        
        // If prop has changed or is new
        if (!oldElement.props.containsKey(key) ||
            oldElement.props[key] != value) {
          changedProps[key] = value;
        }
      }
      
      // Check for removed props
      for (final key in oldElement.props.keys) {
        if (!newElement.props.containsKey(key)) {
          // Set to null to indicate removal
          changedProps[key] = null;
        }
      }
      
      // Update props directly if there are changes
      if (changedProps.isNotEmpty) {
        // Preserve existing event handlers
        oldElement.props.forEach((key, value) {
          if (key.startsWith('on') &&
              value is Function &&
              !changedProps.containsKey(key)) {
            changedProps[key] = value;
          }
        });
        
        await updateView(oldElement.nativeViewId!, changedProps);
        
        // Request layout calculation if any layout props changed
        if (changedProps.keys.any((key) => LayoutProps.isLayoutProperty(key))) {
          // Defer layout calculation to avoid multiple recalculations
          Future.microtask(() => calculateAndApplyLayout());
        }
      }
      
      // Now reconcile children
      await _reconcileChildren(oldElement, newElement);
    }
  }

  /// Reconcile children of two elements
  Future<void> _reconcileChildren(VDomElement oldElement, VDomElement newElement) async {
    final oldChildren = oldElement.children;
    final newChildren = newElement.children;

    // Fast-path: no children in either old or new
    if (oldChildren.isEmpty && newChildren.isEmpty) return;

    // Check if children have keys for more efficient reconciliation
    final hasKeys = _childrenHaveKeys(newChildren);

    if (hasKeys) {
      // Use keyed reconciliation for better performance with reordering
      await _reconcileKeyedChildren(oldElement.nativeViewId!, oldChildren, newChildren);
    } else {
      // Use simple non-keyed reconciliation
      await _reconcileNonKeyedChildren(oldElement.nativeViewId!, oldChildren, newChildren);
    }
  }
  
  /// Check if children have explicit keys
  bool _childrenHaveKeys(List<VDomNode> children) {
    if (children.isEmpty) return false;
    
    // Check if any child has a key
    for (var child in children) {
      if (child.key != null) return true;
    }
    
    return false;
  }
  
  /// Reconcile keyed children with maximum reuse
  Future<void> _reconcileKeyedChildren(String parentViewId,
      List<VDomNode> oldChildren, List<VDomNode> newChildren) async {
    // Map old children by key for O(1) lookup
    final oldChildrenMap = <String?, VDomNode>{};
    
    for (int i = 0; i < oldChildren.length; i++) {
      final oldChild = oldChildren[i];
      final key = oldChild.key ?? i.toString(); // Use index for null keys
      oldChildrenMap[key] = oldChild;
    }

    // Track updated children views
    final updatedChildren = <String>[];
    final processedOldChildren = <VDomNode>{};

    // Process each new child
    for (int i = 0; i < newChildren.length; i++) {
      final newChild = newChildren[i];
      final key = newChild.key ?? i.toString();
      final oldChild = oldChildrenMap[key];

      if (oldChild != null) {
        // Mark as processed
        processedOldChildren.add(oldChild);
        
        // Reuse child - update it
        await _reconcile(oldChild, newChild);

        // Add to updated children if it has a view
        if (oldChild.nativeViewId != null) {
          updatedChildren.add(oldChild.nativeViewId!);
          
          // Always move to ensure correct order
          await _moveViewInParent(oldChild.nativeViewId!, parentViewId, i);
        }
      } else {
        // New child - create it
        final childId = await renderToNative(newChild,
            parentId: parentViewId, index: i);

        if (childId != null && childId.isNotEmpty) {
          updatedChildren.add(childId);
          newChild.nativeViewId = childId;
        }
      }
    }

    // Remove old children that aren't in the new list
    for (var oldChild in oldChildren) {
      if (!processedOldChildren.contains(oldChild) && oldChild.nativeViewId != null) {
        await deleteView(oldChild.nativeViewId!);
      }
    }

    // Update children order
    if (updatedChildren.isNotEmpty) {
      await setChildren(parentViewId, updatedChildren);
    }
  }
  
  /// Reconcile non-keyed children (simpler version)
  Future<void> _reconcileNonKeyedChildren(String parentViewId,
      List<VDomNode> oldChildren, List<VDomNode> newChildren) async {
    final updatedChildren = <String>[];
    final commonLength = math.min(oldChildren.length, newChildren.length);

    // Update common children
    for (var i = 0; i < commonLength; i++) {
      final oldChild = oldChildren[i];
      final newChild = newChildren[i];

      if (oldChild.nativeViewId != null) {
        // Update existing child
        await _reconcile(oldChild, newChild);
        newChild.nativeViewId = oldChild.nativeViewId;
        updatedChildren.add(oldChild.nativeViewId!);
      } else {
        // Create new view for child that doesn't have one
        final childId = await renderToNative(newChild, parentId: parentViewId, index: i);
        if (childId != null && childId.isNotEmpty) {
          updatedChildren.add(childId);
          newChild.nativeViewId = childId;
        }
      }
    }

    // Handle length differences
    if (oldChildren.length > newChildren.length) {
      // Remove extra old children
      for (var i = commonLength; i < oldChildren.length; i++) {
        if (oldChildren[i].nativeViewId != null) {
          await deleteView(oldChildren[i].nativeViewId!);
        }
      }
    } else if (newChildren.length > oldChildren.length) {
      // Add new children
      for (var i = commonLength; i < newChildren.length; i++) {
        final childId = await renderToNative(
          newChildren[i], parentId: parentViewId, index: i);
        if (childId != null && childId.isNotEmpty) {
          updatedChildren.add(childId);
        }
      }
    }

    // Update children order
    if (updatedChildren.isNotEmpty) {
      await setChildren(parentViewId, updatedChildren);
    }
  }

  // Cache for parent view IDs to avoid repeated tree traversal
  final Map<VDomNode, String> _parentViewIdCache = {};
  
  /// Find parent view ID for a component with caching
  String? _findParentViewId(VDomNode node) {
    // Check cache first
    if (_parentViewIdCache.containsKey(node)) {
      return _parentViewIdCache[node];
    }
    
    // Traverse parent chain
    VDomNode? current = node.parent;
    while (current != null) {
      if (current.nativeViewId != null) {
        // Cache the result for future lookups
        _parentViewIdCache[node] = current.nativeViewId!;
        return current.nativeViewId;
      }
      current = current.parent;
    }
    
    // Cache and return default
    _parentViewIdCache[node] = "root";
    return "root"; // Fallback to root if no parent found
  }
  

  /// Call lifecycle methods for components
  void _callLifecycleMethodsIfNeeded(VDomNode node) {
    // Find component owning this node by traversing up the tree
    VDomNode? current = node;
    VDomNode? componentNode;

    while (current != null) {
      if (current is StatefulComponent || current is StatelessComponent) {
        componentNode = current;
        break;
      }
      current = current.parent;
    }

    if (componentNode != null) {
      final String instanceId = componentNode is StatefulComponent 
          ? (componentNode).instanceId 
          : (componentNode as StatelessComponent).instanceId;
          
      final instance = _componentInstances[instanceId];

      if (instance != null && !instance.isMounted) {
        componentNode.componentDidMount();
        instance.isMounted = true;
      }
    }
  }

  /// Find the nearest error boundary for a node
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

  /// Update a view's properties in the native UI
  /// 
  /// This is a critical method for state updates as it sends property changes 
  /// to the native UI layer. It's called by the reconciler when component state changes 
  /// and is the main way that UI updates are reflected in the rendered interface.
  ///
  /// @param viewId The ID of the native view to update
  /// @param props Map of properties to update with their new values
  /// @return Whether the update was successful
  Future<bool> updateView(String viewId, Map<String, dynamic> props) async {
    return await _nativeBridge.updateView(viewId, props);
  }

  /// Delete a view
  Future<bool> deleteView(String viewId) async {
    try {
      final result = await _nativeBridge.deleteView(viewId);
      if (result) {
        _nodesByViewId.remove(viewId);
      }
      return result;
    } catch (e) {
      developer.log('Error deleting view $viewId: $e', name: 'VDom');
      return false;
    }
  }

  /// Set the children of a view
  Future<bool> setChildren(String viewId, List<String> childrenIds) async {
    return await _nativeBridge.setChildren(viewId, childrenIds);
  }

  /// Add a node to the node tree
  void addNodeToTree(String viewId, VDomNode node) {
    _nodesByViewId[viewId] = node;
    node.nativeViewId = viewId;
  }

  /// Remove a node from the node tree
  void removeNodeFromTree(String viewId) {
    final node = _nodesByViewId[viewId];
    if (node != null) {
      node.nativeViewId = null;
      _nodesByViewId.remove(viewId);
    }
  }

  /// Attach a child view to a parent view at specific index
  Future<bool> attachView(String childId, String parentId, int index) async {
    return await _nativeBridge.attachView(childId, parentId, index);
  }

  /// Detach a view from its parent (without deleting it)
  Future<bool> detachView(String viewId) async {
    try {
      // Use the native bridge to detach the view
      final result = await _nativeBridge.detachView(viewId);
      return result;
    } catch (e) {
      developer.log('❌ Error detaching view $viewId: $e', name: 'VDom');
      return false;
    }
  }

  /// Get performance data
  Map<String, dynamic> getPerformanceData() {
    return _performanceMonitor.getMetricsReport();
  }

  /// Reset performance metrics
  void resetPerformanceMetrics() {
    _performanceMonitor.reset();
  }

  /// Find a node by ID
  VDomNode? findNodeById(String id) {
    // Check direct mapping
    return _nodesByViewId[id];
  }
  
  /// Helper method to move a view in its parent
  Future<void> _moveViewInParent(String childId, String parentId, int index) async {
    // Detach and reattach the view at the correct index
    await detachView(childId);
    await attachView(childId, parentId, index);
  }
}