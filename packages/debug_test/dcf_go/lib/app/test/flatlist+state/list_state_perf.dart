import 'package:dcf_go/app/index.dart';
import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';

class ListStatePerf extends StatefulComponent {
  @override
  DCFComponentNode render() {
    final textInputState = useState("Initial Text Value");
    return DCFView(
      layout: LayoutProps(flex: 1),
      children: [
        DCFButton(
          buttonProps: ButtonProps(title: "Next Page"),
          onPress: () {
            pagestate.setState(1);
          },
        ),
        DCFFlatList(
          layout: LayoutProps(
            flex: 2,
            flexDirection: YogaFlexDirection.row,
            flexWrap: YogaWrap.wrap,
          ),
          onScroll: (p0) {
            print("onScroll: $p0");
          },
          onScrollBeginDrag: () {
            print("onScrollBeginDrag");
          },
          onScrollEndDrag: () {
            print("onScrollEndDrag");
          },
          onMomentumScrollBegin: () {
            print("onMomentumScrollBegin");
          },
          onMomentumScrollEnd: () {
            print("onMomentumScrollEnd");
          },
          initialNumToRender: 10,
          maxToRenderPerBatch: 10,
          getItemLayout:
              (item, index) => ListItemConfig(
                itemType: "item",
                estimatedHeight: 50,
                estimatedWidth: 100,
              ),
          estimatedItemSize: 50,
          getItemType: (item, index) => "item",
          orientation: DCFListOrientation.horizontal,
          removeClippedSubviews: true,
          showsVerticalScrollIndicator: true,
          showsHorizontalScrollIndicator: true,

          bounces: true,
          alwaysBounceVertical: false,
          refreshControl:
              textInputState.state.isEmpty
                  ? null
                  : DCFText(content: "Refresh Control"),
          refreshing: textInputState.state.isNotEmpty,
          pagingEnabled: true,
          separator: DCFView(
            layout: LayoutProps(height: 1, width: 1),
            style: StyleSheet(backgroundColor: Colors.grey),
          ),
          data: List<int>.generate(100, (i) => i + 1),
          renderItem: (v, i) {
            return DCFTextInput(
              layout: LayoutProps(height: 50, width: 100, margin: 5),
              style: StyleSheet(backgroundColor: Colors.amber),
              autoCorrect: false,
              textColor: Colors.black,
              selectionColor: Colors.teal,
              value: textInputState.state,
              onChangeText: (v) {
                textInputState.setState(v);
              },
              placeholder: "Update testStore2",
            );
          },
        ),
          DCFButton(buttonProps: ButtonProps(title: "Back"), onPress: () {
          pagestate.setState(0);
        }),
      ],
    );
  }
}
