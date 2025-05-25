# DCFlight Component Protocol - Dart Primitives

## Overview

This document outlines the essential protocol for creating Dart primitive components in DCFlight to ensure proper prop handling, efficient VDOM reconciliation, and seamless integration with native components.

## The Golden Rule: Explicit Prop Management

**CRITICAL**: Your Dart primitive should **ONLY** pass props that are explicitly set by the user. Never inject default values or transform props unless absolutely necessary for the native layer.

## Why This Matters

DCFlight's VDOM system relies on precise prop diffing to determine what has changed. If your Dart primitive injects defaults or transforms props unnecessarily, it will:
- Interfere with efficient reconciliation
- Cause unnecessary native updates
- Break state preservation during updates
- Create unpredictable component behavior

## Component Protocol Guidelines

### 1. Leaf Components (Text, Image, etc.)

Leaf components represent terminal UI elements rendered by native components.

#### ✅ CORRECT Implementation

```dart
class DCFText extends DCFElement {
  final String? content;
  final double? fontSize;
  final String? fontWeight;
  final String? fontFamily;
  final String? color;
  final String? textAlign;
  final int? numberOfLines;
  final bool? isFontAsset;

  const DCFText({
    this.content,
    this.fontSize,
    this.fontWeight,
    this.fontFamily,
    this.color,
    this.textAlign,
    this.numberOfLines,
    this.isFontAsset,
    super.key,
  });

  @override
  Map<String, dynamic> toNativeProps() {
    final props = <String, dynamic>{};
    
    // ✅ Only include props that are explicitly set
    if (content != null) props['content'] = content;
    if (fontSize != null) props['fontSize'] = fontSize;
    if (fontWeight != null) props['fontWeight'] = fontWeight;
    if (fontFamily != null) props['fontFamily'] = fontFamily;
    if (color != null) props['color'] = color;
    if (textAlign != null) props['textAlign'] = textAlign;
    if (numberOfLines != null) props['numberOfLines'] = numberOfLines;
    if (isFontAsset != null) props['isFontAsset'] = isFontAsset;
    
    return props;
  }

  @override
  String get componentType => 'text';

  @override
  List<DCFElement> get children => [];
}
```

#### ❌ INCORRECT Implementation

```dart
class DCFText extends DCFElement {
  final String content;
  final double fontSize;
  final String fontWeight;
  final String color;

  const DCFText({
    required this.content,
    this.fontSize = 16.0,  // ❌ DON'T provide defaults
    this.fontWeight = 'regular',  // ❌ DON'T provide defaults
    this.color = '#000000',  // ❌ DON'T provide defaults
    super.key,
  });

  @override
  Map<String, dynamic> toNativeProps() {
    // ❌ Always sending all props, even defaults
    return {
      'content': content,
      'fontSize': fontSize,  // This will always be sent, even when not specified
      'fontWeight': fontWeight,  // This will always be sent
      'color': color,  // This will always be sent
    };
  }
}
```

### 2. Parent Components (Container, Stack, etc.)

Parent components manage layout and contain child components.

#### ✅ CORRECT Implementation

```dart
class DCFStack extends DCFElement {
  final String? direction;
  final String? alignment;
  final String? justifyContent;
  final double? spacing;
  final List<DCFElement> children;

  const DCFStack({
    this.direction,
    this.alignment,
    this.justifyContent,
    this.spacing,
    required this.children,
    super.key,
  });

  @override
  Map<String, dynamic> toNativeProps() {
    final props = <String, dynamic>{};
    
    // ✅ Only include layout props that are explicitly set
    if (direction != null) props['direction'] = direction;
    if (alignment != null) props['alignment'] = alignment;
    if (justifyContent != null) props['justifyContent'] = justifyContent;
    if (spacing != null) props['spacing'] = spacing;
    
    return props;
  }

  @override
  String get componentType => 'stack';

  @override
  List<DCFElement> get children => this.children;
}
```

### 3. Prop Validation and Transformation

Sometimes you need to validate or transform props for the native layer.

#### ✅ CORRECT Validation

```dart
class DCFImage extends DCFElement {
  final String? source;
  final double? width;
  final double? height;
  final String? contentMode;

  const DCFImage({
    this.source,
    this.width,
    this.height,
    this.contentMode,
    super.key,
  });

  @override
  Map<String, dynamic> toNativeProps() {
    final props = <String, dynamic>{};
    
    // ✅ Only include and validate props that are set
    if (source != null) {
      // ✅ Transform only when necessary for native layer
      props['source'] = source!.startsWith('asset://') 
        ? source!.substring(8) 
        : source;
    }
    
    if (width != null) {
      // ✅ Validate but don't provide defaults
      assert(width! > 0, 'Width must be positive');
      props['width'] = width;
    }
    
    if (height != null) {
      assert(height! > 0, 'Height must be positive');
      props['height'] = height;
    }
    
    if (contentMode != null) {
      // ✅ Validate enum values
      assert(['fill', 'fit', 'stretch'].contains(contentMode), 
        'Invalid contentMode: $contentMode');
      props['contentMode'] = contentMode;
    }
    
    return props;
  }

  @override
  String get componentType => 'image';

  @override
  List<DCFElement> get children => [];
}
```

