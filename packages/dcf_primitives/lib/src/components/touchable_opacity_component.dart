import 'package:dcflight/dcflight.dart';

/// A touchable opacity component implementation using StatelessComponent
class DCFTouchableOpacity extends StatelessComponent {
  /// Child nodes
  final List<VDomNode> children;
  
  /// Opacity when pressed
  final double activeOpacity;
  
  /// The layout properties
  final LayoutProps layout;
  
  /// The style properties
  final StyleSheet style;
  
  /// Press event handler
  final Function? onPress;
  
  /// Press in event handler
  final Function? onPressIn;
  
  /// Press out event handler
  final Function? onPressOut;
  
  /// Long press event handler
  final Function? onLongPress;
  
  /// Long press delay in milliseconds
  final int longPressDelay;
  
  /// Whether the component is disabled
  final bool disabled;
  
  /// Event handlers
  final Map<String, dynamic>? events;
  
  /// Create a touchable opacity component
  DCFTouchableOpacity({
    required this.children,
    this.activeOpacity = 0.2,
    this.layout = const LayoutProps(),
    this.style = const StyleSheet(),
    this.onPress,
    this.onPressIn,
    this.onPressOut,
    this.onLongPress,
    this.longPressDelay = 500,
    this.disabled = false,
    this.events,
    super.key,
  });
  
  @override
  VDomNode render() {
    // Create an events map for callbacks
    Map<String, dynamic> eventMap = events ?? {};
    
    if (onPress != null) {
      eventMap['onPress'] = onPress;
    }
    
    if (onPressIn != null) {
      eventMap['onPressIn'] = onPressIn;
    }
    
    if (onPressOut != null) {
      eventMap['onPressOut'] = onPressOut;
    }
    
    if (onLongPress != null) {
      eventMap['onLongPress'] = onLongPress;
    }
    
    return VDomElement(
      type: 'TouchableOpacity',
      props: {
        'activeOpacity': activeOpacity,
        'disabled': disabled,
        'longPressDelay': longPressDelay,
        ...layout.toMap(),
        ...style.toMap(),
        ...eventMap,
      },
      children: children,
    );
  }
}
