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
  
  /// Scroll begin drag event handler
  final Function? onScrollBeginDrag;
  
  /// Scroll end drag event handler
  final Function? onScrollEndDrag;
  
  /// Scroll end event handler
  final Function? onScrollEnd;
  
  /// Scroll indicator color
  final Color? scrollIndicatorColor;
  
  /// Scroll indicator size/thickness
  final double? scrollIndicatorSize;
  
  /// Create a scroll view component
  DCFScrollView({
    required this.children,
    this.horizontal = false,
    this.layout = const LayoutProps(padding: 8),
    this.style = const StyleSheet(),
    this.showsScrollIndicator = true,
    this.contentContainerStyle = const StyleSheet(),
    this.onScroll,
    this.onScrollBeginDrag,
    this.onScrollEndDrag,
    this.onScrollEnd,
    this.scrollIndicatorColor,
    this.scrollIndicatorSize,
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
    
    if (onScrollBeginDrag != null) {
      eventMap['onScrollBeginDrag'] = onScrollBeginDrag;
    }
    
    if (onScrollEndDrag != null) {
      eventMap['onScrollEndDrag'] = onScrollEndDrag;
    }
    
    if (onScrollEnd != null) {
      eventMap['onScrollEnd'] = onScrollEnd;
    }
    
    return DCFElement(
      type: 'ScrollView',
      props: {
        'horizontal': horizontal,
        'showsScrollIndicator': showsScrollIndicator,
        'scrollIndicatorColor': scrollIndicatorColor?.value,
        'scrollIndicatorSize': scrollIndicatorSize,
        'contentContainerStyle': contentContainerStyle.toMap(),
        ...layout.toMap(),
        ...style.toMap(),
        ...eventMap,
      },
      children: children,
    );
  }
}
