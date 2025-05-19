import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';

class UserCard extends StatelessComponent {
  final Function onPress;

  UserCard({
    super.key,
    required this.onPress,

  });
  @override
  VDomNode render() {
    return DCFTouchableOpacity(
      activeOpacity: 0.5,
      onPress:onPress,
      layout: LayoutProps(
        height: 120,
        width: "100%",
        alignContent: YogaAlign.stretch,
        flexWrap: YogaWrap.nowrap,
        justifyContent: YogaJustifyContent.spaceAround,
      ),
      children: [
        DCFView(
          layout: LayoutProps(
            height: 120,
            width: "100%",
            alignContent: YogaAlign.stretch,
            flexWrap: YogaWrap.nowrap,
            flexDirection: YogaFlexDirection.row,
            justifyContent: YogaJustifyContent.spaceAround,
            alignItems: YogaAlign.center,
          ),
          style: StyleSheet(backgroundColor: Colors.grey[100]),
          children: [
            DCFImage(
              imageProps: ImageProps(
                resizeMode: "cover",
                source: "https://avatars.githubusercontent.com/u/130235676?v=4",
              ),
              layout: LayoutProps(height: 60, width: 60, borderWidth: 1),
              style: StyleSheet(borderRadius: 30, borderColor: Colors.black),
            ),
            DCFView(
              layout: LayoutProps(
                width: "60%",
                alignContent: YogaAlign.center,
                justifyContent: YogaJustifyContent.spaceAround,
              ),
              children: [
                DCFText(
                  content: "DCFight",
                  textProps: TextProps(fontSize: 20, fontWeight: 'bold'),
                ),
                DCFText(
                  content: "Deveolper lead",
                  textProps: TextProps(fontSize: 12, fontWeight: 'normal'),
                ),
                DCFIcon(
                  iconProps: IconProps(name: DCFIcons.github),
                  layout: LayoutProps(height: 20, width: 20),
                ),
              ],
            ),

            DCFIcon(
              iconProps: IconProps(name: DCFIcons.chevronRight),
              layout: LayoutProps(height: 20, width: 20),
            ),
          ],
        ),
      ],
    );
  }
}
