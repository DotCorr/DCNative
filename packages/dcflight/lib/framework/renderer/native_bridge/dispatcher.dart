import 'dart:async';

import 'package:dcflight/framework/renderer/native_bridge/dispatcher_imp.dart';

/// Interface for platform-specific native bridge operations
abstract class PlatformDispatcher {
  /// Get the singleton instance
  static PlatformDispatcher? _instance;
  
  /// Get the singleton instance
  static PlatformDispatcher get instance {
    if (_instance == null) {
      _instance = NativeBridgeFactory.create();
    }
    return _instance!;
  }
  
  /// Initialize the bridge with native code
  Future<bool> initialize();

  /// Create a view with the specified ID, type, and properties
  Future<bool> createView(String viewId, String type, Map<String, dynamic> props);

  /// Update properties for an existing view
  Future<bool> updateView(String viewId, Map<String, dynamic> propPatches);

  /// Delete a view
  Future<bool> deleteView(String viewId);

  /// Detach a view from its parent without deleting it
  Future<bool> detachView(String viewId);

  /// Attach a child view to a parent at the specified index
  Future<bool> attachView(String childId, String parentId, int index);

  /// Set all children for a view (replacing any existing children)
  Future<bool> setChildren(String viewId, List<String> childrenIds);

  /// Add event listeners to a view
  Future<bool> addEventListeners(String viewId, List<String> eventTypes);

  /// Remove event listeners from a view
  Future<bool> removeEventListeners(String viewId, List<String> eventTypes);

  /// Register a specific callback for a view's event
  void registerEventCallback(String viewId, String eventType, Function callback);

  /// Set a global event handler for all events
  void setEventHandler(Function(String viewId, String eventType, Map<String, dynamic> eventData) handler);

  /// Update the layout of a view
  Future<bool> updateViewLayout(String viewId, double left, double top, double width, double height);

  /// Calculate layout for the entire view hierarchy
  Future<bool> calculateLayout();

  /// Call a method on a specific component instance
  Future<dynamic> callComponentMethod(String viewId, String methodName, Map<String, dynamic> args);

  /// Start a batch update (multiple operations that will be applied atomically)
  Future<bool> startBatchUpdate();

  /// Commit the pending batch updates
  Future<bool> commitBatchUpdate();

  /// Cancel the pending batch updates
  Future<bool> cancelBatchUpdate();

  /// Handle an event from native code
  void handleNativeEvent(String viewId, String eventType, Map<String, dynamic> eventData);
}

/// Factory for creating platform-specific native bridges
class NativeBridgeFactory {
  static PlatformDispatcher create() {
    return PlatformDispatcherIml();
  }
}
