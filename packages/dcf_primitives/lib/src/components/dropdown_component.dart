import 'package:dcflight/dcflight.dart';
import '../types/component_types.dart';

/// DCFDropdown - Cross-platform dropdown menu component
/// Provides native dropdown functionality with type-safe positioning and items
class DCFDropdown extends StatelessComponent {
  final bool visible;
  final List<DCFDropdownMenuItem> items;
  final String? selectedValue;
  final String? placeholder;
  final String? placeholderTextColor;
  final DropdownPosition dropdownPosition;
  final double? maxHeight;
  final double? itemHeight;
  final String? backgroundColor;
  final String? borderColor;
  final double? borderWidth;
  final double? borderRadius;
  final bool searchable;
  final String? searchPlaceholder;
  final bool multiSelect;
  final List<String>? selectedValues;
  final bool disabled;
  final void Function(String, DCFDropdownMenuItem)? onValueChange;
  final void Function(List<String>, List<DCFDropdownMenuItem>)? onMultiValueChange;
  final void Function()? onOpen;
  final void Function()? onClose;

  DCFDropdown({
    super.key,
    this.visible = false,
    this.items = const [],
    this.selectedValue,
    this.placeholder,
    this.placeholderTextColor,
    this.dropdownPosition = DropdownPosition.auto,
    this.maxHeight,
    this.itemHeight,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.searchable = false,
    this.searchPlaceholder,
    this.multiSelect = false,
    this.selectedValues,
    this.disabled = false,
    this.onValueChange,
    this.onMultiValueChange,
    this.onOpen,
    this.onClose,
  });

  @override
  DCFComponentNode render() {
    return DCFElement(
      type: 'Dropdown',
      key: key,
      props: {
        'visible': visible,
        'items': items.map((item) => {
          'value': item.value,
          'label': item.title,  // Use title as label for native
          'disabled': item.disabled,
        }).toList(),
        'selectedValue': selectedValue,
        'placeholder': placeholder,
        'placeholderTextColor': placeholderTextColor,
        'dropdownPosition': dropdownPosition.name,
        'maxHeight': maxHeight,
        'itemHeight': itemHeight,
        'backgroundColor': backgroundColor,
        'borderColor': borderColor,
        'borderWidth': borderWidth,
        'borderRadius': borderRadius,
        'searchable': searchable,
        'searchPlaceholder': searchPlaceholder,
        'multiSelect': multiSelect,
        'selectedValues': selectedValues,
        'disabled': disabled,
        if (onValueChange != null) 'onValueChange': onValueChange,
        if (onMultiValueChange != null) 'onMultiValueChange': onMultiValueChange,
        if (onOpen != null) 'onOpen': onOpen,
        if (onClose != null) 'onClose': onClose,
      },
      children: [],
    );
  }
}