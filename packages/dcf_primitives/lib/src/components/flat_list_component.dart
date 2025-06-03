import 'package:dcflight/dcflight.dart';
import '../types/component_types.dart' as types;

/// DCFFlatList - High-performance list component inspired by FlashList
/// Provides ultra-fast scrolling with component recycling and smart rendering
class DCFFlatList<T> extends StatelessComponent {
  final List<T> data;
  final LayoutProps? layout;
  final DCFComponentNode Function(T item, int index) renderItem;
  final String Function(T item, int index)? getItemType;
  final double? estimatedItemSize;
  final types.ListItemConfig Function(T item, int index)? getItemLayout;
  final types.DCFListOrientation orientation;
  final bool inverted;
  final int? initialNumToRender;
  final double? maxToRenderPerBatch;
  final double? windowSize;
  final bool removeClippedSubviews;
  final bool showsVerticalScrollIndicator;
  final bool showsHorizontalScrollIndicator;
  final types.DCFEdgeInsets? contentInset;
  final bool bounces;
  final bool alwaysBounceVertical;
  final bool alwaysBounceHorizontal;
  final bool pagingEnabled;
  final double? snapToInterval;
  final bool snapToStart;
  final bool snapToEnd;
  final double? decelerationRate;
  final bool keyboardDismissMode;
  final bool keyboardShouldPersistTaps;
  final void Function(int index)? onViewableItemsChanged;
  final void Function()? onEndReached;
  final double? onEndReachedThreshold;
  final void Function()? onRefresh;
  final bool refreshing;
  final DCFComponentNode? refreshControl;
  final DCFComponentNode? header;
  final DCFComponentNode? footer;
  final DCFComponentNode? empty;
  final DCFComponentNode? separator;
  final DCFComponentNode Function(int index)? stickyHeaderIndices;
  final void Function(Map<String, dynamic>)? onScroll;
  final void Function()? onScrollBeginDrag;
  final void Function()? onScrollEndDrag;
  final void Function()? onMomentumScrollBegin;
  final void Function()? onMomentumScrollEnd;

  DCFFlatList({
    super.key,
    required this.data,
    this.layout = const LayoutProps(flex: 1),
    required this.renderItem,
    this.getItemType,
    this.estimatedItemSize,
    this.getItemLayout,
    this.orientation = types.DCFListOrientation.vertical,
    this.inverted = false,
    this.initialNumToRender = 10,
    this.maxToRenderPerBatch = 10,
    this.windowSize = 21,
    this.removeClippedSubviews = true,
    this.showsVerticalScrollIndicator = true,
    this.showsHorizontalScrollIndicator = true,
    this.contentInset,
    this.bounces = true,
    this.alwaysBounceVertical = false,
    this.alwaysBounceHorizontal = false,
    this.pagingEnabled = false,
    this.snapToInterval,
    this.snapToStart = false,
    this.snapToEnd = false,
    this.decelerationRate,
    this.keyboardDismissMode = false,
    this.keyboardShouldPersistTaps = false,
    this.onViewableItemsChanged,
    this.onEndReached,
    this.onEndReachedThreshold = 0.1,
    this.onRefresh,
    this.refreshing = false,
    this.refreshControl,
    this.header,
    this.footer,
    this.empty,
    this.separator,
    this.stickyHeaderIndices,
    this.onScroll,
    this.onScrollBeginDrag,
    this.onScrollEndDrag,
    this.onMomentumScrollBegin,
    this.onMomentumScrollEnd,
  });

  @override
  DCFComponentNode render() {
    return DCFElement(
      type: 'FlatList',
      key: key,
      props: {
        'data': data.length,
        ...layout?.toMap() ?? {},
        'orientation': orientation.name,
        'inverted': inverted,
        'initialNumToRender': initialNumToRender,
        'maxToRenderPerBatch': maxToRenderPerBatch,
        'windowSize': windowSize,
        'removeClippedSubviews': removeClippedSubviews,
        'showsVerticalScrollIndicator': showsVerticalScrollIndicator,
        'showsHorizontalScrollIndicator': showsHorizontalScrollIndicator,
        'contentInset': contentInset != null ? {
          'top': contentInset!.top,
          'left': contentInset!.left,
          'bottom': contentInset!.bottom,
          'right': contentInset!.right,
        } : null,
        'bounces': bounces,
        'alwaysBounceVertical': alwaysBounceVertical,
        'alwaysBounceHorizontal': alwaysBounceHorizontal,
        'pagingEnabled': pagingEnabled,
        'snapToInterval': snapToInterval,
        'snapToStart': snapToStart,
        'snapToEnd': snapToEnd,
        'decelerationRate': decelerationRate,
        'keyboardDismissMode': keyboardDismissMode,
        'keyboardShouldPersistTaps': keyboardShouldPersistTaps,
        'onEndReachedThreshold': onEndReachedThreshold,
        'refreshing': refreshing,
        'estimatedItemSize': estimatedItemSize,
        if (onViewableItemsChanged != null) 'onViewableItemsChanged': onViewableItemsChanged,
        if (onEndReached != null) 'onEndReached': onEndReached,
        if (onRefresh != null) 'onRefresh': onRefresh,
        if (onScroll != null) 'onScroll': onScroll,
        if (onScrollBeginDrag != null) 'onScrollBeginDrag': onScrollBeginDrag,
        if (onScrollEndDrag != null) 'onScrollEndDrag': onScrollEndDrag,
        if (onMomentumScrollBegin != null) 'onMomentumScrollBegin': onMomentumScrollBegin,
        if (onMomentumScrollEnd != null) 'onMomentumScrollEnd': onMomentumScrollEnd,
      },
      children: _buildListChildren(),
    );
  }

  List<DCFComponentNode> _buildListChildren() {
    final children = <DCFComponentNode>[];
    
    // Add header if provided
    if (header != null) {
      children.add(header!);
    }

    // Generate list items
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final itemElement = renderItem(item, i);
      children.add(itemElement);
      
      // Add separator after each item (except last one)
      if (separator != null && i < data.length - 1) {
        children.add(separator!);
      }
    }

    // Add footer if provided
    if (footer != null) {
      children.add(footer!);
    }

    // If no data and empty component provided
    if (data.isEmpty && empty != null) {
      children.clear();
      children.add(empty!);
    }

    return children;
  }
}