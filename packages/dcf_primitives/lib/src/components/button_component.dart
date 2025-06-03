import 'package:dcflight/dcflight.dart';

/// Button properties
class ButtonProps {
  /// The title text of the button
  final String title;
  
  /// Title color of the button
  final Color? color;
  
  /// Button's background color
  final Color? backgroundColor;
  
  /// Disabled state
  final bool disabled;
  
  /// Create button props
  const ButtonProps({
    required this.title,
    this.color,
    this.backgroundColor,
    this.disabled = false,
  });
  
  /// Convert to props map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      if (color != null) 'color': color,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      'disabled': disabled,
    };
  }
}

/// A button component implementation using StatelessComponent
class DCFButton extends StatelessComponent {
  /// The button properties
  final ButtonProps buttonProps;
  
  /// The layout properties
  final LayoutProps layout;
  
  /// The style properties
  final StyleSheet style;
  
  /// Event handlers
  final Map<String, dynamic>? events;
  
  /// Press event handler
  final Function? onPress;
  
  /// Create a button component
  DCFButton({
    required this.buttonProps,
       this.layout = const LayoutProps(
    height: 50,width: 200
    ),
    this.style = const StyleSheet(),
    this.onPress,
    this.events,
    super.key,
  });
  
  @override
  DCFComponentNode render() {
    // Create an events map for the onPress handler
    Map<String, dynamic> eventMap = events ?? {};
    
    if (onPress != null) {
      eventMap['onPress'] = onPress;
    }
    
    return DCFElement(
      type: 'Button',
      props: {
        ...buttonProps.toMap(),
        ...layout.toMap(),
        ...style.toMap(),
        ...eventMap,
      },
      children: [],
    );
  }
}

