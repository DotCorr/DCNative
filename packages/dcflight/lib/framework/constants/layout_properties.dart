import 'package:dcflight/framework/constants/yoga_enums.dart';

/// Layout properties for components
class LayoutProps {
  // Width and height
  final dynamic width;
  final dynamic height;
  final dynamic minWidth;
  final dynamic maxWidth;
  final dynamic minHeight;
  final dynamic maxHeight;

  // Margin
  final dynamic margin;
  final dynamic marginTop;
  final dynamic marginRight;
  final dynamic marginBottom;
  final dynamic marginLeft;
  final dynamic marginHorizontal;
  final dynamic marginVertical;

  // Padding
  final dynamic padding;
  final dynamic paddingTop;
  final dynamic paddingRight;
  final dynamic paddingBottom;
  final dynamic paddingLeft;
  final dynamic paddingHorizontal;
  final dynamic paddingVertical;

  // Position
  final dynamic left;
  final dynamic top;
  final dynamic right;
  final dynamic bottom;
  final YogaPositionType? position;

  // Flex properties
  final YogaFlexDirection? flexDirection;
  final YogaJustifyContent? justifyContent;
  final YogaAlign? alignItems;
  final YogaAlign? alignSelf;
  final YogaAlign? alignContent;
  final YogaWrap? flexWrap;
  final double? flex;
  final double? flexGrow;
  final double? flexShrink;
  final dynamic flexBasis;

  // Display and overflow
  final YogaDisplay? display;
  final YogaOverflow? overflow;

  // Direction
  final YogaDirection? direction;

@Deprecated("Use borderWidth from style instead")
  // Border (although visual, it affects layout)
  final dynamic borderWidth;

  /// Create layout props with the specified values
  const LayoutProps({
    this.width = '100%', // Default to 100% width for proper nesting
    this.height = "50%", // Default to 50% height for visibility
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.margin,
    this.marginTop,
    this.marginRight,
    this.marginBottom,
    this.marginLeft,
    this.marginHorizontal,
    this.marginVertical,
    this.padding = 8,
    this.paddingTop,
    this.paddingRight,
    this.paddingBottom,
    this.paddingLeft,
    this.paddingHorizontal,
    this.paddingVertical,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.position,
    this.flexDirection = YogaFlexDirection.column,
    this.justifyContent,
    this.alignItems = YogaAlign.stretch,
    this.alignSelf,
    this.alignContent = YogaAlign.stretch,
    this.flexWrap = YogaWrap.wrap,
    this.flex,
    this.flexGrow,
    this.flexShrink,
    this.flexBasis,
    this.display = YogaDisplay.flex,
    this.overflow = YogaOverflow.visible,
    this.direction,
    this.borderWidth,
  });

  /// Check if there are any layout properties set
  bool get isNotEmpty {
    return width != null ||
        height != null ||
        minWidth != null ||
        maxWidth != null ||
        minHeight != null ||
        maxHeight != null ||
        margin != null ||
        marginTop != null ||
        marginRight != null ||
        marginBottom != null ||
        marginLeft != null ||
        marginHorizontal != null ||
        marginVertical != null ||
        padding != null ||
        paddingTop != null ||
        paddingRight != null ||
        paddingBottom != null ||
        paddingLeft != null ||
        paddingHorizontal != null ||
        paddingVertical != null ||
        left != null ||
        top != null ||
        right != null ||
        bottom != null ||
        position != null ||
        flexDirection != null ||
        justifyContent != null ||
        alignItems != null ||
        alignSelf != null ||
        alignContent != null ||
        flexWrap != null ||
        flex != null ||
        flexGrow != null ||
        flexShrink != null ||
        flexBasis != null ||
        display != null ||
        overflow != null ||
        direction != null ||
        borderWidth != null;
  }

  /// Convert layout props to a map for serialization
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    // Always include default width and height if not specified
    map['width'] = width;
    map['height'] = height;

    // Add dimension properties
    if (minWidth != null) map['minWidth'] = minWidth;
    if (maxWidth != null) map['maxWidth'] = maxWidth;
    if (minHeight != null) map['minHeight'] = minHeight;
    if (maxHeight != null) map['maxHeight'] = maxHeight;

    // Add margin properties
    if (margin != null) map['margin'] = margin;
    if (marginTop != null) map['marginTop'] = marginTop;
    if (marginRight != null) map['marginRight'] = marginRight;
    if (marginBottom != null) map['marginBottom'] = marginBottom;
    if (marginLeft != null) map['marginLeft'] = marginLeft;
    if (marginHorizontal != null) {
      map['marginLeft'] = marginHorizontal;
      map['marginRight'] = marginHorizontal;
    }
    if (marginVertical != null) {
      map['marginTop'] = marginVertical;
      map['marginBottom'] = marginVertical;
    }

