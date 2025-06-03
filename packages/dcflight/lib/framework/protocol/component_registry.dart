import 'package:dcflight/framework/protocol/component_protocol.dart';
import 'package:dcflight/framework/renderer/vdom/vdom_element.dart';
import 'package:dcflight/framework/renderer/vdom/vdom_node.dart';
import 'package:flutter/foundation.dart';

/// Registry for component factories
/// This allows components to be registered with the framework
/// without requiring the framework to know about their specific implementations
class ComponentRegistry {
  /// Singleton instance for global access
  static final ComponentRegistry instance = ComponentRegistry._();
  
  /// Private constructor for singleton
  ComponentRegistry._();
  
  /// Map of component factories by type
  final Map<String, ComponentFactory> _factories = {};
  

  /// Register a component factory and definition
  void registerComponent(String type, ComponentFactory factory) {
    _factories[type] = factory;
    
    
    
    debugPrint('Registered component: $type');
  }

  /// Get a component factory by type
  ComponentFactory? getFactory(String type) {
    return _factories[type];
  }
  

  
  /// Check if a component type is registered
  bool hasComponent(String type) {
    return _factories.containsKey(type);
  }
  
  /// Get all registered component types
  List<String> get registeredTypes {
    return _factories.keys.toList();
  }
  
  /// Create a component instance with the given type, props and children
  VDomElement create(String type, Map<String, dynamic> props, List<VDomNode> children) {
    final factory = _factories[type];
    if (factory == null) {
      throw Exception('Component factory not found: $type');
    }
    
    return factory(props, children);
  }
}