// Test for store usage validation system

import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/framework/renderer/vdom/component/component.dart';
import 'package:dcflight/framework/renderer/vdom/component/component_node.dart';
import 'package:dcflight/framework/renderer/vdom/component/store.dart';
import 'package:flutter/material.dart';

/// Global stores for testing
final testStore1 = Store<int>(0);
final testStore2 = Store<String>('initial');
final modalStore = Store<bool>(false);
final onboardingStore = Store<bool>(true);
final selectedTestStore = Store<String>('none');

/// Test items data store
final testItemsStore = Store<List<String>>([
  'Good Component Test',
  'Direct Access Test', 
  'Mixed Pattern Test',
  'Inconsistent Pattern Test',
  'Store Update Test',
  'Performance Test',
  'Error Handling Test',
  'Reactive Updates Test'
]);

/// Component that uses hooks correctly (should not trigger warnings)
class GoodComponent extends StatefulComponent {
  @override
  DCFComponentNode render() {
    // ✅ GOOD: Using hooks consistently
    final counter = useStore(testStore1);
    final message = useStore(testStore2);

    return DCFView(
      style: StyleSheet(
        backgroundColor: Colors.green.shade50,
        borderRadius: 8,
      ),
      layout: LayoutProps(padding: 16),
      children: [
        DCFText(
          content: '✅ Good Component',
          textProps: TextProps(
            fontSize: 16,
            fontWeight: 'bold',
            color: Colors.green.shade800,
          ),
        ),
        DCFText(
          content: 'Count: ${counter.state}, Message: ${message.state}',
        ),
      ],
    );
  }
}

/// Component that uses direct access correctly (should not trigger warnings)  
class DirectAccessComponent extends StatefulComponent {
  @override
  DCFComponentNode render() {
    // ✅ ACCEPTABLE: Using direct access consistently (but no reactive updates)
    final count = testStore1.state;
    final message = testStore2.state;

    return DCFView(
      style: StyleSheet(
        backgroundColor: Colors.blue.shade50,
        borderRadius: 8,
      ),
      layout: LayoutProps(padding: 16),
      children: [
        DCFText(
          content: '🔵 Direct Access Component',
          textProps: TextProps(
            fontSize: 16,
            fontWeight: 'bold',
            color: Colors.blue.shade800,
          ),
        ),
        DCFText(content: 'Direct Count: $count, Direct Message: $message'),
      ],
    );
  }
}

/// Component that mixes patterns (SHOULD trigger warnings)
class BadMixedComponent extends StatefulComponent {
  @override
  DCFComponentNode render() {
    // ❌ BAD: Mixing hooks and direct access
    final counter = useStore(testStore1); // Using hook
    final message = testStore2.state; // Direct access

    return DCFView(
      style: StyleSheet(
        backgroundColor: Colors.red.shade50,
        borderRadius: 8,
      ),
      layout: LayoutProps(padding: 16),
      children: [
        DCFText(
          content: '❌ Bad Mixed Component',
          textProps: TextProps(
            fontSize: 16,
            fontWeight: 'bold',
            color: Colors.red.shade800,
          ),
        ),
        DCFText(
          content: 'Mixed Count: ${counter.state}, Mixed Message: $message',
        ),
      ],
    );
  }
}

/// Component that switches patterns between renders (SHOULD trigger warnings)
class InconsistentComponent extends StatefulComponent {
  bool useHooks = true;

  @override
  DCFComponentNode render() {
    return DCFView(
      style: StyleSheet(
        backgroundColor: Colors.orange.shade50,
        borderRadius: 8,
      ),
      layout: LayoutProps(padding: 16),
      children: [
        DCFText(
          content: '⚠️ Inconsistent Component',
          textProps: TextProps(
            fontSize: 16,
            fontWeight: 'bold',
            color: Colors.orange.shade800,
          ),
        ),
        _buildPatternContent(),
        DCFButton(
          buttonProps: ButtonProps(
            title: 'Toggle Pattern',
            backgroundColor: Colors.orange,
          ),
          onPress: () {
            togglePattern();
          },
        ),
      ],
    );
  }

  DCFComponentNode _buildPatternContent() {
    if (useHooks) {
      // First render: using hooks
      final counter = useStore(testStore1);
      return DCFText(content: 'Hook Count: ${counter.state}');
    } else {
      // Later render: switching to direct access
      final count = testStore1.state;
      return DCFText(content: 'Direct Count: $count');
    }
  }

  void togglePattern() {
    useHooks = !useHooks;
    // This will trigger a re-render and should show warning
  }
}

