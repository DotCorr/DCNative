# Global State Management with Stores

DCFlight provides a powerful and easy-to-use global state management system based on stores. This system allows you to share state between components and manage complex application state in a predictable way.

## Creating Stores

You can create a store in several ways:

### Local Store

```dart
// Create a local store with an initial value of 0
final counterStore = Store<int>(0);
```

### Global Store (via Registry)

```dart
// Create and register a global store
final counterStore = StoreHelpers.createGlobalStore<int>('counter', 0);

// Get a reference to an existing global store
final counter = StoreHelpers.getGlobalStore<int>('counter');
```

## Using Stores in Components

The `useStore` hook makes it easy to connect a component to a store:

```dart
class CounterComponent extends StatefulComponent {
  @override
  VDomNode render() {
    // Connect to the store
    final counter = useStore(counterStore);
    
    return view(
      children: [
        text(content: 'Count: ${counter.state}'),
        button(
          buttonProps: ButtonProps(title: 'Increment'),
          onPress: () {
            // Update the store
            counter.updateState((state) => state + 1);
          },
        )
      ],
    );
  }
}
```

## Updating State

There are two ways to update a store's state:

### Direct State Update

```dart
counter.setState(42);
```

### Functional Update

```dart
counter.updateState((currentState) => currentState + 1);
```

The functional update is safer when the update depends on the current state.

## Complex State Examples

### Object State

```dart
// Define a state class
class UserState {
  final String name;
  final int age;
  
  UserState({required this.name, required this.age});
  
  // Create a new state with some properties changed
  UserState copyWith({String? name, int? age}) {
    return UserState(
      name: name ?? this.name,
      age: age ?? this.age,
    );
  }
}

// Create a store with the initial state
final userStore = Store<UserState>(UserState(name: 'John', age: 30));

// Update a specific property
userStore.updateState((state) => state.copyWith(age: 31));
```

### List State

```dart
// Store for a list of items
final itemsStore = Store<List<String>>(['Item 1', 'Item 2']);

// Add an item
itemsStore.updateState((items) => [...items, 'Item 3']);

// Remove an item
itemsStore.updateState((items) => items.where((item) => item != 'Item 2').toList());
```

## Advanced Usage

### Computed State

You can create computed state by deriving values from your store:

```dart
class TodoComponent extends StatefulComponent {
  @override
  VDomNode render() {
    final todoStore = useStore(todosStore);
    
    // Compute derived state
    final completedCount = todoStore.state.where((todo) => todo.completed).length;
    final totalCount = todoStore.state.length;
    
    return view(
      children: [
        text(content: 'Completed: $completedCount / $totalCount'),
        // Rest of the component
      ],
    );
  }
}
```

### Store Composition

You can compose multiple stores to create more complex state management:

```dart
// Authentication store
final authStore = StoreHelpers.createGlobalStore<User?>('auth', null);

// Theme store
final themeStore = StoreHelpers.createGlobalStore<ThemeMode>('theme', ThemeMode.light);

// App component using multiple stores
class App extends StatefulComponent {
  @override
  VDomNode render() {
    final auth = useStore(authStore);
    final theme = useStore(themeStore);
    
    // Use both stores to render the UI
    // ...
  }
}
```
