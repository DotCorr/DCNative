import 'package:dcf_go/app/store.dart';
import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';

class Footer extends StatefulComponent {
  @override
  DCFComponentNode render() {
    final globalCounter = useStore(globalCounterState);
    final tabIndex = useStore(tabIndexCount);

    return DCFView(
      style: StyleSheet(
        backgroundColor:
            globalCounter.state % 2 == 0 ? Colors.amber : Colors.teal,
      ),
      layout: LayoutProps(
        height: 100,
        marginVertical: 20,
        flexDirection: YogaFlexDirection.row,
      ),
      children: [
        _Container(
          tabIndex == 0,
          children: [
            DCFIcon(iconProps: IconProps(name: DCFIcons.house)),
            DCFView(
              style: StyleSheet(backgroundColor: Colors.red, borderRadius: 360),
              layout: LayoutProps(
                height: 15,
                width: 15,
                display: YogaDisplay.flex,
                position: YogaPositionType.absolute,
              ),
              children: [
                DCFText(
                  content: globalCounter.state.toString(),
                  textProps: TextProps(fontSize: 8),
                ),
              ],
            ),
          ],
        ),
        _Container(
          tabIndex == 1,
          children: [DCFIcon(iconProps: IconProps(name: DCFIcons.scan))],
        ),

        _Container(
          tabIndex == 3,
          children: [DCFIcon(iconProps: IconProps(name: DCFIcons.settings))],
        ),
      ],
    );
  }
}

class _Container extends StatelessComponent {
  final List<DCFComponentNode> children;
  final bool isSelected;

  _Container(this.isSelected, {required this.children});
  @override
  DCFComponentNode render() {
    return DCFView(
      layout: LayoutProps(
        height: 30,
        width: 30,
        alignContent: YogaAlign.center,
        justifyContent: YogaJustifyContent.center,
        display: YogaDisplay.flex,
        position: YogaPositionType.relative,
      ),
      style: StyleSheet(backgroundColor: Colors.grey[100]),
      children: children,
    );
  }
}
