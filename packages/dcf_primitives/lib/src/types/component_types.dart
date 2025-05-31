// DCFlight Component Types
// Type-safe enums and classes for component properties


/// Alert action styles
enum DCFAlertActionStyle {
  defaultStyle,
  cancel,
  destructive,
}

/// Alert styles
enum DCFAlertStyle {
  alert,
  actionSheet,
}

/// Text input types
enum DCFTextInputType {
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
enum DCFKeyboardType {
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
enum DCFAutoCapitalizationType {
  none,
  words,
  sentences,
  allCharacters,
}

/// Return key types
enum DCFReturnKeyType {
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
enum DCFTextContentType {
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


/// Dropdown menu positions
enum DCFDropdownPosition {
  auto,
  top,
  bottom,
  left,
  right,
}

/// FlatList layout orientations
enum DCFListOrientation {
  vertical,
  horizontal,
}

/// FlatList scroll positions
enum DCFScrollPosition {
  start,
  center,
  end,
  nearest,
}

/// FlatList item separator positions
enum DCFSeparatorPosition {
  leading,
  trailing,
  both,
  none,
}

/// Image resize modes - type-safe options for image resizing
enum DCFImageResizeMode {
  cover,
  contain,
  stretch,
  repeat,
  center,
}

extension DCFImageResizeModeExtension on DCFImageResizeMode {
  String get name {
    switch (this) {
      case DCFImageResizeMode.cover:
        return 'cover';
      case DCFImageResizeMode.contain:
        return 'contain';
      case DCFImageResizeMode.stretch:
        return 'stretch';
      case DCFImageResizeMode.repeat:
        return 'repeat';
      case DCFImageResizeMode.center:
        return 'center';
    }
  }
}

/// Alert action configuration
class DCFAlertAction {
  final String title;
  final DCFAlertActionStyle style;
  final void Function()? onPressed;
  final bool enabled;

  const DCFAlertAction({
    required this.title,
    this.style = DCFAlertActionStyle.defaultStyle,
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


/// Dropdown menu item configuration
class DCFDropdownMenuItem {
  final String value;
  final String title;
  final String? subtitle;
  final String? icon;
  final bool disabled;
  final void Function(String value)? onSelected;

  const DCFDropdownMenuItem({
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
class DCFEdgeInsets {
  final double top;
  final double left;
  final double bottom;
  final double right;

  const DCFEdgeInsets.all(double value)
      : top = value,
        left = value,
        bottom = value,
        right = value;

  const DCFEdgeInsets.symmetric({
    double vertical = 0,
    double horizontal = 0,
  })  : top = vertical,
        bottom = vertical,
        left = horizontal,
        right = horizontal;

  const DCFEdgeInsets.only({
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
