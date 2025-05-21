import 'dart:async';
import 'dart:developer' as developer;

import 'package:dcflight/framework/renderer/interface/interface.dart' show NativeBridgeFactory, PlatformInterface;
import 'package:dcflight/framework/renderer/vdom/component/component.dart';
import 'package:dcflight/framework/renderer/vdom/component/error_boundary.dart';
export 'package:dcflight/framework/renderer/vdom/component/store.dart';
import 'package:dcflight/framework/renderer/vdom/vdom_element.dart';
import 'vdom_node.dart';
import 'reconciler.dart';
import 'component/fragment.dart';

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

  /// Reconciliation engine
  late final Reconciler _reconciler;

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

      // Create reconciler
      _reconciler = Reconciler(this);

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
  void _scheduleComponentUpdate(StatefulComponent component) {
    print('Scheduling update for component: ${component.instanceId} from the vdom');
    _pendingUpdates.add(component.instanceId);

    if (_isUpdateScheduled) return;
    _isUpdateScheduled = true;

    // Schedule updates to run after current execution using microtask for animations
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
      await _reconciler.reconcile(oldRenderedNode, newRenderedNode);
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

  /// Update a view's properties
  Future<bool> updateView(String viewId, Map<String, dynamic> props) async {
    print("UPDATE Triggered, the reconciuler is the only one that call this so the reconcielr called updateView. hopefuy the native side calls it");
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
  
  // Removed purgeDetachedNodes method
}
