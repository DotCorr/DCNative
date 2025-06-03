import 'package:dcflight/dcflight.dart';

/// An animated view component implementation using StatelessComponent
class DCFAnimatedView extends StatelessComponent {
  /// Child nodes
  final List<VDomNode> children;
  
  /// The layout properties
  final LayoutProps layout;
  
  /// The style properties
  final StyleSheet style;
  
  /// The animation configuration
  final Map<String, dynamic> animation;
  
  /// Event handlers
  final Map<String, dynamic>? events;
  
  /// Animation end event handler
  final Function? onAnimationEnd;
  
  /// Create an animated view component
  DCFAnimatedView({
    required this.children,
    required this.animation,
    this.layout = const LayoutProps(),
    this.style = const StyleSheet(),
    this.onAnimationEnd,
    this.events,
    super.key,
  });
  
  @override
  VDomNode render() {
    // Create an events map for callbacks
    Map<String, dynamic> eventMap = events ?? {};
    
    if (onAnimationEnd != null) {
      eventMap['onAnimationEnd'] = onAnimationEnd;
    }
    
    return VDomElement(
      type: 'AnimatedView',
      props: {
        'animation': animation,
        ...layout.toMap(),
        ...style.toMap(),
        ...eventMap,
      },
      children: children,
    );
  }
}
