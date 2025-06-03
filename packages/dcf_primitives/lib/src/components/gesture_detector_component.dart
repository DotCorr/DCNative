import 'package:dcflight/dcflight.dart';

/// A gesture detector component implementation using StatelessComponent
class DCFGestureDetector extends StatelessComponent {
  /// Child nodes
  final List<DCFComponentNode> children;
  
  /// The layout properties
  final LayoutProps layout;
  
  /// The style properties
  final StyleSheet style;
  
  /// Event handlers
  final Map<String, dynamic>? events;
  
  /// Tap event handler
  final Function? onTap;
  
  /// Long press event handler
  final Function? onLongPress;
  
  /// Swipe left event handler
  final Function? onSwipeLeft;
  
  /// Swipe right event handler
  final Function? onSwipeRight;
  
  /// Swipe up event handler
  final Function? onSwipeUp;
  
  /// Swipe down event handler
  final Function? onSwipeDown;
  
  /// Pan start event handler
  final Function? onPanStart;
  
  /// Pan update event handler
  final Function? onPanUpdate;
  
  /// Pan end event handler
  final Function? onPanEnd;
  
  /// Create a gesture detector component
  DCFGestureDetector({
    required this.children,
    this.layout = const LayoutProps(padding: 8, height: 50,width: 200),
    this.style = const StyleSheet(),
    this.onTap,
    this.onLongPress,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.events,
    super.key,
  });
  
  @override
  DCFComponentNode render() {
    // Create an events map for callbacks
    Map<String, dynamic> eventMap = events ?? {};
    
    if (onTap != null) {
      eventMap['onTap'] = onTap;
    }
    
    if (onLongPress != null) {
      eventMap['onLongPress'] = onLongPress;
    }
    
    if (onSwipeLeft != null) {
      eventMap['onSwipeLeft'] = onSwipeLeft;
    }
    
    if (onSwipeRight != null) {
      eventMap['onSwipeRight'] = onSwipeRight;
    }
    
    if (onSwipeUp != null) {
      eventMap['onSwipeUp'] = onSwipeUp;
    }
    
    if (onSwipeDown != null) {
      eventMap['onSwipeDown'] = onSwipeDown;
    }
    
    if (onPanStart != null) {
      eventMap['onPanStart'] = onPanStart;
    }
    
    if (onPanUpdate != null) {
      eventMap['onPanUpdate'] = onPanUpdate;
    }
    
    if (onPanEnd != null) {
      eventMap['onPanEnd'] = onPanEnd;
    }
    
    return DCFElement(
      type: 'GestureDetector',
      props: {
        ...layout.toMap(),
        ...style.toMap(),
        ...eventMap,
      },
      children: children,
    );
  }
}
