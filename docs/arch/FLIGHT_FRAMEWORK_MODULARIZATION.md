# DCFlight Framework Modularization

This document outlines the modularized architecture of the DCFlight framework.

## Overview

The DCFlight framework has been modularized to separate the core framework layer from component implementations. This architecture allows for:

- Independent development of the framework core
- Pluggable component modules
- Better maintainability and extensibility
- Cleaner separation of concerns

## Architecture

The modularization follows a clear layered approach:

1. **Framework Layer** (core)
   - Protocols and interfaces
   - VDOM implementation
   - Native bridge
   - Layout engine (Yoga)

2. **Components Layer** (primitives)
   - Component implementations (View, Text, Button, etc.)
   - Component-specific props and refs
   - Component event handling

## Framework Structure

### Dart Side

#### Core Protocols and Interfaces

The framework layer defines protocols through abstract classes and interfaces:

- `ComponentDefinition` - Interface for component definitions
- `ComponentFactory` - Type definition for component factories
- `ComponentProps` - Base class for component properties
- `DCFPlugin` - Interface for framework plugins

#### Registry System

Component registration is handled through the registry system:

- `ComponentRegistry` - Singleton registry for component factories
- `PluginRegistry` - Registry for framework plugins

#### Core Infrastructure

The framework provides core infrastructure without component-specific code:

- `VDom` - Virtual DOM implementation
- `PlatformDispatcher` - Native bridge communication
- `DCFlight` - Framework main entry point

### Native (iOS) Side

#### Component Protocol

The native side defines the component protocol:

```swift
protocol DCFComponent {
    /// Initialize the component
    init()
    
    /// Create a view with the given props
    func createView(props: [String: Any]) -> UIView
    
    /// Update a view with new props
    func updateView(_ view: UIView, withProps props: [String: Any]) -> Bool
    
    /// Apply yoga layout to the view
    func applyLayout(_ view: UIView, layout: YGNodeLayout)
    
    // Other required methods...
}
```

#### Method Handling Protocol

For component method calls:

```swift
protocol ComponentMethodHandler {
    /// Handle a method call on a specific view instance
    func handleMethod(methodName: String, args: [String: Any], view: UIView) -> Bool
}
```

#### Registry System

Components are registered through:

```swift
class DCFComponentRegistry {
    static let shared = DCFComponentRegistry()
    
    internal var componentTypes: [String: DCFComponent.Type] = [:]
    
    func registerComponent(_ type: String, componentClass: DCFComponent.Type) {
        componentTypes[type] = componentClass
        print("Registered component type: \(type)")
    }
    
    // Other methods...
}
```

#### Module System

The module system enables pluggable components:

```swift
protocol DCFModule {
    var name: String { get }
    var priority: Int { get }
    func initialize()
    func registerComponents()
}
```

## Flow of Operations

### Component Registration Flow

1. A component module implements the `DCFPlugin` (Dart) or `DCFModule` (iOS) protocol
2. During app initialization, the module registers itself with the framework
3. The framework invokes the module's `registerComponents()` method
4. The module registers its components with the component registry

### Component Creation Flow

1. Dart code creates a component using the VDOM: `vdom.createElement('Button', props, children)`
2. The VDOM looks up the component factory in the `ComponentRegistry`
3. The component factory creates a `VDomElement` with the component's type
4. The element is added to the VDOM tree

### Native Rendering Flow

1. `vdom.renderToNative()` is called to render the tree
2. The VDOM serializes the tree and sends it to the native bridge
3. Native bridge creates views using the component registry to find implementations
4. Layout props are extracted and applied to the Yoga shadow tree
5. Style props are applied directly to views

### Method Call Flow (e.g., ScrollViewRef.scrollTo)

1. Dart side calls a method on a component reference: `scrollViewRef.scrollTo({x: 0, y: 100})`
2. The call is routed through `PlatformDispatcher.instance.callComponentMethod`
3. Native bridge receives the method call through `handleCallComponentMethod`
4. Bridge looks up the view and its component type
5. If component implements `ComponentMethodHandler`, the method is routed to it
6. Component handles the method internally

### Event Flow

1. Native component triggers an event: `triggerEvent(view, "onPress", eventData)`
2. Event data is sent to `DCMauiEventMethodHandler`
3. Event is serialized and sent over the bridge to Dart
4. VDOM routes the event to the appropriate event handler in the component props

## Integration with Host Apps

### iOS Integration

Host apps integrate with DCFlight by importing the framework and calling the `divergeToFlight()` method in their `AppDelegate`:

```swift
@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
    lazy var flutterEngine = FlutterEngine(name: "main engine")
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        divergeToFlight()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

The `divergeToFlight()` extension method:
- Initializes the Flutter engine
- Sets up method channels
- Creates a native root view controller
- Registers the root view with the bridge
- Initializes the layout system

### Dart Integration

Host apps integrate with DCFlight by importing the framework and calling `initializeApplication()`:

```dart
import 'package:dcflight/main.dart';

void main() {
  initializeApplication(MyApp());
}

class MyApp extends Component {
  @override
  render() {
    // Render your app using DCFlight components
  }
}
```

## Component Implementation

To create a new component, developers need to:

### Dart Side

1. Create a component plugin implementing `DCFPlugin`
2. Create component props class extending `ComponentProps`
3. Create component factory function
4. Create component definition implementing `ComponentDefinition`
5. Register components with `ComponentRegistry`

### Native Side

1. Create a module implementing `DCFModule`
2. Create component class implementing `DCFComponent`
3. Implement method handler if needed with `ComponentMethodHandler`
4. Register components with `DCFComponentRegistry`

## Conclusion

The DCFlight framework's modularized architecture provides a clean separation between the framework layer and component implementations. This allows for pluggable components, independent development, and better maintainability while maintaining high performance through native rendering.

The framework layer has been successfully modularized, with all component-specific code removed and replaced with protocol-based interfaces. Component implementations can now be added as separate modules without modifying the core framework code.
