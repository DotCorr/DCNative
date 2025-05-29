import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'store.dart';
import 'store_manager.dart';

/// Base hook class for all hook types
abstract class Hook {
  /// Clean up the hook when component unmounts
  void dispose() {}
}

/// State hook for managing component state
class StateHook<T> extends Hook {
  /// Current value of the state
  T _value;

  /// Name for debugging
  final String? _name;

  /// Schedule update function to trigger re-render
  final Function() _scheduleUpdate;

  /// Create a state hook
  StateHook(this._value, this._name, this._scheduleUpdate);

  /// Get the current value
  T get state => _value;

  /// Set the value and trigger update
  void setState(T newValue) {
    // Only update and trigger render if value actually changed
    if (_value != newValue) {
      _value = newValue;
      
      if (kDebugMode) {
        final name = _name != null ? ' ($_name)' : '';
        developer.log('State changed$name: $newValue', name: 'StateHook');
      }
      
      // Schedule a component update
      _scheduleUpdate();
    }
  }
  
  @override
  void dispose() {
    // Nothing to dispose for simple state
  }
  
  @override
  String toString() {
    final name = _name != null ? ' ($_name)' : '';
    return 'StateHook$name: $_value';
  }
}

/// Effect hook for side effects in components
class EffectHook extends Hook {
  /// The effect function
  final Function()? Function() _effect;

  /// Dependencies array - when these change, effect runs again
  List<dynamic> _dependencies;

  /// Cleanup function returned by the effect
  Function()? _cleanup;

  /// Previous dependencies for comparison
  List<dynamic>? _prevDeps;

  /// Create an effect hook
  EffectHook(this._effect, this._dependencies);
  
  /// Update dependencies - called during reconciliation
  void updateDependencies(List<dynamic> newDependencies) {
    _dependencies = newDependencies;
  }

  /// Run the effect if needed based on dependency changes
  void runEffect() {
    // Run effect if first time or dependencies changed
    if (_prevDeps == null || !_areEqualDeps(_dependencies, _prevDeps!)) {
      // Clean up previous effect if needed
      if (_cleanup != null) {
        _cleanup!();
        _cleanup = null;
      }

      // Run the effect and store cleanup
      _cleanup = _effect();
      
      // Update previous dependencies
      _prevDeps = List<dynamic>.from(_dependencies);
    }
  }

  @override
  void dispose() {
    // Run cleanup if it exists
    if (_cleanup != null) {
      _cleanup!();
      _cleanup = null;
    }
  }

  /// Compare two dependency arrays for equality
  bool _areEqualDeps(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;
    
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    
    return true;
  }
}

/// Reference object wrapper
class RefObject<T> {
  /// Current value
  T? _value;

  /// Create a ref object
  RefObject([this._value]);

  /// Get current value
  T? get current => _value;
  
  /// Set current value
  set current(T? value) {
    _value = value;
  }
}

/// Ref hook for storing mutable references
class RefHook<T> extends Hook {
  /// The ref object
  final RefObject<T> ref;

  /// Create a ref hook
  RefHook([T? initialValue]) : ref = RefObject<T>(initialValue);
  
  @override
  void dispose() {
    // Nothing to dispose for refs
  }
}

/// Store hook for connecting to global state with proper lifecycle management
class StoreHook<T> extends Hook {
  /// The store
  final Store<T> _store;
  
  /// Get the store (for hook validation)
  Store<T> get store => _store;
  
  /// Component ID for tracking subscriptions
  final String _componentId;
  
  /// Whether we're managed by StoreManager
  bool _isManagedByStoreManager = false;

  /// Create a store hook with proper lifecycle management
  StoreHook(this._store, Function() onChange, this._componentId) {
    // Use StoreManager for centralized subscription management
    if (!StoreManager.instance.isComponentSubscribed(_componentId, _store)) {
      StoreManager.instance.subscribeComponent(_componentId, _store, onChange);
      _isManagedByStoreManager = true;
      
      if (kDebugMode) {
        developer.log('StoreHook created and managed for component $_componentId', name: 'StoreHook');
      }
    } else {
      if (kDebugMode) {
        developer.log('Component $_componentId already subscribed to store - reusing subscription', name: 'StoreHook');
      }
    }
  }

  /// Get current state
  T get state => _store.state;
  
  /// Update store state
  void setState(T newState) {
    _store.setState(newState);
  }
  
  /// Update store state with a function
  void updateState(T Function(T) updater) {
    _store.updateState(updater);
  }

  @override
  void dispose() {
    // Only unsubscribe if we're the managing hook
    if (_isManagedByStoreManager) {
      StoreManager.instance.unsubscribeComponentFromStore(_componentId, _store);
      _isManagedByStoreManager = false;
      
      if (kDebugMode) {
        developer.log('StoreHook disposed for component $_componentId', name: 'StoreHook');
      }
    }
  }
}