## VDOM Integration Best Practices

### 1. State-Aware Components

For components that manage internal state:

```dart
class DCFButton extends DCFElement {
  final String? title;
  final String? color;
  final VoidCallback? onPressed;
  final bool? disabled;

  const DCFButton({
    this.title,
    this.color,
    this.onPressed,
    this.disabled,
    super.key,
  });

  @override
  Map<String, dynamic> toNativeProps() {
    final props = <String, dynamic>{};
    
    // ✅ Only pass visual props to native
    if (title != null) props['title'] = title;
    if (color != null) props['color'] = color;
    if (disabled != null) props['disabled'] = disabled;
    
    // ✅ Handle callbacks in Dart layer, not native
    if (onPressed != null) {
      props['onPressed'] = true;  // Just indicate it's pressable
    }
    
    return props;
  }

  @override
  String get componentType => 'button';

  @override
  List<DCFElement> get children => [];
}
```

### 2. Conditional Props

For props that depend on other props:

```dart
class DCFTextField extends DCFElement {
  final String? placeholder;
  final String? value;
  final bool? multiline;
  final int? maxLines;

  const DCFTextField({
    this.placeholder,
    this.value,
    this.multiline,
    this.maxLines,
    super.key,
  });

  @override
  Map<String, dynamic> toNativeProps() {
    final props = <String, dynamic>{};
    
    if (placeholder != null) props['placeholder'] = placeholder;
    if (value != null) props['value'] = value;
    if (multiline != null) props['multiline'] = multiline;
    
    // ✅ Conditional prop based on multiline
    if (maxLines != null) {
      // Only send maxLines if multiline is enabled
      if (multiline == true) {
        props['maxLines'] = maxLines;
      }
    }
    
    return props;
  }

  @override
  String get componentType => 'textfield';

  @override
  List<DCFElement> get children => [];
}
```

## Common Anti-Patterns to Avoid

### 1. ❌ Always Providing Defaults
```dart
// DON'T DO THIS
const DCFText({
  this.content = '',  // Forces empty string default
  this.fontSize = 16.0,  // Forces font size default
});
```

### 2. ❌ Transforming Props Unnecessarily
```dart
// DON'T DO THIS
@override
Map<String, dynamic> toNativeProps() {
  return {
    'content': content ?? '',  // Don't inject defaults
    'fontSize': fontSize ?? 16.0,  // Don't inject defaults
    'color': color?.toUpperCase() ?? '#000000',  // Don't transform unless necessary
  };
}
```

### 3. ❌ Complex Prop Logic in Primitives
```dart
// DON'T DO THIS - Keep primitives simple
@override
Map<String, dynamic> toNativeProps() {
  final calculatedFontSize = fontSize != null 
    ? fontSize! * 1.2  // Complex calculations don't belong here
    : null;
    
  return {
    if (calculatedFontSize != null) 'fontSize': calculatedFontSize,
  };
}
```

## Testing Your Component

### Test Case 1: Minimal Props
```dart
void testMinimalProps() {
  final text = DCFText(content: 'Hello');
  final props = text.toNativeProps();
  
  // Should only contain content
  expect(props.keys, equals(['content']));
  expect(props['content'], equals('Hello'));
}
```

### Test Case 2: All Props Set
```dart
void testAllProps() {
  final text = DCFText(
    content: 'Hello',
    fontSize: 18.0,
    fontWeight: 'bold',
    color: '#FF0000',
  );
  final props = text.toNativeProps();
  
  // Should contain all specified props
  expect(props.keys.length, equals(4));
  expect(props['fontSize'], equals(18.0));
}
```

### Test Case 3: VDOM Diffing
```dart
void testVDOMDiffing() {
  final text1 = DCFText(content: 'Hello', fontSize: 16.0);
  final text2 = DCFText(content: 'World', fontSize: 16.0);
  
  final props1 = text1.toNativeProps();
  final props2 = text2.toNativeProps();
  
  // VDOM should only send changed props (content in this case)
  final diff = calculatePropDiff(props1, props2);
  expect(diff.keys, equals(['content']));
}
```

## Summary

Following this protocol ensures:
- ✅ Efficient VDOM reconciliation
- ✅ Minimal prop passing to native layer
- ✅ Predictable component behavior
- ✅ Proper state preservation
- ✅ Clean separation of concerns
- ✅ Easy debugging and testing

Remember: **Your Dart primitive is a declaration of intent, not an implementation. Keep it simple, explicit, and let the VDOM and native layers handle the complex parts.**
