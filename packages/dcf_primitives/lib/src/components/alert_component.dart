import 'package:dcflight/dcflight.dart';
import '../types/component_types.dart';

/// DCFAlert - Cross-platform alert dialog component
/// Provides native alert functionality with type-safe styling
class DCFAlert extends StatelessComponent {
  final String title;
  final String? message;
  final List<AlertAction> actions;
  final AlertStyle style;
  final void Function(AlertAction)? onAction;
  final void Function()? onDismiss;

  /// Event handlers
  final Map<String, dynamic>? events;

  DCFAlert({
    super.key,
    required this.title,
    this.message,
    this.actions = const [],
    this.style = AlertStyle.alert,
    this.onAction,
    this.onDismiss,
    this.events,
  });

  @override
  DCFComponentNode render() {
    // Create an events map for callbacks
    Map<String, dynamic> eventMap = events ?? {};
    
    if (onAction != null) {
      eventMap['onAction'] = onAction;
    }
    
    if (onDismiss != null) {
      eventMap['onDismiss'] = onDismiss;
    }

    return DCFElement(
      type: 'Alert',
      props: {
        'title': title,
        if (message != null) 'message': message,
        'actions': actions.map((action) => action.toMap()).toList(),
        'style': style.name,
        ...eventMap,
      },
      children: [],
    );
  }
}
