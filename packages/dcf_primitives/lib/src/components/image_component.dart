import 'package:dcflight/dcflight.dart';

/// Image properties
class ImageProps {
  /// The image source URI (can be a network URL or local resource)
  final String source;
  
  /// Resize mode for the image
  final String? resizeMode;
  
  /// Whether to fade in the image when loaded
  final bool? fadeDuration;
  
  /// Placeholder image to show while loading
  final String? placeholder;
  
  /// Create image props
  const ImageProps({
    required this.source,
    this.resizeMode,
    this.fadeDuration,
    this.placeholder,
  });
  
  /// Convert to props map
  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'isRelativePath': false,
      if (resizeMode != null) 'resizeMode': resizeMode,
      if (fadeDuration != null) 'fadeDuration': fadeDuration,
      if (placeholder != null) 'placeholder': placeholder,
    };
  }
}

/// An image component implementation using StatelessComponent
class DCFImage extends StatelessComponent {
  /// The image properties
  final ImageProps imageProps;
  
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
  
  /// Create an image component
  DCFImage({
    required this.imageProps,
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
      type: 'Image',
      props: {
        ...imageProps.toMap(),
        ...layout.toMap(),
        ...style.toMap(),
        ...eventMap,
      },
      children: [],
    );
  }
}