    // Add padding properties
    if (padding != null) map['padding'] = padding;
    if (paddingTop != null) map['paddingTop'] = paddingTop;
    if (paddingRight != null) map['paddingRight'] = paddingRight;
    if (paddingBottom != null) map['paddingBottom'] = paddingBottom;
    if (paddingLeft != null) map['paddingLeft'] = paddingLeft;
    if (paddingHorizontal != null) {
      map['paddingLeft'] = paddingHorizontal;
      map['paddingRight'] = paddingHorizontal;
    }
    if (paddingVertical != null) {
      map['paddingTop'] = paddingVertical;
      map['paddingBottom'] = paddingVertical;
    }

    // Add position properties
    if (left != null) map['left'] = left;
    if (top != null) map['top'] = top;
    if (right != null) map['right'] = right;
    if (bottom != null) map['bottom'] = bottom;
    if (position != null) map['position'] = position.toString().split('.').last;

    // Add flex properties
    if (flexDirection != null) {
      map['flexDirection'] = flexDirection.toString().split('.').last;
    }
    if (justifyContent != null) {
      map['justifyContent'] = justifyContent.toString().split('.').last;
    }
    if (alignItems != null) {
      map['alignItems'] = alignItems.toString().split('.').last;
    }
    if (alignSelf != null) {
      map['alignSelf'] = alignSelf.toString().split('.').last;
    }
    if (alignContent != null) {
      map['alignContent'] = alignContent.toString().split('.').last;
    }
    if (flexWrap != null) map['flexWrap'] = flexWrap.toString().split('.').last;
    if (flex != null) map['flex'] = flex;
    if (flexGrow != null) map['flexGrow'] = flexGrow;
    if (flexShrink != null) map['flexShrink'] = flexShrink;
    if (flexBasis != null) map['flexBasis'] = flexBasis;

    // Add display and overflow properties
    if (display != null) map['display'] = display.toString().split('.').last;
    if (overflow != null) map['overflow'] = overflow.toString().split('.').last;

    // Add direction property
    if (direction != null) {
      map['direction'] = direction.toString().split('.').last;
    }

    // Add border width (affects layout)
    if (borderWidth != null) map['borderWidth'] = borderWidth;

