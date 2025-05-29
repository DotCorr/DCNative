// DCFlight Component Types
// Type-safe enums and classes for component properties

/// Modal presentation styles
enum ModalPresentationStyle {
  automatic,
  fullScreen,
  pageSheet,
  formSheet,
  overFullScreen,
  overCurrentContext,
  popover,
  none,
}

/// Modal transition styles
enum ModalTransitionStyle {
  coverVertical,
  flipHorizontal,
  crossDissolve,
  partialCurl,
}

/// Alert action styles
enum AlertActionStyle {
  defaultStyle,
  cancel,
  destructive,
}

/// Alert styles
enum AlertStyle {
  alert,
  actionSheet,
}

/// Text input types
enum TextInputType {
  text,
  email,
  password,
  number,
  phone,
  url,
  search,
  multiline,
}

/// Keyboard types
enum KeyboardType {
  defaultType,
  asciiCapable,
  numbersAndPunctuation,
  numberPad,
  phonePad,
  namePhonePad,
  emailAddress,
  decimalPad,
  twitter,
  webSearch,
  asciiCapableNumberPad,
}

/// Auto-capitalization types
enum AutoCapitalizationType {
  none,
  words,
  sentences,
  allCharacters,
}

/// Return key types
enum ReturnKeyType {
  defaultReturn,
  go,
  google,
  join,
  next,
  route,
  search,
  send,
  yahoo,
  done,
  emergencyCall,
  continue_,
}

/// Text content types for autofill
enum TextContentType {
  none,
  addressCity,
  addressCityAndState,
  addressState,
  countryName,
  creditCardNumber,
  emailAddress,
  familyName,
  fullStreetAddress,
  givenName,
  jobTitle,
  location,
  middleName,
  name,
  namePrefix,
  nameSuffix,
  nickname,
  organizationName,
  postalCode,
  streetAddressLine1,
  streetAddressLine2,
  sublocality,
  telephoneNumber,
  url,
  username,
  password,
  newPassword,
  oneTimeCode,
}

/// Drawer positions
enum DrawerPosition {
  left,
  right,
}

/// Drawer types
enum DrawerType {
  front,
  back,
  slide,
}

/// Context menu preview types
enum ContextMenuPreviewType {
  none,
  default_,
  hapticFeedback,
}

/// Dropdown menu positions
enum DropdownPosition {
  auto,
  top,
  bottom,
  left,
  right,
}

/// FlatList layout orientations
enum ListOrientation {
  vertical,
  horizontal,
}

/// FlatList scroll positions
enum ScrollPosition {
  start,
  center,
  end,
  nearest,
}

/// FlatList item separator positions
enum SeparatorPosition {
  leading,
  trailing,
  both,
  none,
}

/// Image resize modes - type-safe options for image resizing
enum ImageResizeMode {
  cover,
  contain,
  stretch,
  repeat,
  center,
}

extension ImageResizeModeExtension on ImageResizeMode {
  String get name {
    switch (this) {
      case ImageResizeMode.cover:
        return 'cover';
      case ImageResizeMode.contain:
        return 'contain';
      case ImageResizeMode.stretch:
        return 'stretch';
      case ImageResizeMode.repeat:
        return 'repeat';
      case ImageResizeMode.center:
        return 'center';
    }
  }
}

/// Alert action configuration
class AlertAction {
  final String title;
  final AlertActionStyle style;
  final void Function()? onPressed;
  final bool enabled;

  const AlertAction({
    required this.title,
    this.style = AlertActionStyle.defaultStyle,
    this.onPressed,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'style': style.name,
      'enabled': enabled,
    };
  }
}

/// Context menu action configuration
class ContextMenuAction {
  final String title;
  final String? icon;
  final bool destructive;
  final bool disabled;
  final void Function()? onPressed;

  const ContextMenuAction({
    required this.title,
    this.icon,
    this.destructive = false,
    this.disabled = false,
    this.onPressed,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'icon': icon,
      'destructive': destructive,
      'disabled': disabled,
    };
  }
}

/// Dropdown menu item configuration
class DropdownMenuItem {
  final String value;
  final String title;
  final String? subtitle;
  final String? icon;
  final bool disabled;
  final void Function(String value)? onSelected;

  const DropdownMenuItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
    this.disabled = false,
    this.onSelected,
  });

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'title': title,
      'subtitle': subtitle,
      'icon': icon,
      'disabled': disabled,
    };
  }
}

/// List item render configuration for FlashList-style performance
class ListItemConfig {
  final String itemType;
  final double? estimatedHeight;
  final double? estimatedWidth;

  const ListItemConfig({
    required this.itemType,
    this.estimatedHeight,
    this.estimatedWidth,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemType': itemType,
      'estimatedHeight': estimatedHeight,
      'estimatedWidth': estimatedWidth,
    };
  }
}

/// Edge insets configuration
class EdgeInsets {
  final double top;
  final double left;
  final double bottom;
  final double right;

  const EdgeInsets.all(double value)
      : top = value,
        left = value,
        bottom = value,
        right = value;

  const EdgeInsets.symmetric({
    double vertical = 0,
    double horizontal = 0,
  })  : top = vertical,
        bottom = vertical,
        left = horizontal,
        right = horizontal;

  const EdgeInsets.only({
    this.top = 0,
    this.left = 0,
    this.bottom = 0,
    this.right = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'top': top,
      'left': left,
      'bottom': bottom,
      'right': right,
    };
  }
}
