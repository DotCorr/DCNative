
# DCFlight
# 🚧 This CLI is Under Development

Its aim is to simplify cross-platform app development for personal future projects.

## ⚠️ Important Notice

Just move from experimental to modularization where the framework is now modularised into a package. Although cli is not complete to allow the app run independent from the flutter cli, with hot reload support etc, the main framework as a package is complete (More platforms can be ported over but fundamentally done)


## 📌 Key Points
DCFlight can be used in any flutter app to diverge from the flutter framework and render native UI. This involves extra work with no guarantee of hot relaod/ restart support or any dev tools. The DCFlight Cli is therefopre advised to be used.
It is almost impossible to decouple the Dart VM from Flutter. To work around this:

## 📝 Dart Example

```dart

void main() {
  DCFlight.start(app: DCFGo());
}

import 'package:dcf_go/app/components/footer.dart';
import 'package:dcf_go/app/components/user_card.dart';
import 'package:dcf_go/app/store.dart';
import 'package:dcf_go/app/components/top_bar.dart';
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
          style: StyleSheet(backgroundColor: Colors.white),
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
        GobalStateCounterComp(),
      ],
    );
  }
}
```


## ☕ Buy Me a Coffee  

> **Your support fuels the grind. Every contribution keeps this journey alive.**  

[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png)](https://coff.ee/squirelboy360)  

[**buy_me_a_coffee: https://coff.ee/squirelboy360**](https://coff.ee/squirelboy360)

