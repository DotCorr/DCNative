import 'package:dcflight/dcflight.dart';
import '../types/component_types.dart';

/// DCFModal - Cross-platform modal presentation component
/// Provides native modal functionality with type-safe presentation styles
class DCFModal extends StatelessComponent {
  final bool visible;
  final ModalPresentationStyle presentationStyle;
  final ModalTransitionStyle transitionStyle;
  final bool animationType;
  final bool transparent;
  final bool statusBarTranslucent;
  final String? backgroundColor;
  final bool hardwareAccelerated;
  final void Function()? onShow;
  final void Function()? onDismiss;
  final void Function()? onRequestClose;
  final void Function()? onOrientationChange;
  final List<DCFComponentNode> children;

  /// Event handlers
  final Map<String, dynamic>? events;

  DCFModal({
    super.key,
    this.visible = false,
    this.presentationStyle = ModalPresentationStyle.automatic,
    this.transitionStyle = ModalTransitionStyle.coverVertical,
    this.animationType = true,
    this.transparent = false,
    this.statusBarTranslucent = false,
    this.backgroundColor,
    this.hardwareAccelerated = false,
    this.onShow,
    this.onDismiss,
    this.onRequestClose,
    this.onOrientationChange,
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

    return DCFElement(
      type: 'DCFModal',
      props: {
        'visible': visible,
        'presentationStyle': presentationStyle.name,
        'transitionStyle': transitionStyle.name,
        'animationType': animationType,
        'transparent': transparent,
        'statusBarTranslucent': statusBarTranslucent,
        if (backgroundColor != null) 'backgroundColor': backgroundColor,
        'hardwareAccelerated': hardwareAccelerated,
        ...eventMap,
      },
      children: children,
    );
  }
}
