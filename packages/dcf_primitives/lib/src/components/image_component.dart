import 'package:dcflight/dcflight.dart';
import '../types/component_types.dart' as types;

/// Image properties
class ImageProps {
  /// The image source URI (can be a network URL or local resource)
  final String source;
  
  /// Resize mode for the image - type-safe enum
  final types.ImageResizeMode? resizeMode;
  
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
      if (resizeMode != null) 'resizeMode': resizeMode!.name,
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
     height: 50,width: 200
    ),
    this.style = const StyleSheet(),
    this.onLoad,
    this.onError,
    this.events,
    super.key,
  });
  
  @override
  DCFComponentNode render() {
    // Create an events map for callbacks
    Map<String, dynamic> eventMap = events ?? {};
    
    if (onLoad != null) {
      eventMap['onLoad'] = onLoad;
    }
    
    if (onError != null) {
      eventMap['onError'] = onError;
    }
    
    return DCFElement(
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

