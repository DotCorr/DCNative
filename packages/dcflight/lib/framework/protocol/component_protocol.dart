
import '../renderer/vdom/component/component_node.dart';
import '../renderer/vdom/component/dcf_element.dart';

/// This will be used to register component factories with the framework
typedef ComponentFactory = DCFElement Function(Map<String, dynamic> props, List<DCFComponentNode> children);
