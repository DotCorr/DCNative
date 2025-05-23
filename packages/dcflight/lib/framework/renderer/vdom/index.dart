/// This file serves as a central export point for the VDOM system,
/// allowing easy swapping between implementations.

// Re-export the new VDOM API
export 'vdom_api.dart';

// Re-export the component classes from the new implementation
export 'component/component_new.dart';

// Re-export hooks
export 'component/state_hook_new.dart';

// Re-export fragment
export 'component/fragment.dart';

// Re-export element and node classes
export 'vdom_node.dart';
export 'vdom_element.dart';

// Re-export error boundary
export 'component/error_boundary.dart';

// Re-export store
export 'component/store.dart';