    return map;
  }

  /// Create a new LayoutProps object by merging this one with another
  LayoutProps merge(LayoutProps other) {
    return LayoutProps(
      width: other.width ?? width,
      height: other.height ?? height,
      minWidth: other.minWidth ?? minWidth,
      maxWidth: other.maxWidth ?? maxWidth,
      minHeight: other.minHeight ?? minHeight,
      maxHeight: other.maxHeight ?? maxHeight,
      margin: other.margin ?? margin,
      marginTop: other.marginTop ?? marginTop,
      marginRight: other.marginRight ?? marginRight,
      marginBottom: other.marginBottom ?? marginBottom,
      marginLeft: other.marginLeft ?? marginLeft,
      marginHorizontal: other.marginHorizontal ?? marginHorizontal,
      marginVertical: other.marginVertical ?? marginVertical,
      padding: other.padding ?? padding,
      paddingTop: other.paddingTop ?? paddingTop,
      paddingRight: other.paddingRight ?? paddingRight,
      paddingBottom: other.paddingBottom ?? paddingBottom,
      paddingLeft: other.paddingLeft ?? paddingLeft,
      paddingHorizontal: other.paddingHorizontal ?? paddingHorizontal,
      paddingVertical: other.paddingVertical ?? paddingVertical,
      left: other.left ?? left,
      top: other.top ?? top,
      right: other.right ?? right,
      bottom: other.bottom ?? bottom,
      position: other.position ?? position,
      flexDirection: other.flexDirection ?? flexDirection,
      justifyContent: other.justifyContent ?? justifyContent,
      alignItems: other.alignItems ?? alignItems,
      alignSelf: other.alignSelf ?? alignSelf,
      alignContent: other.alignContent ?? alignContent,
      flexWrap: other.flexWrap ?? flexWrap,
      flex: other.flex ?? flex,
      flexGrow: other.flexGrow ?? flexGrow,
      flexShrink: other.flexShrink ?? flexShrink,
      flexBasis: other.flexBasis ?? flexBasis,
      display: other.display ?? display,
      overflow: other.overflow ?? overflow,
      direction: other.direction ?? direction,
      borderWidth: other.borderWidth ?? borderWidth,
    );
  }

  /// Create a copy of this LayoutProps with certain properties modified
  LayoutProps copyWith({
    dynamic width,
    dynamic height,
    dynamic minWidth,
    dynamic maxWidth,
    dynamic minHeight,
    dynamic maxHeight,
    dynamic margin,
    dynamic marginTop,
    dynamic marginRight,
    dynamic marginBottom,
    dynamic marginLeft,
    dynamic marginHorizontal,
    dynamic marginVertical,
    dynamic padding,
    dynamic paddingTop,
    dynamic paddingRight,
    dynamic paddingBottom,
    dynamic paddingLeft,
    dynamic paddingHorizontal,
    dynamic paddingVertical,
    dynamic left,
    dynamic top,
    dynamic right,
    dynamic bottom,
    YogaPositionType? position,
    YogaFlexDirection? flexDirection,
    YogaJustifyContent? justifyContent,
    YogaAlign? alignItems,
    YogaAlign? alignSelf,
    YogaAlign? alignContent,
    YogaWrap? flexWrap,
    double? flex,
    double? flexGrow,
    double? flexShrink,
    dynamic flexBasis,
    YogaDisplay? display,
    YogaOverflow? overflow,
    YogaDirection? direction,
    dynamic borderWidth,
  }) {
    return LayoutProps(
      width: width ?? this.width,
      height: height ?? this.height,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      margin: margin ?? this.margin,
      marginTop: marginTop ?? this.marginTop,
      marginRight: marginRight ?? this.marginRight,
      marginBottom: marginBottom ?? this.marginBottom,
      marginLeft: marginLeft ?? this.marginLeft,
      marginHorizontal: marginHorizontal ?? this.marginHorizontal,
      marginVertical: marginVertical ?? this.marginVertical,
      padding: padding ?? this.padding,
      paddingTop: paddingTop ?? this.paddingTop,
      paddingRight: paddingRight ?? this.paddingRight,
      paddingBottom: paddingBottom ?? this.paddingBottom,
      paddingLeft: paddingLeft ?? this.paddingLeft,
      paddingHorizontal: paddingHorizontal ?? this.paddingHorizontal,
      paddingVertical: paddingVertical ?? this.paddingVertical,
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      position: position ?? this.position,
      flexDirection: flexDirection ?? this.flexDirection,
      justifyContent: justifyContent ?? this.justifyContent,
      alignItems: alignItems ?? this.alignItems,
      alignSelf: alignSelf ?? this.alignSelf,
      alignContent: alignContent ?? this.alignContent,
      flexWrap: flexWrap ?? this.flexWrap,
      flex: flex ?? this.flex,
      flexGrow: flexGrow ?? this.flexGrow,
      flexShrink: flexShrink ?? this.flexShrink,
      flexBasis: flexBasis ?? this.flexBasis,
      display: display ?? this.display,
      overflow: overflow ?? this.overflow,
      direction: direction ?? this.direction,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }

  /// List of all layout property names for easy identification
  static const List<String> all = [
    'width',
    'height',
    'minWidth',
    'maxWidth',
    'minHeight',
    'maxHeight',
    'margin',
    'marginTop',
    'marginRight',
    'marginBottom',
    'marginLeft',
    'marginHorizontal',
    'marginVertical',
    'padding',
    'paddingTop',
    'paddingRight',
    'paddingBottom',
    'paddingLeft',
    'paddingHorizontal',
    'paddingVertical',
    'left',
    'top',
    'right',
    'bottom',
    'position',
    'flexDirection',
    'justifyContent',
    'alignItems',
    'alignSelf',
    'alignContent',
    'flexWrap',
    'flex',
    'flexGrow',
    'flexShrink',
    'flexBasis',
    'display',
    'overflow',
    'direction',
    'borderWidth',
  ];

  /// Helper method to check if a property is a layout property
  static bool isLayoutProperty(String propName) {
    return all.contains(propName);
  }

  /// Parse a dimension value that could be a number or percentage string
  static dynamic parseDimensionValue(dynamic value) {
    if (value == null) return null;

    // If it's already a number, return it directly
    if (value is num) return value.toDouble();

    // Handle percentage strings
    if (value is String && value.endsWith('%')) {
      return value; // Keep percentage strings as-is for native handling
    }

    // Try to parse as a number
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Convert dimension to percentage string
  static String toPercentage(double value) {
    return '${value.toString()}%';
  }

  /// Check if dimension is percentage
  static bool isPercentage(dynamic value) {
    return value is String && value.endsWith('%');
  }
}
