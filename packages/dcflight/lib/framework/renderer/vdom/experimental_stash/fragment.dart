// import 'component_node.dart';

// /// Fragment component that renders multiple children without a container
// class Fragment extends DCFComponentNode {
//   /// Child nodes
//   final List<DCFComponentNode> children;

//   Fragment({
//     required this.children,
//     super.key,
//   });

//   @override
//   DCFComponentNode clone() {
//     return Fragment(
//       children: children.map((child) => child.clone()).toList(),
//       key: key,
//     );
//   }

//   @override
//   bool equals(DCFComponentNode other) {
//     return other is Fragment && key == other.key;
//   }

//   @override
//   void mount(DCFComponentNode? parent) {
//     this.parent = parent;

//     // Mount all children
//     for (final child in children) {
//       child.mount(this);
//     }
//   }

//   @override
//   void unmount() {
//     // Unmount all children
//     for (final child in children) {
//       child.unmount();
//     }
//   }
// }
