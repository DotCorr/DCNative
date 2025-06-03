import 'package:dcflight/dcflight.dart';
export 'package:dcf_primitives/src/components/dictionary/dcf_icons_dict.dart';

/// Icon properties
class IconProps {
  /// The name of the icon
  final String name;
  
  /// Size of the icon
  // final double size;
  
  /// Color of the icon
  final Color? color;
  
  /// Package where the icon is defined
  final String package;
  
  /// Create icon props
  const IconProps({
    required this.name,
    // this.size = 24.0,
    this.color,
    this.package = 'dcf_primitives',
  });
  
  /// Convert to props map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      // 'size': size,
      'package': package,
      'isRelativePath': false,
      if (color != null) 'color': color,
    };
  }
}

/// An icon component implementation using StatelessComponent
class DCFIcon extends StatelessComponent {
  /// The icon properties
  final IconProps iconProps;
  
  /// The layout properties
  final LayoutProps layout;
  
  /// The style properties
  final StyleSheet style;
  
  /// Event handlers
  final Map<String, dynamic>? events;
  
  /// Load event handler
  final Function? onLoad;
  
  /// Error event handler
  final Function? onError;
  
  /// Create an icon component
  DCFIcon({
    required this.iconProps,
       this.layout = const LayoutProps(
      flex: 1
    ),
    this.style = const StyleSheet(),
    this.onLoad,
    this.onError,
    this.events,
    super.key,
  });
  
  @override
  VDomNode render() {
    // Create an events map for callbacks
    Map<String, dynamic> eventMap = events ?? {};
    
    if (onLoad != null) {
      eventMap['onLoad'] = onLoad;
    }
    
    if (onError != null) {
      eventMap['onError'] = onError;
    }
    
    return VDomElement(
      type: 'DCFIcon',
      props: {
        ...iconProps.toMap(),
        ...layout.toMap(),
        ...style.toMap(),
        ...eventMap,
      },
      children: [],
    );
  }
}
