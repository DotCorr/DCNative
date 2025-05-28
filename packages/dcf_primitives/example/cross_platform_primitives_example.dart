// DCFlight Cross-Platform Primitives Example
// This example demonstrates all the new type-safe components

import 'package:dcflight/dcflight.dart';
import 'package:dcf_primitives/dcf_primitives.dart';

class CrossPlatformPrimitivesExample extends StatefulComponent {
  @override
  State<CrossPlatformPrimitivesExample> createState() => _CrossPlatformPrimitivesExampleState();
}

class _CrossPlatformPrimitivesExampleState extends State<CrossPlatformPrimitivesExample> {
  // Modal state
  bool _modalVisible = false;
  
  // Drawer state
  bool _drawerOpen = false;
  
  // Dropdown state
  String? _selectedValue;
  List<String> _multiSelectedValues = [];
  
  // TextInput state
  String _textInputValue = '';
  
  @override
  DCFComponentNode render() {
    return DCFView(
      layout: const LayoutProps(padding: 16),
      style: const StyleSheet(backgroundColor: Colors.white),
      children: [
        
        // Title
        DCFText(
          content: 'DCFlight Cross-Platform Primitives',
          textProps: const TextProps(
            fontSize: 24,
            fontWeight: 'bold',
            textAlign: 'center',
          ),
          layout: const LayoutProps(marginBottom: 24),
        ),
        
        // Alert Examples
        _buildAlertSection(),
        
        // Modal Examples
        _buildModalSection(),
        
        // TextInput Examples
        _buildTextInputSection(),
        
        // Drawer Examples
        _buildDrawerSection(),
        
        // Dropdown Examples
        _buildDropdownSection(),
        
        // Context Menu Examples
        _buildContextMenuSection(),
        
        // FlatList Examples
        _buildFlatListSection(),
        
      ],
    );
  }
  
  DCFComponentNode _buildAlertSection() {
    return DCFView(
      layout: const LayoutProps(marginBottom: 24),
      children: [
        DCFText(
          content: 'Alert Components',
          textProps: const TextProps(fontSize: 18, fontWeight: 'bold'),
          layout: const LayoutProps(marginBottom: 12),
        ),
        
        // Basic Alert
        DCFButton(
          buttonProps: const ButtonProps(
            title: 'Show Basic Alert',
            backgroundColor: Colors.blue,
            color: Colors.white,
          ),
          onPress: () {
            DCFAlert.show(
              title: 'Basic Alert',
              message: 'This is a basic alert message.',
              actions: [
                AlertAction(
                  text: 'OK',
                  style: AlertActionStyle.defaultStyle,
                  onPress: () => print('OK pressed'),
                ),
              ],
            );
          },
        ),
        
        const SizedBox(height: 8),
        
        // Confirmation Alert
        DCFButton(
          buttonProps: const ButtonProps(
            title: 'Show Confirmation',
            backgroundColor: Colors.orange,
            color: Colors.white,
          ),
          onPress: () {
            DCFAlert.showConfirm(
              title: 'Confirm Action',
              message: 'Are you sure you want to proceed?',
              onConfirm: () => print('Confirmed'),
              onCancel: () => print('Cancelled'),
            );
          },
        ),
        
        const SizedBox(height: 8),
        
        // Destructive Alert
        DCFButton(
          buttonProps: const ButtonProps(
            title: 'Show Destructive Alert',
            backgroundColor: Colors.red,
            color: Colors.white,
          ),
          onPress: () {
            DCFAlert.showDestructive(
              title: 'Delete Item',
              message: 'This action cannot be undone.',
              destructiveText: 'Delete',
              onDestructive: () => print('Item deleted'),
              onCancel: () => print('Delete cancelled'),
            );
          },
        ),
      ],
    );
  }
  
