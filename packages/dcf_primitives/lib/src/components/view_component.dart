import 'package:dcflight/dcflight.dart';

/// A basic view component implementation using StatelessComponent
class DCFView extends StatelessComponent {
  /// The layout properties
  final LayoutProps layout;

  /// The style properties
  final StyleSheet style;

  /// Child nodes
  final List<DCFComponentNode> children;

  /// Event handlers
  final Map<String, dynamic>? events;

  /// Create a view component
  DCFView({
    this.layout = const LayoutProps(padding: 8),
    this.style = const StyleSheet(),
    this.children = const [],
    this.events,
    super.key,
  });

  @override
  DCFComponentNode render() {
    return DCFElement(
      type: 'View',
      props: {
        ...layout.toMap(),
        ...style.toMap(),
        ...(events ?? {}),
      },
      children: children,
    );
  }
}
