import 'dart:ui' show Color;

import 'package:dcflight/dcflight.dart';

/// StyleSheet for visual styling properties
class StyleSheet {
  // Border styles
  final dynamic borderRadius;
  final dynamic borderTopLeftRadius;
  final dynamic borderTopRightRadius;
  final dynamic borderBottomLeftRadius;
  final dynamic borderBottomRightRadius;
  final Color? borderColor;
  final dynamic borderWidth;

  // Background and opacity
  final Color? backgroundColor;
  final double? opacity;

  // Shadow properties
  final Color? shadowColor;
  final double? shadowOpacity;
  final dynamic shadowRadius;
  final dynamic shadowOffsetX;
  final dynamic shadowOffsetY;
  final dynamic elevation;

  // Transform properties
  final Map<String, dynamic>? transform;

  // Hit area expansion
  final Map<String, dynamic>? hitSlop;

  // Accessibility properties
  final bool? accessible;
  final String? accessibilityLabel;
  final String? testID;
  final bool? pointerEvents;

  /// Create a style sheet with visual styling properties
  const StyleSheet({
    this.borderRadius,
    this.borderTopLeftRadius,
    this.borderTopRightRadius,
    this.borderBottomLeftRadius,
    this.borderBottomRightRadius,
    this.borderColor = Colors.black,
    this.borderWidth,
    this.backgroundColor,
    this.opacity,
    this.shadowColor = Colors.black,
    this.shadowOpacity,
    this.shadowRadius,
    this.shadowOffsetX,
    this.shadowOffsetY,
    this.elevation,
    this.transform,
    this.hitSlop,
    this.accessible,
    this.accessibilityLabel,
    this.testID,
    this.pointerEvents,
  });

  /// Convert style properties to a map for serialization
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    // Add border style properties
    if (borderRadius != null) map['borderRadius'] = borderRadius;
    if (borderTopLeftRadius != null) {
      map['borderTopLeftRadius'] = borderTopLeftRadius;
    }
    if (borderTopRightRadius != null) {
      map['borderTopRightRadius'] = borderTopRightRadius;
    }
    if (borderBottomLeftRadius != null) {
      map['borderBottomLeftRadius'] = borderBottomLeftRadius;
    }
    if (borderBottomRightRadius != null) {
      map['borderBottomRightRadius'] = borderBottomRightRadius;
    }
    if (borderColor != null) {
      // FIXED: Check for transparency before converting to hex
      if (borderColor!.alpha == 0) {
        map['borderColor'] = 'transparent';
      } else {
        final hexValue = borderColor!.value & 0xFFFFFF;
        map['borderColor'] = '#${hexValue.toRadixString(16).padLeft(6, '0')}';
      }
    }
    if (borderWidth != null) map['borderWidth'] = borderWidth;

    // Add background and opacity
    if (backgroundColor != null) {
      // FIXED: Check for transparency and handle it specially
      if (backgroundColor!.alpha == 0) {
        map['backgroundColor'] = 'transparent';

      } else {
        final hexValue = backgroundColor!.value & 0xFFFFFF;
        map['backgroundColor'] =
            '#${hexValue.toRadixString(16).padLeft(6, '0')}';
      
      }
    }
    if (opacity != null) map['opacity'] = opacity;

    // Add shadow properties
    if (shadowColor != null) {
      // FIXED: Also check for transparency in shadow color
      if (shadowColor!.alpha == 0) {
        map['shadowColor'] = 'transparent';
      } else {
        final hexValue = shadowColor!.value & 0xFFFFFF;
        map['shadowColor'] = '#${hexValue.toRadixString(16).padLeft(6, '0')}';
      }
    }
    if (shadowOpacity != null) map['shadowOpacity'] = shadowOpacity;
    if (shadowRadius != null) map['shadowRadius'] = shadowRadius;
    if (shadowOffsetX != null) map['shadowOffsetX'] = shadowOffsetX;
    if (shadowOffsetY != null) map['shadowOffsetY'] = shadowOffsetY;
    if (elevation != null) map['elevation'] = elevation;

    // Add transform properties
    if (transform != null) map['transform'] = transform;

    // Add hit slop
    if (hitSlop != null) map['hitSlop'] = hitSlop;

