import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';
import '../store/store.dart';

class TopBar extends StatefulComponent {
  @override
  DCFComponentNode render() {
    final notes = useStore(notesStore);
    
    return DCFView(
      layout: LayoutProps(
        height: 120,
        width: "100%",
        paddingTop: ScreenUtilities.instance.statusBarHeight,
        paddingHorizontal: 20,
        paddingVertical: 10,
        justifyContent: YogaJustifyContent.center,
        alignItems: YogaAlign.center,
        flexDirection: YogaFlexDirection.row,
      ),
      style: StyleSheet(
        backgroundColor: Colors.blue,
        shadowColor: Colors.blue.withOpacity(0.3),
        shadowRadius: 8,
        shadowOffsetY: 2,
      ),
      children: [
        DCFView(
          layout: LayoutProps(flex: 1),
          children: [
            DCFText(
              content: "DCFGo Notes",
              textProps: TextProps(
                fontSize: 24,
                fontWeight: "bold",
                color: Colors.white,
              ),
            ),
            DCFText(
              content: "${notes.state.length} ${notes.state.length == 1 ? 'note' : 'notes'}",
              textProps: TextProps(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
              layout: LayoutProps(marginTop: 2),
            ),
          ],
        ),
        DCFView(
          layout: LayoutProps(
            width: 40,
            height: 40,
            alignItems: YogaAlign.center,
            justifyContent: YogaJustifyContent.center,
          ),
          style: StyleSheet(
            backgroundColor: Colors.white.withOpacity(0.2),
            borderRadius: 20,
          ),
          children: [
            DCFIcon(
              iconProps: IconProps(
                name: DCFIcons.bookOpen,
                color: Colors.white,
              ),
              layout: LayoutProps(width: 20, height: 20),
            ),
          ],
        ),
      ],
    );
  }
}
