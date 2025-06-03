import 'dart:developer' as developer;

import 'package:dcflight/framework/renderer/vdom/vdom_node.dart';

import 'component.dart';

/// Component that catches errors in its subtree
abstract class ErrorBoundary extends StatefulComponent {
  ErrorBoundary({super.key});

  /// Current error state
  Object? _error;
  StackTrace? _stackTrace;
  bool _hasError = false;

  /// Handle error in child component
  void handleError(Object error, StackTrace stackTrace) {
    _error = error;
    _stackTrace = stackTrace;
    _hasError = true;

    // Log the error
    developer.log('Error caught by ErrorBoundary: $error',
        name: 'ErrorBoundary', error: error, stackTrace: stackTrace);

    // Trigger a re-render directly
    scheduleUpdate();
  }

  /// Reset error state
  void resetError() {
    _error = null;
    _stackTrace = null;
    _hasError = false;

    // Trigger a re-render directly
    scheduleUpdate();
  }

  /// Get whether there's an error
  bool get hasError => _hasError;

  /// Get current error
  Object? get error => _error;

  /// Get error stack trace
  StackTrace? get stackTrace => _stackTrace;

  /// Render fallback UI when error occurs
  VDomNode renderFallback(Object error, StackTrace? stackTrace);

  @override
  VDomNode render() {
    if (_hasError) {
      return renderFallback(_error!, _stackTrace);
    }

    return renderContent();
  }

  /// Render content when no error
  VDomNode renderContent();
}