/// Modal component to show test items
class TestItemsModal extends StatefulComponent {
  @override
  DCFComponentNode render() {
    final modalVisible = useStore(modalStore);
    final testItems = useStore(testItemsStore);
    final selectedTest = useStore(selectedTestStore);

    return DCFModal(
      visible: modalVisible.state,
      statusBarTranslucent: false,
      presentationStyle: ModalPresentationStyle.popover,
      borderRadius: 16,
      header: ModalHeaderOptions(
        title: "Available Tests",
        titleColor: Colors.black,
        fontSize: 20,
        fontWeight: "bold",
        leftButton: ModalHeaderButton(
          title: "Close",
          style: ModalHeaderButtonStyle.bordered,
          onPress: () => modalVisible.setState(false),
        ),
        rightButton: ModalHeaderButton(
          title: "Run Selected",
          style: ModalHeaderButtonStyle.bordered,
          onPress: () {
            _runSelectedTest(selectedTest.state);
            modalVisible.setState(false);
          },
        ),
      ),
      onDismiss: () {
        modalVisible.setState(false);
      },
      children: [
        DCFView(
          layout: LayoutProps(padding: 20),
          children: [
            DCFText(
              content: 'Select a test to run:',
              textProps: TextProps(
                fontSize: 16,
                fontWeight: 'w600',
              ),
              layout: LayoutProps(marginBottom: 16),
            ),
            ...testItems.state.map((item) => DCFButton(
              buttonProps: ButtonProps(
                title: item,
                backgroundColor: selectedTest.state == item 
                    ? Colors.blue 
                    : Colors.grey.shade200,
                color: selectedTest.state == item 
                    ? Colors.white 
                    : Colors.black,
              ),
              layout: LayoutProps(marginBottom: 8),
              onPress: () {
                selectedTest.setState(item);
              },
            )).toList(),
          ],
        ),
      ],
    );
  }

  void _runSelectedTest(String testName) {
    print('🧪 Running test: $testName');
    // Add test execution logic here
    switch (testName) {
      case 'Good Component Test':
        testStore1.setState(100);
        testStore2.setState('Good test completed');
        break;
      case 'Direct Access Test':
        testStore1.setState(200);
        testStore2.setState('Direct access test');
        break;
      case 'Mixed Pattern Test':
        testStore1.setState(300);
        testStore2.setState('Mixed pattern warning');
        break;
      default:
        testStore1.setState(0);
        testStore2.setState('Test: $testName');
    }
  }
}

/// Onboarding screen component
class OnboardingScreen extends StatefulComponent {
  @override
  DCFComponentNode render() {
    final onboarding = useStore(onboardingStore);
    
    if (!onboarding.state) return DCFView(children: []);

    return DCFView(
      style: StyleSheet(
        backgroundColor: Colors.white,
      ),
      layout: LayoutProps(
        padding: 24,
        flex: 1,
      ),
      children: [
        DCFText(
          content: '🚀 DCFlight Validation Test Suite',
          textProps: TextProps(
            fontSize: 28,
            fontWeight: 'bold',
            color: Colors.blue.shade800,
            textAlign: 'center',
          ),
          layout: LayoutProps(marginBottom: 24),
        ),
        DCFText(
          content: 'Welcome to the store usage validation system. This test suite demonstrates:',
          textProps: TextProps(
            fontSize: 16,
          ),
          layout: LayoutProps(marginBottom: 16),
        ),
        DCFView(
          layout: LayoutProps(marginBottom: 24),
          children: [
            _buildFeatureItem('✅', 'Proper store hook usage patterns'),
            _buildFeatureItem('🔵', 'Direct state access patterns'),
            _buildFeatureItem('❌', 'Mixed pattern warnings'),
            _buildFeatureItem('⚠️', 'Inconsistent pattern detection'),
            _buildFeatureItem('🧪', 'Interactive test scenarios'),
            _buildFeatureItem('📊', 'Real-time validation feedback'),
          ],
        ),
        DCFView(
          layout: LayoutProps(marginTop: 32),
          children: [
            DCFButton(
              buttonProps: ButtonProps(
                title: 'Start Testing',
                backgroundColor: Colors.blue,
                color: Colors.white,
              ),
              layout: LayoutProps(marginBottom: 12),
              onPress: () {
                onboarding.setState(false);
              },
            ),
            DCFButton(
              buttonProps: ButtonProps(
                title: 'View Test Items',
                backgroundColor: Colors.green,
                color: Colors.white,
              ),
              onPress: () {
                onboarding.setState(false);
                modalStore.setState(true);
              },
            ),
          ],
        ),
      ],
    );
  }

  DCFComponentNode _buildFeatureItem(String icon, String text) {
    return DCFView(
      layout: LayoutProps(
        marginBottom: 8,
      ),
      children: [
        DCFText(
          content: icon,
          textProps: TextProps(fontSize: 20),
          layout: LayoutProps(marginRight: 12),
        ),
        DCFText(
          content: text,
          textProps: TextProps(fontSize: 16),
        ),
      ],
    );
  }
}

