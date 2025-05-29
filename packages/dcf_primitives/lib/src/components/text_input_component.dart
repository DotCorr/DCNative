import 'package:dcflight/dcflight.dart';
import '../types/component_types.dart' as types;

/// DCFTextInput - Cross-platform text input component
/// Provides native text input functionality with comprehensive type safety
class DCFTextInput extends StatelessComponent {
  final LayoutProps? layout;
  final StyleSheet? style;
  final String? value;
  final String? defaultValue;
  final String? placeholder;
  final String? placeholderTextColor;
  final types.TextInputType inputType;
  final types.KeyboardType keyboardType;
  final types.AutoCapitalizationType autoCapitalization;
  final types.ReturnKeyType returnKeyType;
  final types.TextContentType textContentType;
  final bool autoCorrect;
  final bool autoFocus;
  final bool blurOnSubmit;
  final bool caretHidden;
  final bool clearButtonMode;
  final bool clearTextOnFocus;
  final bool contextMenuHidden;
  final bool editable;
  final bool enablesReturnKeyAutomatically;
  final int? maxLength;
  final int? numberOfLines;
  final bool multiline;
  final bool secureTextEntry;
  final bool selectTextOnFocus;
  final String? selectionColor;
  final bool spellCheck;
  final String? textAlign;
  final Color? textColor;
  final String? fontSize;
  final String? fontWeight;
  final String? fontFamily;
  final void Function(String)? onChangeText;
  final void Function()? onFocus;
  final void Function()? onBlur;
  final void Function()? onSubmitEditing;
  final void Function()? onKeyPress;
  final void Function()? onSelectionChange;
  final void Function()? onEndEditing;
  
  DCFTextInput({
    super.key,
    this.style,
    this.layout = const LayoutProps( height: 50,width: 200),
    this.value,
    this.defaultValue,
    this.placeholder,
    this.placeholderTextColor,
    this.inputType = types.TextInputType.text,
    this.keyboardType = types.KeyboardType.defaultType,
    this.autoCapitalization = types.AutoCapitalizationType.sentences,
    this.returnKeyType = types.ReturnKeyType.defaultReturn,
    this.textContentType = types.TextContentType.none,
    this.autoCorrect = true,
    this.autoFocus = false,
    this.blurOnSubmit = true,
    this.caretHidden = false,
    this.clearButtonMode = false,
    this.clearTextOnFocus = false,
    this.contextMenuHidden = false,
    this.editable = true,
    this.enablesReturnKeyAutomatically = false,
    this.maxLength,
    this.numberOfLines = 1,
    this.multiline = false,
    this.secureTextEntry = false,
    this.selectTextOnFocus = false,
    this.selectionColor,
    this.spellCheck = true,
    this.textAlign,
    this.textColor,
    this.fontSize,
    this.fontWeight,
    this.fontFamily,
    this.onChangeText,
    this.onFocus,
    this.onBlur,
    this.onSubmitEditing,
    this.onKeyPress,
    this.onSelectionChange,
    this.onEndEditing,
  });

  @override
  DCFComponentNode render() {
    final events = <String, dynamic>{};
    if (onChangeText != null) events['onChangeText'] = onChangeText;
    if (onFocus != null) events['onFocus'] = onFocus;
    if (onBlur != null) events['onBlur'] = onBlur;
    if (onSubmitEditing != null) events['onSubmitEditing'] = onSubmitEditing;
    if (onKeyPress != null) events['onKeyPress'] = onKeyPress;
    if (onSelectionChange != null) events['onSelectionChange'] = onSelectionChange;
    if (onEndEditing != null) events['onEndEditing'] = onEndEditing;

    return DCFElement(
      type: 'TextInput',
      key: key,
      props: {
        'value': value,
        'defaultValue': defaultValue,
        'placeholder': placeholder,
        'placeholderTextColor': placeholderTextColor,
        'inputType': inputType.name,
        'keyboardType': keyboardType.name,
        'autoCapitalization': autoCapitalization.name,
        'returnKeyType': returnKeyType.name,
        'textContentType': textContentType.name,
        'autoCorrect': autoCorrect,
        'autoFocus': autoFocus,
        'blurOnSubmit': blurOnSubmit,
        'caretHidden': caretHidden,
        'clearButtonMode': clearButtonMode,
        'clearTextOnFocus': clearTextOnFocus,
        'contextMenuHidden': contextMenuHidden,
        'editable': editable,
        'enablesReturnKeyAutomatically': enablesReturnKeyAutomatically,
        'maxLength': maxLength,
        'numberOfLines': numberOfLines,
        'multiline': multiline,
        'secureTextEntry': secureTextEntry,
        'selectTextOnFocus': selectTextOnFocus,
        'selectionColor': selectionColor,
        'spellCheck': spellCheck,
        'textAlign': textAlign,
        'textColor': textColor,
        'fontSize': fontSize,
        'fontWeight': fontWeight,
        'fontFamily': fontFamily,
        ...layout?.toMap() ?? {},
        ...style?.toMap() ?? {},
        ...events,
      },
      children: [],
    );
  }
}