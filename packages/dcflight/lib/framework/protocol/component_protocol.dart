
import '../renderer/vdom/vdom_node.dart';
import '../renderer/vdom/vdom_element.dart';

/// This will be used to register component factories with the framework
typedef ComponentFactory = VDomElement Function(Map<String, dynamic> props, List<VDomNode> children);
