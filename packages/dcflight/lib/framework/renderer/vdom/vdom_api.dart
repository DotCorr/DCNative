import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:dcflight/framework/renderer/interface/interface.dart' show PlatformInterface;
import 'package:dcflight/framework/renderer/vdom/vdom_node.dart';
import 'package:dcflight/framework/renderer/vdom/vdom_element.dart';
import 'vdom.dart';

/// Main API for VDOM operations
/// This class provides a simplified interface to the VDOM implementation
class VDomAPI {
  /// Singleton instance
  static final VDomAPI _instance = VDomAPI._();
  static VDomAPI get instance => _instance;
  
  /// Internal VDOM implementation
  late final VDom _vdom;
  
  /// Ready completer
  final Completer<void> _readyCompleter = Completer<void>();
  
  /// Private constructor
  VDomAPI._() {
    // Will be initialized explicitly with init()
  }
  
  /// Initialize the VDOM API with a platform interface
  Future<void> init(PlatformInterface platformInterface) async {
    try {
      _vdom = VDom(platformInterface);
      await _vdom.isReady;
      _readyCompleter.complete();
    } catch (e) {
      _readyCompleter.completeError(e);
      rethrow;
    }
  }
  
  /// Future that completes when the VDOM is ready
  Future<void> get isReady => _readyCompleter.future;
  
  /// Create a root component
  Future<void> createRoot(VDomNode component) async {
    await isReady;
    return _vdom.createRoot(component);
  }
  
  /// Create an element
  VDomElement createElement(
    String type, {
    Map<String, dynamic>? props,
    List<VDomNode>? children,
    String? key,
  }) {
    return VDomElement(
      type: type,
      props: props ?? {},
      children: children ?? [],
      key: key,
    );
  }
  
  /// Calculate and apply layout
  Future<void> calculateLayout() async {
    await isReady;
    return _vdom.calculateAndApplyLayout();
  }
  
  /// Render a node to native UI
  Future<String?> renderToNative(VDomNode node,
      {String? parentViewId, int? index}) async {
    await isReady;
    return _vdom.renderToNative(node, parentViewId: parentViewId, index: index);
  }
  
  /// Log VDOM state for debugging
  void debugLog(String message) {
    if (kDebugMode) {
      print('VDOM: $message');
    }
  }
}