  DCFComponentNode _buildModalSection() {
    return DCFView(
      layout: const LayoutProps(marginBottom: 24),
      children: [
        DCFText(
          content: 'Modal Components',
          textProps: const TextProps(fontSize: 18, fontWeight: 'bold'),
          layout: const LayoutProps(marginBottom: 12),
        ),
        
        DCFButton(
          buttonProps: const ButtonProps(
            title: 'Show Modal',
            backgroundColor: Colors.purple,
            color: Colors.white,
          ),
          onPress: () {
            setState(() {
              _modalVisible = true;
            });
          },
        ),
        
        // Modal Component
        DCFModal(
          visible: _modalVisible,
          presentationStyle: ModalPresentationStyle.pageSheet,
          transitionStyle: ModalTransitionStyle.coverVertical,
          onRequestClose: () {
            setState(() {
              _modalVisible = false;
            });
          },
          children: [
            DCFView(
              layout: const LayoutProps(padding: 24),
              style: const StyleSheet(backgroundColor: Colors.white),
              children: [
                DCFText(
                  content: 'Modal Content',
                  textProps: const TextProps(fontSize: 20, fontWeight: 'bold'),
                  layout: const LayoutProps(marginBottom: 16),
                ),
                DCFText(
                  content: 'This is a modal with type-safe presentation styles.',
                  layout: const LayoutProps(marginBottom: 24),
                ),
                DCFButton(
                  buttonProps: const ButtonProps(
                    title: 'Close Modal',
                    backgroundColor: Colors.red,
                    color: Colors.white,
                  ),
                  onPress: () {
                    setState(() {
                      _modalVisible = false;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
  
  DCFComponentNode _buildTextInputSection() {
    return DCFView(
      layout: const LayoutProps(marginBottom: 24),
      children: [
        DCFText(
          content: 'TextInput Components',
          textProps: const TextProps(fontSize: 18, fontWeight: 'bold'),
          layout: const LayoutProps(marginBottom: 12),
        ),
        
        // Basic Text Input
        DCFTextInput(
          placeholder: 'Enter text here...',
          value: _textInputValue,
          inputType: TextInputType.text,
          keyboardType: KeyboardType.defaultType,
          autoCapitalization: AutoCapitalizationType.sentences,
          onChangeText: (text) {
            setState(() {
              _textInputValue = text;
            });
          },
          style: const DCFStyle(marginBottom: 12),
        ),
        
        // Email Input
        DCFTextInput(
          placeholder: 'Enter email...',
          inputType: TextInputType.email,
          keyboardType: KeyboardType.emailAddress,
          autoCapitalization: AutoCapitalizationType.none,
          style: const DCFStyle(marginBottom: 12),
        ),
        
        // Password Input
        DCFTextInput(
          placeholder: 'Enter password...',
          inputType: TextInputType.password,
          secureTextEntry: true,
          style: const DCFStyle(marginBottom: 12),
        ),
        
        // Multiline Input
        DCFTextInput(
          placeholder: 'Enter multiline text...',
          multiline: true,
          numberOfLines: 4,
          style: const DCFStyle(marginBottom: 12),
        ),
      ],
    );
  }
  
  DCFComponentNode _buildDrawerSection() {
    return DCFView(
      layout: const LayoutProps(marginBottom: 24),
      children: [
        DCFText(
          content: 'Drawer Components',
          textProps: const TextProps(fontSize: 18, fontWeight: 'bold'),
          layout: const LayoutProps(marginBottom: 12),
        ),
        
        DCFButton(
          buttonProps: const ButtonProps(
            title: 'Open Drawer',
            backgroundColor: Colors.green,
            color: Colors.white,
          ),
          onPress: () {
            setState(() {
              _drawerOpen = true;
            });
          },
        ),
        
        // Drawer Component
        DCFDrawer(
          open: _drawerOpen,
          position: DrawerPosition.left,
          drawerWidth: 280,
          swipeEnabled: true,
          onDrawerClose: () {
            setState(() {
              _drawerOpen = false;
            });
          },
          drawerContent: DCFView(
            layout: const LayoutProps(padding: 24),
            style: const StyleSheet(backgroundColor: Colors.grey.shade100),
            children: [
              DCFText(
                content: 'Drawer Menu',
                textProps: const TextProps(fontSize: 20, fontWeight: 'bold'),
                layout: const LayoutProps(marginBottom: 16),
              ),
              DCFText(
                content: 'This is the drawer content with type-safe positioning.',
                layout: const LayoutProps(marginBottom: 24),
              ),
              DCFButton(
                buttonProps: const ButtonProps(
                  title: 'Close Drawer',
                  backgroundColor: Colors.red,
                  color: Colors.white,
                ),
                onPress: () {
                  setState(() {
                    _drawerOpen = false;
                  });
                },
              ),
            ],
          ),
          children: [],
        ),
      ],
    );
  }
  
  DCFComponentNode _buildDropdownSection() {
    return DCFView(
      layout: const LayoutProps(marginBottom: 24),
      children: [
        DCFText(
          content: 'Dropdown Components',
          textProps: const TextProps(fontSize: 18, fontWeight: 'bold'),
          layout: const LayoutProps(marginBottom: 12),
        ),
        
        // Single Select Dropdown
        DCFDropdown(
          items: [
            DropdownMenuItem(value: 'option1', label: 'Option 1'),
            DropdownMenuItem(value: 'option2', label: 'Option 2'),
            DropdownMenuItem(value: 'option3', label: 'Option 3'),
          ],
          selectedValue: _selectedValue,
          placeholder: 'Select an option...',
          dropdownPosition: DropdownPosition.bottom,
          onValueChange: (value, item) {
            setState(() {
              _selectedValue = value;
            });
          },
          style: const DCFStyle(marginBottom: 12),
        ),
        
        // Multi Select Dropdown
        DCFDropdown(
          items: [
            DropdownMenuItem(value: 'multi1', label: 'Multi Option 1'),
            DropdownMenuItem(value: 'multi2', label: 'Multi Option 2'),
            DropdownMenuItem(value: 'multi3', label: 'Multi Option 3'),
          ],
          multiSelect: true,
          selectedValues: _multiSelectedValues,
          placeholder: 'Select multiple options...',
          onMultiValueChange: (values, items) {
            setState(() {
              _multiSelectedValues = values;
            });
          },
          style: const DCFStyle(marginBottom: 12),
        ),
      ],
    );
  }
  
  DCFComponentNode _buildContextMenuSection() {
    return DCFView(
      layout: const LayoutProps(marginBottom: 24),
      children: [
        DCFText(
          content: 'Context Menu Components',
          textProps: const TextProps(fontSize: 18, fontWeight: 'bold'),
          layout: const LayoutProps(marginBottom: 12),
        ),
        
        DCFContextMenu(
          actions: [
            ContextMenuAction(
              title: 'Copy',
              systemIcon: 'doc.on.doc',
              onPress: () => print('Copy pressed'),
            ),
            ContextMenuAction(
              title: 'Share',
              systemIcon: 'square.and.arrow.up',
              onPress: () => print('Share pressed'),
            ),
            ContextMenuAction(
              title: 'Delete',
              systemIcon: 'trash',
              destructive: true,
              onPress: () => print('Delete pressed'),
            ),
          ],
          previewType: ContextMenuPreviewType.default_,
          children: [
            DCFView(
              layout: const LayoutProps(padding: 16),
              style: const StyleSheet(
                backgroundColor: Colors.blue.shade100,
                borderRadius: 8,
              ),
              children: [
                DCFText(
                  content: 'Long press for context menu',
                  textProps: const TextProps(textAlign: 'center'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
  
  DCFComponentNode _buildFlatListSection() {
    return DCFView(
      layout: const LayoutProps(marginBottom: 24),
      children: [
        DCFText(
          content: 'High-Performance FlatList',
          textProps: const TextProps(fontSize: 18, fontWeight: 'bold'),
          layout: const LayoutProps(marginBottom: 12),
        ),
        
        // High-performance list with FlashList optimizations
        DCFFlatList(
          data: List.generate(100, (index) => 'Item $index'),
          orientation: ListOrientation.vertical,
          estimatedItemSize: 60,
          initialNumToRender: 10,
          maxToRenderPerBatch: 10,
          windowSize: 21,
          removeClippedSubviews: true,
          onViewableItemsChanged: (viewableItems) {
            print('Viewable items: $viewableItems');
          },
          onEndReached: () {
            print('End reached - load more data');
          },
          onEndReachedThreshold: 0.1,
          style: const DCFStyle(height: 300),
        ),
      ],
    );
  }
}

// Example usage in a DCFlight app
class ExampleApp extends StatelessComponent {
  @override
  DCFComponentNode render() {
    return DCFApp(
      home: CrossPlatformPrimitivesExample(),
    );
  }
}

void main() {
  runApp(ExampleApp());
}
