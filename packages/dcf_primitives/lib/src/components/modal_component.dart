import 'package:dcf_primitives/src/components/view_component.dart';
import 'package:dcflight/dcflight.dart';
import '../types/component_types.dart';

/// DCFModal - Cross-platform modal presentation component
/// Provides native modal functionality with type-safe presentation styles
class DCFModal extends StatelessComponent {
  final bool visible;
  final StyleSheet? style;
  final ModalPresentationStyle presentationStyle;
  final ModalTransitionStyle transitionStyle;
  final bool animationType;
  final bool transparent;
  final bool statusBarTranslucent;
  final String? backgroundColor;
  final bool hardwareAccelerated;
  final double? borderRadius;
  final ModalHeaderOptions? header;
  final ModalSheetConfiguration? sheetConfiguration;
  final bool isDismissible;
  final void Function()? onShow;
  final void Function()? onDismiss;
  final void Function()? onRequestClose;
  final void Function()? onOrientationChange;
  final void Function()? onLeftButtonPress;
  final void Function()? onRightButtonPress;
  final List<DCFComponentNode> children;

  /// Event handlers
  final Map<String, dynamic>? events;

  DCFModal({
    super.key,
    this.visible = false,
    this.style,
    this.presentationStyle = ModalPresentationStyle.formSheet,
    this.transitionStyle = ModalTransitionStyle.coverVertical,
    this.animationType = true,
    this.transparent = false,
    this.statusBarTranslucent = false,
    this.backgroundColor,
    this.hardwareAccelerated = false,
    this.borderRadius,
    this.header,
    this.sheetConfiguration,
    this.isDismissible = true,
    this.onShow,
    this.onDismiss,
    this.onRequestClose,
    this.onOrientationChange,
    this.onLeftButtonPress,
    this.onRightButtonPress,
    this.children = const [],
    this.events,
  });

  @override
  DCFComponentNode render() {
    // Create an events map for callbacks
    Map<String, dynamic> eventMap = events ?? {};

    if (onShow != null) {
      eventMap['onShow'] = onShow;
    }

    if (onDismiss != null) {
      eventMap['onDismiss'] = onDismiss;
    }

    if (onRequestClose != null) {
      eventMap['onRequestClose'] = onRequestClose;
    }

    if (onOrientationChange != null) {
      eventMap['onOrientationChange'] = onOrientationChange;
    }

    if (onLeftButtonPress != null) {
      eventMap['onLeftButtonPress'] = onLeftButtonPress;
    }

    if (onRightButtonPress != null) {
      eventMap['onRightButtonPress'] = onRightButtonPress;
    }

    return DCFElement(
      type: 'Modal',
      props: {
        'visible': visible,
        'presentationStyle': presentationStyle.name,
        'transitionStyle': transitionStyle.name,
        'animationType': animationType,
        'transparent': transparent,
        'statusBarTranslucent': statusBarTranslucent,
        if (backgroundColor != null) 'backgroundColor': backgroundColor,
        'hardwareAccelerated': hardwareAccelerated,
        if (borderRadius != null) 'borderRadius': borderRadius,
        if (header != null) 'header': header!.toMap(),
        if (sheetConfiguration != null) 'sheetConfiguration': sheetConfiguration!.toMap(),
        'isDismissible': isDismissible,
        ...eventMap,
      },
      children: [
        DCFView(
          style: style ?? StyleSheet(),
          layout: LayoutProps(flex: 1, height: "100%", width: "100%"),
          children: children,
        )
      ],
    );
  }
}
