import 'package:dcf_go/app/dcfgo/components/bunch_cards.dart';
import 'package:dcf_go/app/dcfgo/components/footer.dart';
import 'package:dcf_go/app/dcfgo/pages/scan.dart';
import 'package:dcf_go/app/dcfgo/store.dart';
import 'package:dcf_go/app/dcfgo/components/top_bar.dart';
import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';

class DCFGo extends StatefulComponent {
  @override
  DCFComponentNode render() {
    final globalCounter = useStore(globalCounterState);
    final counter = useState(0);
    useEffect(() {
      return null;
    }, dependencies: []);
    return tabIndexCount.state == 0
        ? DCFView(
          layout: LayoutProps(flex: 1),
          children: [
            TopBar(globalCounter: globalCounter, counter: counter),
            DCFScrollView(
              showsScrollIndicator: true,
              scrollIndicatorColor: Colors.red,
              scrollIndicatorSize: 20,
              style: StyleSheet(
                // backgroundColor:
                //     counter.value % 2 == 0 ? Colors.amber : Colors.white,
              ),
              layout: LayoutProps(
                justifyContent: YogaJustifyContent.spaceAround,
                padding: 8,
                // gap: 10,
                flex: 1,
                width: "100%",
                flexDirection: YogaFlexDirection.column,
              ),

              onScroll: (v) {
                print("scrolling: $v");
              },
              children: [
                DCFScrollView(
                  onScrollBeginDrag: (v) {
                    print("scroll begin drag: $v");
                  },
                  onScrollEndDrag: (v) {
                    print("scroll end drag: $v");
                  },
                  onScrollEnd: (v) {
                    print("scroll end: $v");
                  },
                  showsScrollIndicator: true,
                  scrollIndicatorColor: Colors.green,
                  scrollIndicatorSize: 10,
                  horizontal: true,
                  children: bunchCards(),
                  
                  layout: LayoutProps(
                    flex: 2,
                    gap: 4,
                    flexDirection: YogaFlexDirection.row,
                  ),
                ),
                DCFScrollView(
                  layout: LayoutProps(flex: 6),
                  children: bunchCards(),
                ),
              ],
            ),
            Footer(),
            DCFTouchableOpacity(
              onPress: () {
                counter.setValue(counter.value + 1);
              },
              children: [
                DCFView(
                  layout: LayoutProps(
                    flex: 1,
                    alignItems: YogaAlign.center,
                    justifyContent: YogaJustifyContent.center,
                  ),
                  style: StyleSheet(
                    borderRadius: 20,
                    backgroundColor: Colors.blue,
                    shadowColor: Colors.black,
                    shadowRadius: 2,
                    shadowOffsetX: 2,
                  ),
                  children: [
                    DCFIcon(iconProps: IconProps(name: DCFIcons.plus)),
                  ],
                ),
              ],
              layout: LayoutProps(
                alignItems: YogaAlign.center,
                justifyContent: YogaJustifyContent.center,
                marginBottom: 80,
                marginRight: 10,
                height: 50,
                width: 50,
                position: YogaPositionType.absolute,
                bottom: 1,
                right: 1,
              ),
              style: StyleSheet(borderRadius: 20),
            ),
          ],
        )
        : ScanPage();
  }
}
