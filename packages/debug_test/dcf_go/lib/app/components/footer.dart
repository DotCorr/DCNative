import 'package:dcf_go/app/store.dart';
import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';

class Footer extends StatefulComponent {
  @override
  DCFComponentNode render() {
    final globalCounter = useStore(globalCounterState);

    return DCFView(
      layout: LayoutProps(height: 100, width: "100%"),
      children: [
        DCFView(
          layout: LayoutProps(height: 1, width: '100%'),
          style: StyleSheet(backgroundColor: Colors.grey[200]),
        ),
        DCFView(
          layout: LayoutProps(
            height: "100%",
            width: "100%",
            justifyContent: YogaJustifyContent.spaceAround,
            alignItems: YogaAlign.center,
            flexDirection: YogaFlexDirection.row,
          ),
          children: [
            _Container(
             0,
              children: [
                DCFIcon(iconProps: IconProps(name: DCFIcons.house)),
                DCFView(
                  style: StyleSheet(
                    backgroundColor: Colors.red,
                    borderRadius: 10,
                  ),
                  layout: LayoutProps(
                    height: 22,
                    alignItems: YogaAlign.center,
                    justifyContent: YogaJustifyContent.center,
                    width: 22,
                    right: 5,
                    bottom: 5,
                    position: YogaPositionType.absolute,
                  ),
                  children: [
                    DCFText(
                      content: globalCounter.state.toString(),
                      layout: LayoutProps(width: 20),
                      textProps: TextProps(
                        numberOfLines: 1,
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: "bold",
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _Container(
              1,
              children: [DCFIcon(iconProps: IconProps(name: DCFIcons.scan))],
            ),

            _Container(
             2,
              children: [
                DCFIcon(iconProps: IconProps(name: DCFIcons.settings)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _Container extends StatelessComponent {
  final List<DCFComponentNode> children;
  final int index;

  _Container(this.index, {required this.children});
  @override
  DCFComponentNode render() {
    return DCFTouchableOpacity(
      onPress: (V) {
        print("pressed with values : $V");
        tabIndexCount.setState(index);
      },
      activeOpacity: 0.5,
      layout: LayoutProps(height: 50, width: 50),
      children: [
        DCFView(
          layout: LayoutProps(
            flex: 1,
            alignItems: YogaAlign.center,
            justifyContent: YogaJustifyContent.center,
            display: YogaDisplay.flex,
            position: YogaPositionType.relative,
          ),
          style: StyleSheet(
            backgroundColor:
                index == tabIndexCount.state
                    ? Colors.blueAccent
                    : Colors.grey[100],
            borderRadius: 15,
          ),
          children: children,
        ),
      ],
    );
  }
}