    // Add accessibility properties
    if (accessible != null) map['accessible'] = accessible;
    if (accessibilityLabel != null) {
      map['accessibilityLabel'] = accessibilityLabel;
    }
    if (testID != null) map['testID'] = testID;
    if (pointerEvents != null) map['pointerEvents'] = pointerEvents;

    return map;
  }

  /// Create a new StyleSheet by merging this one with another
  StyleSheet merge(StyleSheet other) {
    return StyleSheet(
      borderRadius: other.borderRadius ?? borderRadius,
      borderTopLeftRadius: other.borderTopLeftRadius ?? borderTopLeftRadius,
      borderTopRightRadius: other.borderTopRightRadius ?? borderTopRightRadius,
      borderBottomLeftRadius:
          other.borderBottomLeftRadius ?? borderBottomLeftRadius,
      borderBottomRightRadius:
          other.borderBottomRightRadius ?? borderBottomRightRadius,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      opacity: other.opacity ?? opacity,
      shadowColor: other.shadowColor ?? shadowColor,
      shadowOpacity: other.shadowOpacity ?? shadowOpacity,
      shadowRadius: other.shadowRadius ?? shadowRadius,
      shadowOffsetX: other.shadowOffsetX ?? shadowOffsetX,
      shadowOffsetY: other.shadowOffsetY ?? shadowOffsetY,
      elevation: other.elevation ?? elevation,
      transform: other.transform ?? transform,
      hitSlop: other.hitSlop ?? hitSlop,
      accessible: other.accessible ?? accessible,
      accessibilityLabel: other.accessibilityLabel ?? accessibilityLabel,
      testID: other.testID ?? testID,
      pointerEvents: other.pointerEvents ?? pointerEvents,
    );
  }

  /// Create a copy of this StyleSheet with certain properties modified
  StyleSheet copyWith({
    dynamic borderRadius,
    dynamic borderTopLeftRadius,
    dynamic borderTopRightRadius,
    dynamic borderBottomLeftRadius,
    dynamic borderBottomRightRadius,
    Color? borderColor,
    dynamic borderWidth,
    Color? backgroundColor,
    double? opacity,
    Color? shadowColor,
    double? shadowOpacity,
    dynamic shadowRadius,
    dynamic shadowOffsetX,
    dynamic shadowOffsetY,
    dynamic elevation,
    Map<String, dynamic>? transform,
    Map<String, dynamic>? hitSlop,
    bool? accessible,
    String? accessibilityLabel,
    String? testID,
    bool? pointerEvents,
  }) {
    return StyleSheet(
      borderRadius: borderRadius ?? this.borderRadius,
      borderTopLeftRadius: borderTopLeftRadius ?? this.borderTopLeftRadius,
      borderTopRightRadius: borderTopRightRadius ?? this.borderTopRightRadius,
      borderBottomLeftRadius:
          borderBottomLeftRadius ?? this.borderBottomLeftRadius,
      borderBottomRightRadius:
          borderBottomRightRadius ?? this.borderBottomRightRadius,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      opacity: opacity ?? this.opacity,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      shadowRadius: shadowRadius ?? this.shadowRadius,
      shadowOffsetX: shadowOffsetX ?? this.shadowOffsetX,
      shadowOffsetY: shadowOffsetY ?? this.shadowOffsetY,
      elevation: elevation ?? this.elevation,
      transform: transform ?? this.transform,
      hitSlop: hitSlop ?? this.hitSlop,
      accessible: accessible ?? this.accessible,
      accessibilityLabel: accessibilityLabel ?? this.accessibilityLabel,
      testID: testID ?? this.testID,
      pointerEvents: pointerEvents ?? this.pointerEvents,
    );
  }

  /// List of all style property names for easy identification
  static const List<String> all = [
    'borderRadius',
    'borderTopLeftRadius',
    'borderTopRightRadius',
    'borderBottomLeftRadius',
    'borderBottomRightRadius',
    'borderColor',
    'borderWidth',
    'backgroundColor',
    'opacity',
    'shadowColor',
    'shadowOpacity',
    'shadowRadius',
    'shadowOffsetX',
    'shadowOffsetY',
    'elevation',
    'transform',
    'hitSlop',
    'accessible',
    'accessibilityLabel',
    'testID',
    'pointerEvents',
  ];

  /// Helper method to check if a property is a style property
  static bool isStyleProperty(String propName) {
    return all.contains(propName);
  }
}
