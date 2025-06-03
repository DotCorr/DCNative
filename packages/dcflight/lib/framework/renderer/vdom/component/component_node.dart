/// Base class for all Virtual DOM nodes
abstract class DCFComponentNode{
  /// Unique identifier for this node
  final String? key;

  /// Parent node in the virtual tree
  DCFComponentNode? parent;

  /// Native view ID once rendered
  String? nativeViewId;
  
  /// The native view ID of the rendered content
  String? contentViewId;
  
  /// The rendered node from the component (for component nodes)
  DCFComponentNode? _renderedNode;

  DCFComponentNode({this.key});

  /// Clone this node
  DCFComponentNode clone();

  /// Whether this node is equal to another
  bool equals(DCFComponentNode other);

  void mount(DCFComponentNode? parent);
  void unmount();
  
  /// Called when the node is mounted (lifecycle method)
  void componentDidMount() {
    // Base implementation does nothing
  }

  /// Called when the node will unmount (lifecycle method)
  void componentWillUnmount() {
    // Base implementation does nothing
  }
  
  /// Get the rendered node (for component-like nodes)
  DCFComponentNode? get renderedNode => _renderedNode;
  
  /// Set the rendered node (for component-like nodes)
  set renderedNode(DCFComponentNode? node) {
    _renderedNode = node;
    if (_renderedNode != null) {
      _renderedNode!.parent = this;
    }
  }
  
  /// Get effective native view ID (may be from rendered content)
  String? get effectiveNativeViewId {
    // For component nodes, the native view ID is the ID of their rendered content
    return contentViewId ?? nativeViewId;
  }

  @override
  String toString() {
    return 'VDomNode(key: $key)';
  }
}

/// Represents absence of a node - useful for conditional rendering
class EmptyVDomNode extends DCFComponentNode {
  EmptyVDomNode() : super(key: null);

  @override
  DCFComponentNode clone() => EmptyVDomNode();

  @override
  bool equals(DCFComponentNode other) => other is EmptyVDomNode;

  @override
  String toString() => 'EmptyVDomNode()';

  @override
  void mount(DCFComponentNode? parent) {
    this.parent = parent;
    // Empty node has no additional mounting logic
  }

  @override
  void unmount() {
    // Empty node has no cleanup logic
  }
}


