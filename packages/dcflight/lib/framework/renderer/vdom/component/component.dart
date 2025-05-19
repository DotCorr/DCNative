import 'dart:math';
import 'package:dcflight/framework/renderer/vdom/vdom_node.dart';
import 'state_hook.dart';
import 'store.dart';

/// Stateful component with hooks
abstract class StatefulComponent extends VDomNode {
  /// Unique ID for this component instance
  final String instanceId;

  /// Fully qualified type name for component
  final String typeName;

  /// The rendered node from the component
  VDomNode? _renderedNode;

  /// Whether the component is mounted
  bool _isMounted = false;

  /// Current hook index during rendering
  int _hookIndex = 0;

  /// List of hooks
  final List<Hook> _hooks = [];

  /// Function to schedule updates when state changes
  Function() scheduleUpdate = () {};

  /// Create a stateful component
  StatefulComponent({super.key})
      : instanceId = DateTime.now().millisecondsSinceEpoch.toString() +
            Random().nextDouble().toString(),
        typeName = StackTrace.current.toString().split('\n')[1].split(' ')[0];

  /// Render the component
  VDomNode render();
  
  /// Get the rendered node (lazily render if necessary)
  @override
  VDomNode get renderedNode {
    _renderedNode ??= render();
    return _renderedNode!;
  }
  
  /// Set the rendered node
  @override
  set renderedNode(VDomNode? node) {
    _renderedNode = node;
    if (_renderedNode != null) {
      _renderedNode!.parent = this;
    }
  }

  /// Get whether the component is mounted
  bool get isMounted => _isMounted;

  /// Called when the component is mounted
  @override
  void componentDidMount() {
    _isMounted = true;
  }

  /// Called when the component will unmount
  @override
  void componentWillUnmount() {
    // Clean up hooks
    for (final hook in _hooks) {
      hook.dispose();
    }
    _hooks.clear();
    _isMounted = false;
  }

  /// Called after the component updates
  void componentDidUpdate(Map<String, dynamic> prevProps) {}

  /// Reset hook state for next render
  void _resetHookState() {
    _hookIndex = 0;
  }

  /// Create a state hook
  StateHook<T> useState<T>(T initialValue, [String? name]) {
    if (_hookIndex >= _hooks.length) {
      // Create new hook
      final hook = StateHook<T>(initialValue, name, () {
        scheduleUpdate();
      });
      _hooks.add(hook);
    }
    
    // Get the hook (either existing or newly created)
    final hook = _hooks[_hookIndex] as StateHook<T>;
    _hookIndex++;
    
    return hook;
  }

  /// Create an effect hook
  void useEffect(Function()? Function() effect,
      {List<dynamic> dependencies = const []}) {
    if (_hookIndex >= _hooks.length) {
      // Create new hook
      final hook = EffectHook(effect, dependencies);
      _hooks.add(hook);
    }
    
    // Just increment the hook index
    _hookIndex++;
  }

  /// Create a ref hook
  RefObject<T> useRef<T>([T? initialValue]) {
    if (_hookIndex >= _hooks.length) {
      // Create new hook
      final hook = RefHook<T>(initialValue);
      _hooks.add(hook);
    }
    
    // Get the hook (either existing or newly created)
    final hook = _hooks[_hookIndex] as RefHook<T>;
    _hookIndex++;
    
    return hook.ref;
  }

  /// Create a store hook for global state
  StoreHook<T> useStore<T>(Store<T> store) {
    if (_hookIndex >= _hooks.length) {
      // Create new hook
      final hook = StoreHook<T>(store, () {
        scheduleUpdate();
      });
      _hooks.add(hook);
    }
    
    // Get the hook (either existing or newly created)
    final hook = _hooks[_hookIndex] as StoreHook<T>;
    _hookIndex++;
    
    return hook;
  }

  /// Prepare component for rendering - used by VDOM
  void prepareForRender() {
    _resetHookState();
  }

  /// Run effects after render - called by VDOM
  void runEffectsAfterRender() {
    for (var i = 0; i < _hooks.length; i++) {
      final hook = _hooks[i];
      if (hook is EffectHook) {
        hook.runEffect();
      }
    }
  }
  
  /// Implement VDomNode methods
  
  @override
  VDomNode clone() {
    // Components can't be cloned easily due to state, hooks, etc.
    throw UnsupportedError("Stateful components cannot be cloned directly.");
  }
  
  @override
  bool equals(VDomNode other) {
    if (other is! StatefulComponent) return false;
    return runtimeType == other.runtimeType && key == other.key;
  }
  
  @override
  void mount(VDomNode? parent) {
    this.parent = parent;
    
    // Ensure the component has rendered
    final node = renderedNode;
    
    // Mount the rendered content
    node.mount(this);
    
    // Component lifecycle method
    componentDidMount();
  }
  
  @override
  void unmount() {
    // Unmount the rendered content if any
    if (_renderedNode != null) {
      _renderedNode!.unmount();
    }
    
    // Component lifecycle method
    componentWillUnmount();
  }

  @override
  String toString() {
    return '$typeName($instanceId)';
  }
}

/// Stateless component without hooks
abstract class StatelessComponent extends VDomNode {
  /// Unique ID for this component instance
  final String instanceId;

  /// Fully qualified type name for component
  final String typeName;

  /// The rendered node from the component
  VDomNode? _renderedNode;

  /// Whether the component is mounted
  bool _isMounted = false;

  /// Create a stateless component
  StatelessComponent({super.key})
      : instanceId = DateTime.now().millisecondsSinceEpoch.toString() +
            Random().nextDouble().toString(),
        typeName = StackTrace.current.toString().split('\n')[1].split(' ')[0];

  /// Render the component
  VDomNode render();
  
  /// Get the rendered node (lazily render if necessary)
  VDomNode get renderedNode {
    _renderedNode ??= render();
    return _renderedNode!;
  }
  
  /// Set the rendered node
  @override
  set renderedNode(VDomNode? node) {
    _renderedNode = node;
    if (_renderedNode != null) {
      _renderedNode!.parent = this;
    }
  }

  /// Get whether the component is mounted
  bool get isMounted => _isMounted;

  /// Called when the component is mounted
  void componentDidMount() {
    _isMounted = true;
  }

  /// Called when the component will unmount
  void componentWillUnmount() {
    // Base implementation does nothing
  }
  
  /// Implement VDomNode methods
  
  @override
  VDomNode clone() {
    // Components can't be cloned easily due to state, hooks, etc.
    throw UnsupportedError("Stateless components cannot be cloned directly.");
  }
  
  @override
  bool equals(VDomNode other) {
    if (other is! StatelessComponent) return false;
    return runtimeType == other.runtimeType && key == other.key;
  }
  
  @override
  void mount(VDomNode? parent) {
    this.parent = parent;
    
    // Ensure the component has rendered
    final node = renderedNode;
    
    // Mount the rendered content
    node.mount(this);
    
    // Component lifecycle method
    componentDidMount();
  }
  
  @override
  void unmount() {
    // Unmount the rendered content if any
    if (_renderedNode != null) {
      _renderedNode!.unmount();
    }
    
    // Component lifecycle method
    componentWillUnmount();
  }

  @override
  String toString() {
    return '$typeName($instanceId)';
  }
}
