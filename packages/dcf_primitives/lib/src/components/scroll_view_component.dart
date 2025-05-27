import 'package:dcflight/dcflight.dart';

/// A scroll view component implementation using StatelessComponent
class DCFScrollView extends StatelessComponent {
  /// Child nodes
  final List<DCFComponentNode> children;
  
  /// Whether to scroll horizontally
  final bool horizontal;
  
  /// The layout properties
  final LayoutProps layout;
  
  /// The style properties
  final StyleSheet style;
  
  /// Whether to show scrollbar
  final bool showsScrollIndicator;
  
  /// Content container style
  final StyleSheet contentContainerStyle;
  
  /// Event handlers
  final Map<String, dynamic>? events;
  
  /// Scroll event handler
  final Function? onScroll;
  
  /// Create a scroll view component
  DCFScrollView({
    required this.children,
    this.horizontal = false,
    this.layout = const LayoutProps(),
    this.style = const StyleSheet(),
    this.showsScrollIndicator = true,
    this.contentContainerStyle = const StyleSheet(),
    this.onScroll,
    this.events,
    super.key,
  });
  
    @override
  DCFComponentNode render() {
    // Create an events map for callbacks
    Map<String, dynamic> eventMap = events ?? {};
    
    if (onScroll != null) {
      eventMap['onScroll'] = onScroll;
    }
    
    return DCFElement(
      type: 'ScrollView',
      props: {
        'horizontal': horizontal,
        'showsScrollIndicator': showsScrollIndicator,
        'contentContainerStyle': contentContainerStyle.toMap(),
        ...layout.toMap(),
        ...style.toMap(),
        ...eventMap,
      },
      children: children,
    );
  }
}
