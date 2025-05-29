import 'package:dcflight/dcflight.dart';
import '../types/component_types.dart';

/// DCFContextMenu - Cross-platform context menu component
/// Provides native context menu functionality with haptic feedback and preview
class DCFContextMenu extends StatelessComponent {
  final List<ContextMenuAction> actions;
  final ContextMenuPreviewType previewType;
  final String? previewBackgroundColor;
  final double? previewBorderRadius;
  final bool disabled;
  final void Function(ContextMenuAction)? onPress;
  final void Function()? onCancel;
  final void Function()? onPreviewTap;
  final List<DCFComponentNode> children;

  DCFContextMenu({
    super.key,
    this.actions = const [],
    this.previewType = ContextMenuPreviewType.default_,
    this.previewBackgroundColor,
    this.previewBorderRadius,
    this.disabled = false,
    this.onPress,
    this.onCancel,
    this.onPreviewTap,
    this.children = const [],
  });

  @override
  DCFElement render() {
    return DCFElement(
      type: 'ContextMenu',
      key: key,
      props: {
        'actions': actions.map((action) => action.toMap()).toList(),
        'previewType': previewType.name,
        'previewBackgroundColor': previewBackgroundColor,
        'previewBorderRadius': previewBorderRadius,
        'disabled': disabled,
        if (onPress != null) 'onPress': onPress,
        if (onCancel != null) 'onCancel': onCancel,
        if (onPreviewTap != null) 'onPreviewTap': onPreviewTap,
      },
      children: children,
    );
  }
}
