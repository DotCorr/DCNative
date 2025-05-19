import 'package:dcf_go/app/components/footer.dart';
import 'package:dcf_go/app/components/user_card.dart';
import 'package:dcf_go/app/store.dart';
import 'package:dcf_go/app/top_bar.dart';
import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';



class DCFGo extends StatefulComponent {
  @override
  VDomNode render() {
    final globalCounter = useStore(globalCounterState);
    final counter = useState(0);
    return Fragment(
      children: [
       TopBar(globalCounter: globalCounter, counter: counter),
        DCFScrollView(
          showsScrollIndicator: true,
          style: StyleSheet(backgroundColor: Colors.deepPurpleAccent),
          layout: LayoutProps(
            paddingHorizontal: 20,
            justifyContent: YogaJustifyContent.spaceBetween,
            flex: 1,
            width: "100%",
            flexDirection: YogaFlexDirection.column,
          ),
          children: [
            UserCard(
              onPress: () {
                print("touchable pressed, maybe state woud change");
                print("counter value: ${counter.value}");
                print("global counter value: ${globalCounter.state}");
                counter.setValue(counter.value + 1);
                globalCounter.setState(globalCounter.state + 1);
              },
            ), UserCard(
              onPress: () {
                print("touchable pressed, maybe state woud change");
                print("counter value: ${counter.value}");
                print("global counter value: ${globalCounter.state}");
                counter.setValue(counter.value + 1);
                globalCounter.setState(globalCounter.state + 1);
              },
            ), UserCard(
              onPress: () {
                print("touchable pressed, maybe state woud change");
                print("counter value: ${counter.value}");
                print("global counter value: ${globalCounter.state}");
                counter.setValue(counter.value + 1);
                globalCounter.setState(globalCounter.state + 1);
              },
            ), UserCard(
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
        Fragment(children: [GobalStateCounterComp()]),
      ],
    );
  }
}

