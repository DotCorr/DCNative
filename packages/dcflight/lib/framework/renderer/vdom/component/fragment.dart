import '../vdom_node.dart';

/// Fragment component that renders multiple children without a container
class Fragment extends VDomNode {
  /// Child nodes
  final List<VDomNode> children;

  Fragment({
    required this.children,
    super.key,
  });

  @override
  VDomNode clone() {
    return Fragment(
      children: children.map((child) => child.clone()).toList(),
      key: key,
    );
  }

  @override
  bool equals(VDomNode other) {
    return other is Fragment && key == other.key;
  }

  @override
  void mount(VDomNode? parent) {
    this.parent = parent;

    // Mount all children
    for (final child in children) {
      child.mount(this);
    }
  }

  @override
  void unmount() {
    // Unmount all children
    for (final child in children) {
      child.unmount();
    }
  }
}
