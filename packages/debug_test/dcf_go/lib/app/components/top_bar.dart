import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';

class TopBar extends StatefulComponent {
  final StoreHook<int> globalCounter;
  final StateHook<int> counter;
  TopBar({super.key, required this.globalCounter, required this.counter});
  @override
  VDomNode render() {
    return DCFView(
      layout: LayoutProps(
        height: 100,
        flexDirection: YogaFlexDirection.row,
        flexWrap: YogaWrap.wrap,
        justifyContent: YogaJustifyContent.spaceBetween,
        alignItems: YogaAlign.center,
        alignContent: YogaAlign.center,
        paddingTop: ScreenUtilities.instance.statusBarHeight,
      ),
      style: StyleSheet(backgroundColor: Colors.blueAccent),
      children: [
        DCFText(
          content: "DCF Go",
          textProps: TextProps(
            fontSize: 20,
            fontWeight: 'bold',
            color: Colors.white,
          ),
        ),

        DCFView(
          layout: LayoutProps(
            flexDirection: YogaFlexDirection.row,
            justifyContent: YogaJustifyContent.spaceBetween,
            alignItems: YogaAlign.center,
            alignContent: YogaAlign.center,
            width: 100,
          ),
          children: [
            DCFIcon(
              iconProps: IconProps(name: DCFIcons.house, color: Colors.white),
              layout: LayoutProps(width: 20, height: 20),
            ),
            DCFText(
              content: counter.value.toString(),
              textProps: TextProps(
                fontSize: 12,
                fontWeight: 'bold',
                color: Colors.white,
              ),
            ),
          ],
        ),
        DCFView(
          layout: LayoutProps(
            flexDirection: YogaFlexDirection.row,
            justifyContent: YogaJustifyContent.spaceBetween,
            width: 100,
            alignItems: YogaAlign.center,
            alignContent: YogaAlign.center,
          ),
          children: [
            DCFIcon(
              iconProps: IconProps(name: DCFIcons.globe, color: Colors.white),
              layout: LayoutProps(width: 20, height: 20),
            ),
            DCFText(
              content: globalCounter.state.toString(),
              textProps: TextProps(
                fontSize: 12,
                fontWeight: 'bold',
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
