import 'package:dcflight/dcflight.dart';
import '../types/component_types.dart';

/// DCFDrawer - Cross-platform drawer navigation component
/// Provides native drawer functionality with type-safe positioning and animation
class DCFDrawer extends StatelessComponent {
  final bool open;
  final DrawerPosition position;
  final DrawerType drawerType;
  final double drawerWidth;
  final String? drawerBackgroundColor;
  final bool drawerLockMode;
  final bool gestureHandlerProps;
  final bool hideStatusBar;
  final bool keyboardDismissMode;
  final double minSwipeDistance;
  final double edgeWidth;
  final bool overlayColor;
  final bool scrimColor;
  final bool statusBarAnimation;
  final bool swipeEnabled;
  final double swipeVelocityThreshold;
  final void Function()? onDrawerOpen;
  final void Function()? onDrawerClose;
  final void Function(double)? onDrawerSlide;
  final void Function()? onDrawerStateChanged;
  final DCFElement? drawerContent;
  final List<DCFElement> children;

  DCFDrawer({
    super.key,
    this.open = false,
    this.position = DrawerPosition.left,
    this.drawerType = DrawerType.front,
    this.drawerWidth = 280.0,
    this.drawerBackgroundColor,
    this.drawerLockMode = false,
    this.gestureHandlerProps = true,
    this.hideStatusBar = false,
    this.keyboardDismissMode = true,
    this.minSwipeDistance = 60.0,
    this.edgeWidth = 20.0,
    this.overlayColor = true,
    this.scrimColor = true,
    this.statusBarAnimation = true,
    this.swipeEnabled = true,
    this.swipeVelocityThreshold = 2500.0,
    this.onDrawerOpen,
    this.onDrawerClose,
    this.onDrawerSlide,
    this.onDrawerStateChanged,
    this.drawerContent,
    this.children = const [],
  });

  @override
  DCFElement render() {
    final childElements = <DCFElement>[];
    if (drawerContent != null) childElements.add(drawerContent!);
    childElements.addAll(children);

    final events = <String, dynamic>{};
    if (onDrawerOpen != null) events['onDrawerOpen'] = onDrawerOpen;
    if (onDrawerClose != null) events['onDrawerClose'] = onDrawerClose;
    if (onDrawerSlide != null) events['onDrawerSlide'] = onDrawerSlide;
    if (onDrawerStateChanged != null) events['onDrawerStateChanged'] = onDrawerStateChanged;

    return DCFElement(
      type: 'Drawer',
      key: key,
      props: {
        'open': open,
        'position': position.name,
        'drawerType': drawerType.name,
        'drawerWidth': drawerWidth,
        'drawerBackgroundColor': drawerBackgroundColor,
        'drawerLockMode': drawerLockMode,
        'gestureHandlerProps': gestureHandlerProps,
        'hideStatusBar': hideStatusBar,
        'keyboardDismissMode': keyboardDismissMode,
        'minSwipeDistance': minSwipeDistance,
        'edgeWidth': edgeWidth,
        'overlayColor': overlayColor,
        'scrimColor': scrimColor,
        'statusBarAnimation': statusBarAnimation,
        'swipeEnabled': swipeEnabled,
        'swipeVelocityThreshold': swipeVelocityThreshold,
        ...events,
      },
      children: childElements,
    );
  }
}