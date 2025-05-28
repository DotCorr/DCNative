import 'package:dcf_go/app/components/footer.dart';
import 'package:dcf_go/app/components/user_card.dart';
import 'package:dcf_go/app/store.dart';
import 'package:dcf_go/app/components/top_bar.dart';
import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';

class DCFGo extends StatefulComponent {
  @override
  DCFComponentNode render() {
    final globalCounter = useStore(globalCounterState);
    final counter = useState(0);
    return DCFView(
      layout: LayoutProps(flex: 1),
      children: [
        TopBar(globalCounter: globalCounter, counter: counter),
        DCFView(
          // showsScrollIndicator: true,
          style: StyleSheet(
            backgroundColor:
                counter.value % 2 == 0 ? Colors.amber : Colors.white,
          ),
          layout: LayoutProps(
            paddingHorizontal: 20,
            justifyContent: YogaJustifyContent.spaceBetween,
            flex: 1,
            width: "100%",
            flexDirection: YogaFlexDirection.column,
          ),
          // horizontal: false,onScroll: (v){
          //   print("scrolling: $v");
          // },
          children: [
            UserCard(
              onPress: () {
                print("touchable pressed, maybe state woud change");
                print("counter value: ${counter.value}");
                print("global counter value: ${globalCounter.state}");
                counter.setValue(counter.value + 1);
                globalCounter.setState(globalCounter.state + 1);
              },
            ),
            UserCard(
              onPress: () { 
                print("touchable pressed, maybe state woud change");
                print("counter value: ${counter.value}");
                print("global counter value: ${globalCounter.state}");
                counter.setValue(counter.value + 1);
                globalCounter.setState(globalCounter.state + 1);
              },
            ),
            UserCard(
              onPress: () {
                print("touchable pressed, maybe state woud change");
                print("counter value: ${counter.value}");
                print("global counter value: ${globalCounter.state}");
                counter.setValue(counter.value + 1);
                globalCounter.setState(globalCounter.state + 1);
              },
            ),
            UserCard(
              onPress: () {
                print("touchable pressed, maybe state woud change");
                print("counter value: ${counter.value}");
                print("global counter value: ${globalCounter.state}");
                counter.setValue(counter.value + 1);
                globalCounter.setState(globalCounter.state + 1);
              },
            ),
          ],
        ),
        Footer(),
      ],
    );
  }
}
