# DCFlight Component Architecture & Protocol

## Overview

This document explains the architectural principles and protocols that govern how components work in DCFlight to ensure efficient VDOM reconciliation, proper state preservation, and predictable behavior.

## The Problem We Solved

### Case Study: Text Component Font Preservation

We recently encountered an issue where text components were losing properties like `fontSize` and `fontWeight` during state changes. The investigation revealed a critical architectural lesson:

**Initial Hypothesis**: VDOM diffing was incorrectly sending only changed props.  
**Reality**: VDOM diffing was working perfectly - it should only send changed props.  
**Actual Issue**: Native Swift component was applying unnecessary defaults that interfered with iOS system behavior.

### The Logs That Revealed the Truth

```
🔍 Text component VDOM reconciliation:
Old props: {content: Hello World, fontSize: 20.0, fontWeight: bold, color: #FF0000}
New props: {content: State change for global 4, fontSize: 20.0, fontWeight: bold, color: #FF0000}
Changed props being sent to native: {content: State change for global 4}
```

This showed perfect behavior: only the content changed, so only content was sent to the native layer. The fontSize, fontWeight, and color were correctly preserved by not being included in the update.

## Core Architectural Principles

### 1. Single Source of Truth

The VDOM maintains the complete state of each component. Native components should never:
- Store their own defaults
- Make assumptions about unspecified properties
- Reset properties that aren't in the current update

### 2. Efficient Reconciliation

The VDOM diffing algorithm only sends changed properties to native components. This is not a bug - it's the intended behavior for:
- Performance optimization
- Minimal native layer updates
- Clear separation of concerns
- Predictable state management

### 3. Respect System Defaults

Native components should respect platform defaults (iOS system fonts, Android material design, etc.) by not overriding them unless explicitly requested.

## Component Protocol Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Dart Layer    │    │   VDOM Engine    │    │  Native Layer   │
│                 │    │                  │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │ ┌─────────────┐ │
│ │  DCFText    │ │────│ │ Prop Diffing │ │────│ │ Text Native │ │
│ │  Primitive  │ │    │ │ Algorithm    │ │    │ │ Component   │ │
│ └─────────────┘ │    │ └──────────────┘ │    │ └─────────────┘ │
│                 │    │                  │    │                 │
│ • Declarative   │    │ • Efficient      │    │ • Minimal       │
│ • Explicit Props│    │ • Smart Diffing  │    │ • Respectful    │
│ • No Defaults   │    │ • Change Detection│    │ • Native Feel  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Data Flow

1. **Dart Primitive** declares component with explicit props only
2. **VDOM Engine** diffs props and identifies changes
3. **Native Component** applies only the changed props
4. **Platform** handles unspecified properties with system defaults

## Implementation Guidelines

### Dart Layer (Primitives)

```dart
// ✅ CORRECT: Explicit, nullable props
class DCFText extends DCFElement {
  final String? content;
  final double? fontSize;  // null means "not specified"
  final String? fontWeight;
  
  @override
  Map<String, dynamic> toNativeProps() {
    final props = <String, dynamic>{};
    
    // Only include explicitly set props
    if (content != null) props['content'] = content;
    if (fontSize != null) props['fontSize'] = fontSize;
    if (fontWeight != null) props['fontWeight'] = fontWeight;
    
    return props;
  }
}
```

### VDOM Layer (Reconciliation)

```dart
// The VDOM engine automatically handles this
Map<String, dynamic> diffProps(Map<String, dynamic> oldProps, Map<String, dynamic> newProps) {
  final changes = <String, dynamic>{};
  
  for (final key in newProps.keys) {
    if (oldProps[key] != newProps[key]) {
      changes[key] = newProps[key];
    }
  }
  
  return changes; // Only changed props are sent to native
}
```

### Native Layer (Swift/Kotlin)

```swift
// ✅ CORRECT: Only update specified props
func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool {
    guard let label = view as? UILabel else { return false }
    
    // Only update properties that are in the props dictionary
    if let content = props["content"] as? String {
        label.text = content
    }
    
    if let fontSize = props["fontSize"] as? CGFloat {
        // Preserve other font attributes when changing size
        let currentFont = label.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
        label.font = currentFont.withSize(fontSize)
    }
    
    // Don't touch properties not in props!
    
    return true
}
```

## Anti-Patterns and Their Consequences

### 1. ❌ Applying Defaults in Native Layer

```swift
// DON'T DO THIS
func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool {
    let fontSize = props["fontSize"] as? CGFloat ?? 16.0  // BAD!
    label.font = UIFont.systemFont(ofSize: fontSize)  // Resets font even when not requested
}
```

**Consequences:**
- Overrides iOS system font defaults
- Breaks state preservation during updates
- Creates unexpected behavior for developers

### 2. ❌ Providing Defaults in Dart Layer

```dart
// DON'T DO THIS
class DCFText extends DCFElement {
  final double fontSize;
  
  const DCFText({
    this.fontSize = 16.0,  // BAD! Always sends a value
  });
}
```

**Consequences:**
- Forces unnecessary prop updates
- Prevents VDOM optimization
- Breaks the "explicit only" principle

### 3. ❌ Always Sending All Props

```dart
// DON'T DO THIS
@override
Map<String, dynamic> toNativeProps() {
  return {
    'content': content ?? '',
    'fontSize': fontSize ?? 16.0,  // BAD! Always sends defaults
    'color': color ?? '#000000',
  };
}
```

**Consequences:**
- VDOM can't optimize (everything always "changes")
- Native layer receives unnecessary updates
- Performance degradation

## Best Practices Summary

### For Dart Primitives:
1. ✅ Use nullable properties (`String?`, `double?`)
2. ✅ Only include non-null props in `toNativeProps()`
3. ✅ Keep transformation logic minimal
4. ✅ Document required vs optional props clearly

### For Native Components:
1. ✅ Only update properties present in props dictionary
2. ✅ Respect platform defaults for unspecified properties
3. ✅ Preserve existing values when rebuilding complex properties (like fonts)
4. ✅ Use conditional updates (`if let` in Swift, `if` in Kotlin)

### For VDOM Integration:
1. ✅ Trust the diffing algorithm - it knows what changed
2. ✅ Don't second-guess prop optimization
3. ✅ Test with partial updates to ensure preservation
4. ✅ Monitor performance with minimal update patterns

## Testing Protocol Compliance

### Test 1: System Default Preservation
```dart
// Create component with no styling props
final text = DCFText(content: 'Hello');
// Should use iOS/Android system fonts and colors
```

### Test 2: Partial Update Preservation  
```dart
// Create styled component
final text1 = DCFText(content: 'Hello', fontSize: 20.0, fontWeight: 'bold');
// Update only content
final text2 = DCFText(content: 'World', fontSize: 20.0, fontWeight: 'bold');
// Should only send {content: 'World'} to native
```

### Test 3: State Change Isolation
```dart
// During state changes, verify only content updates
// fontSize, fontWeight, color should remain untouched in native layer
```

## Conclusion

The font preservation issue taught us that the VDOM system was working correctly all along. The problem was in the native layer applying unnecessary defaults. By following this protocol:

- **Dart primitives** declare intent explicitly
- **VDOM engine** optimizes efficiently  
- **Native components** respect platform conventions
- **Developers** get predictable, performant components

This architecture ensures that DCFlight components behave exactly as users expect while maintaining excellent performance through minimal, targeted updates.
