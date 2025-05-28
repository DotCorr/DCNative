import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';

class UserCard extends StatelessComponent {
  final Function onPress;

  UserCard({
    super.key,
    required this.onPress,

  });
  @override
  DCFComponentNode render() {
    return DCFTouchableOpacity(
      activeOpacity: 0.5,
      onPress:onPress,
      layout: LayoutProps(
        marginBottom: 8,
        height: 120,
        width: "100%",
        flexWrap: YogaWrap.nowrap,
        justifyContent: YogaJustifyContent.spaceAround,
      ),
      children: [
        DCFView(
          layout: LayoutProps(
           flex: 1,
            alignContent: YogaAlign.stretch,
            flexWrap: YogaWrap.nowrap,
            flexDirection: YogaFlexDirection.row,
            justifyContent: YogaJustifyContent.spaceAround,
            alignItems: YogaAlign.center,
          ),
          style: StyleSheet(borderRadius: 15,backgroundColor: Colors.grey[300]),
          children: [
            DCFImage(
              imageProps: ImageProps(
                resizeMode: "cover",
                source: "https://avatars.githubusercontent.com/u/130235676?v=4",
              ),
              layout: LayoutProps(height: 60, width: 60, borderWidth: 10),
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
