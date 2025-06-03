import 'dart:developer' as developer;

/// A store for global state management
class Store<T> {
  /// The current state
  T _state;

  /// List of listeners to notify on state change
  final List<void Function(T)> _listeners = [];

  /// Create a store with initial state
  Store(this._state);

  /// Get the current state
  T get state => _state;

  /// Update the state
  void setState(T newState) {
    // Skip update if state is identical (for references) or equal (for values)
    if (identical(_state, newState) || _state == newState) {
      return;
    }

    developer.log('Store updated: from $_state to $newState', name: 'Store');

    // Update state
    _state = newState;

    // Notify listeners
    _notifyListeners();
  }

  /// Update the state using a function
  void updateState(T Function(T) updater) {
    setState(updater(_state));
  }

  /// Register a listener
  void subscribe(void Function(T) listener) {
    _listeners.add(listener);
  }

  /// Unregister a listener
  void unsubscribe(void Function(T) listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners of state change
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_state);
    }
  }
}

/// Store registry for managing global stores
class StoreRegistry {
  /// Singleton instance
  static final StoreRegistry instance = StoreRegistry._();

  /// Private constructor for singleton
  StoreRegistry._();

  /// Map of stores by ID
  final Map<String, Store<dynamic>> _stores = {};

  /// Register a store with a unique ID
  void registerStore<T>(String id, Store<T> store) {
    if (_stores.containsKey(id)) {
      developer.log('Store with ID $id already exists, replacing', name: 'StoreRegistry');
    }
    _stores[id] = store;
  }

  /// Get a store by ID
  Store<T>? getStore<T>(String id) {
    final store = _stores[id];
    if (store == null) {
      return null;
    }
    
    if (store is Store<T>) {
      return store;
    } else {
      developer.log('Store with ID $id is not of type Store<$T>', name: 'StoreRegistry');
      return null;
    }
  }

  /// Remove a store
  void removeStore(String id) {
    _stores.remove(id);
  }

  /// Create and register a store in one step
  Store<T> createStore<T>(String id, T initialState) {
    final store = Store<T>(initialState);
    registerStore(id, store);
    return store;
  }
}

/// Helper functions for working with stores
class StoreHelpers {
  /// Create a new store
  static Store<T> createStore<T>(T initialState) {
    return Store<T>(initialState);
  }
  
  /// Create and register a global store
  static Store<T> createGlobalStore<T>(String id, T initialState) {
    return StoreRegistry.instance.createStore(id, initialState);
  }
  
  /// Get a global store by ID
  static Store<T>? getGlobalStore<T>(String id) {
    return StoreRegistry.instance.getStore<T>(id);
  }
}