/// Component that properly updates stores
class UpdaterComponent extends StatefulComponent {
  @override
  DCFComponentNode render() {
    final counter = useStore(testStore1);
    final message = useStore(testStore2);

    return DCFView(
      style: StyleSheet(
        backgroundColor: Colors.purple.shade50,
        borderRadius: 8,
      ),
      layout: LayoutProps(padding: 16),
      children: [
        DCFText(
          content: '🔄 Store Updater Component',
          textProps: TextProps(
            fontSize: 16,
            fontWeight: 'bold',
            color: Colors.purple.shade800,
          ),
          layout: LayoutProps(marginBottom: 12),
        ),
        DCFText(content: 'Count: ${counter.state}'),
        DCFText(content: 'Message: ${message.state}'),

        DCFView(
          layout: LayoutProps(marginTop: 12),
          children: [
            // Button to increment counter using hooks (GOOD)
            DCFButton(
              buttonProps: ButtonProps(
                title: 'Increment (Hook)',
                backgroundColor: Colors.green,
                color: Colors.white,
              ),
              layout: LayoutProps(marginBottom: 8),
              onPress: () {
                counter.setState(counter.state + 1);
              },
            ),

            // Button to update message using hooks (GOOD)
            DCFButton(
              buttonProps: ButtonProps(
                title: 'Update Message (Hook)',
                backgroundColor: Colors.blue,
                color: Colors.white,
              ),
              layout: LayoutProps(marginBottom: 8),
              onPress: () {
                message.setState('Updated at ${DateTime.now().toString().substring(11, 19)}');
              },
            ),

            // Button that updates via direct access (creates mixed pattern warning)
            DCFButton(
              buttonProps: ButtonProps(
                title: 'Direct Update (BAD)',
                backgroundColor: Colors.red,
                color: Colors.white,
              ),
              onPress: () {
                testStore1.setState(testStore1.state + 10); // Direct access
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Test app that demonstrates validation warnings
class ValidationTestApp extends StatefulComponent {
  @override
  DCFComponentNode render() {
    final onboarding = useStore(onboardingStore);
    
    // Show onboarding first
    if (onboarding.state) {
      return DCFView(
        children: [
          OnboardingScreen(),
        ],
      );
    }

    // Main test interface
    return DCFView(
      style: StyleSheet(
        backgroundColor: Colors.grey.shade50,
      ),
      layout: LayoutProps(padding: 16),
      children: [
        // Header
        DCFView(
          style: StyleSheet(
            backgroundColor: Colors.white,
            borderRadius: 12,
          ),
          layout: LayoutProps(
            padding: 16,
            marginBottom: 16,
          ),
          children: [
            DCFText(
              content: '🧪 Store Usage Validation Test',
              textProps: TextProps(
                fontSize: 24,
                fontWeight: 'bold',
                color: Colors.blue.shade800,
                textAlign: 'center',
              ),
              layout: LayoutProps(marginBottom: 8),
            ),
            DCFText(
              content: 'Monitor debug console for validation warnings',
              textProps: TextProps(
                fontSize: 14,
                color: Colors.grey.shade600,
                textAlign: 'center',
              ),
            ),
          ],
        ),

        // Control Panel
        DCFView(
          style: StyleSheet(
            backgroundColor: Colors.white,
            borderRadius: 12,
          ),
          layout: LayoutProps(
            padding: 16,
            marginBottom: 16,
          ),
          children: [
            DCFText(
              content: '🎛️ Control Panel',
              textProps: TextProps(
                fontSize: 18,
                fontWeight: 'bold',
              ),
              layout: LayoutProps(marginBottom: 12),
            ),
            DCFView(
              children: [
                DCFButton(
                  buttonProps: ButtonProps(
                    title: 'Show Test Items',
                    backgroundColor: Colors.blue,
                    color: Colors.white,
                  ),
                  onPress: () {
                    modalStore.setState(true);
                  },
                ),
                DCFButton(
                  buttonProps: ButtonProps(
                    title: 'Reset All',
                    backgroundColor: Colors.orange,
                    color: Colors.white,
                  ),
                  onPress: () {
                    testStore1.setState(0);
                    testStore2.setState('reset');
                    selectedTestStore.setState('none');
                  },
                ),
                DCFButton(
                  buttonProps: ButtonProps(
                    title: 'Show Onboarding',
                    backgroundColor: Colors.green,
                    color: Colors.white,
                  ),
                  onPress: () {
                    onboardingStore.setState(true);
                  },
                ),
              ],
            ),
          ],
        ),

        // Test Components
        DCFView(
          layout: LayoutProps(gap: 12),
          children: [
            // These should work fine
            GoodComponent(),
            DirectAccessComponent(),

            // These should trigger warnings
            BadMixedComponent(),
            InconsistentComponent(),

            // This demonstrates proper and improper updates
            UpdaterComponent(),
          ],
        ),

        // Modal
        TestItemsModal(),
      ],
    );
  }
}
