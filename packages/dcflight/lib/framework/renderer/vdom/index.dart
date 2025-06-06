/// This file serves as a central export point for the VDOM system,
/// allowing easy swapping between implementations.
library;

// Re-export the new VDOM API
export 'vdom_api.dart';

// Re-export the component classes from the new implementation
export 'component/component.dart';

// Re-export hooks
export 'component/state_hook.dart';

// Re-export fragment
export 'experimental_stash/fragment.dart';

// Re-export element and node classes
export 'component/component_node.dart';
export 'component/dcf_element.dart';

// Re-export error boundary
export 'component/error_boundary.dart';

// Re-export store
export 'component/store.dart';
