// Test for store usage validation system

import 'package:dcf_go/app/index.dart';
import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/framework/constants/layout_properties.dart';
import 'package:dcflight/framework/renderer/vdom/component/component.dart';
import 'package:dcflight/framework/renderer/vdom/component/component_node.dart';
import 'package:dcflight/framework/renderer/vdom/component/store.dart';

/// Global stores for testing
final testStore1 = Store<int>(0);
final testStore2 = Store<String>('initial');

/// Component that uses hooks correctly (should not trigger warnings)
class GoodComponent extends StatefulComponent {
  @override
  DCFComponentNode render() {
    // ✅ GOOD: Using hooks consistently
    final counter = useStore(testStore1);
    final message = useStore(testStore2);
    
    return DCFText(content:'Count: ${counter.state}, Message: ${message.state}');
  }
}

/// Component that uses direct access correctly (should not trigger warnings)
class DirectAccessComponent extends StatefulComponent {
  @override
  DCFComponentNode render() {
    // ✅ ACCEPTABLE: Using direct access consistently (but no reactive updates)
    final count = testStore1.state;
    final message = testStore2.state;
    
    return DCFText(content: 'Direct Count: $count, Direct Message: $message');
  }
}

/// Component that mixes patterns (SHOULD trigger warnings)
class BadMixedComponent extends StatefulComponent {
  @override
  DCFComponentNode render() {
    // ❌ BAD: Mixing hooks and direct access
    final counter = useStore(testStore1);  // Using hook
    final message = testStore2.state;      // Direct access
    
    return DCFText(content: 'Mixed Count: ${counter.state}, Mixed Message: $message');
  }
}

/// Component that switches patterns between renders (SHOULD trigger warnings)
class InconsistentComponent extends StatefulComponent {
  bool useHooks = true;
  
  @override
  DCFComponentNode render() {
    if (useHooks) {
      // First render: using hooks
      final counter = useStore(testStore1);
      return DCFText(content:'Hook Count: ${counter.state}');
    } else {
      // Later render: switching to direct access
      final count = testStore1.state;
      return DCFText(content:'Direct Count: $count');
    }
  }
  
  void togglePattern() {
    useHooks = !useHooks;
    // This will trigger a re-render and should show warning
  }
}

/// Component that properly updates stores
class UpdaterComponent extends StatefulComponent {
  @override
  DCFComponentNode render() {
    final counter = useStore(testStore1);
    final message = useStore(testStore2);
    
    return DCFView(
      children: [
        DCFText(content: 'Count: ${counter.state}'),
        DCFText(content: 'Message: ${message.state}'),
        
        // Button to increment counter using hooks (GOOD)
        DCFButton(
          buttonProps: ButtonProps(title: 'Increment (Hook)'),
          onPress: () {
            counter.setState(counter.state + 1);
          },
        ),
        
        // Button to update message using hooks (GOOD)
        DCFButton(
          buttonProps: ButtonProps(title: 'Update Message (Hook)'),
          onPress: () {
            message.setState('Updated at ${DateTime.now()}');
          },
        ),
        
        // Button that updates via direct access (creates mixed pattern warning)
        DCFButton(
          buttonProps: ButtonProps(title: 'Direct Update (BAD)'),
          onPress: () {
            testStore1.setState(testStore1.state + 10);  // Direct access
          },
        ),
      ],
    );
  }
}

/// Test app that demonstrates validation warnings
class ValidationTestApp extends StatefulComponent {
  
  @override
  DCFComponentNode render() {
    final modal = useState(false);
    return DCFView(
      layout: LayoutProps(flex: 1,padding: 50),
      children: [
        DCFText(content: 'Store Usage Validation Test'),
        DCFText(content: 'Check debug console for warnings'),
        
        // These should work fine
        GoodComponent(),
        DirectAccessComponent(),
        
        // These should trigger warnings
        BadMixedComponent(),
        InconsistentComponent(),
        
        // This demonstrates proper and improper updates
        UpdaterComponent(),
        
        // Reset button
        DCFButton(
          buttonProps: ButtonProps(title: 'Reset Store options'),
          onPress: () {
            modal.setState(true);
            testStore1.setState(0);
            testStore2.setState('reset');
          },
        ),
        DCFButton(buttonProps: ButtonProps(title: "Next Page"), onPress: () {
          pagestate.setState(1);
        }),
      ],
    );
  }
}
