// filepath: /Users/tahiruagbanwa/Desktop/Dotcorr/DCFlight/packages/dcflight/lib/framework/renderer/vdom/vdom_element.dart
import 'package:dcflight/dcflight.dart';


/// Represents an element in the Virtual DOM tree
class DCFElement extends DCFComponentNode {
  /// Type of the element (e.g., 'View', 'Text', 'Button')
  final String type;

  /// Properties of the element
  Map<String, dynamic> props;
  /// Child nodes
  final List<DCFComponentNode> children;

  DCFElement({
    required this.type,
    super.key,
    required this.props,
    this.children = const [],
  }) {
    // Set parent reference for children
    for (var child in children) {
      child.parent = this;
    }
  }

  @override
  DCFComponentNode clone() {
    return DCFElement(
      type: type,
      key: key,
      props: Map<String, dynamic>.from(props),
      children: children.map((child) => child.clone()).toList(),
    );
  }

  @override
  bool equals(DCFComponentNode other) {
    if (other is! DCFElement) return false;
    if (type != other.type) return false;
    if (key != other.key) return false;

    return true;
  }

  @override
  String toString() {
    return 'VDomElement(type: $type, key: $key, props: ${props.length}, children: ${children.length})';
  }

  /// Get all descendant nodes flattened into a list
  List<DCFComponentNode> get allDescendants {
    final result = <DCFComponentNode>[];
    for (final child in children) {
      result.add(child);
      if (child is DCFElement) {
        result.addAll(child.allDescendants);
      }
    }
    return result;
  }

  /// Get list of event types from props
  List<String> get eventTypes {
    final List<String> types = [];

    // Extract event types from props with direct event names (e.g., 'onPress')
    for (final key in props.keys) {
      if (props[key] is Function) {
        // First check for direct event format (e.g., 'onPress')
        if (key.startsWith('on') && key.length > 2) {
          // Use the event name directly without normalization (onPress -> onPress)
          types.add(key);
        }

        // Also check for canonical format that will be sent from native (onPress -> press)
        if (key.startsWith('on') && key.length > 2) {
          // Convert onEventName to eventName format
          final eventName =
              key.substring(2, 3).toLowerCase() + key.substring(3);
          if (!types.contains(eventName)) {
            types.add(eventName);
          }
        }
      }
    }

    return types;
  }

  @override
  void mount(DCFComponentNode? parent) {
    this.parent = parent;

    // Call mount on children
    for (final child in children) {
      child.mount(this);
    }
  }

  @override
  void unmount() {
    // Unmount all children first
    for (final child in children) {
      child.unmount();
    }
  }
}
