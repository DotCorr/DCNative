import 'dart:async';

import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';

class ExampleApp extends StatefulComponent {
  @override
  DCFComponentNode render() {
    final infoModal = useState(false);
    final alert = useState(false);
    final contextMenu = useState(false);
    final textInput = useState("Search");
    final dropdownValue = useState("Option 1");

    useEffect(() {
      // This effect runs once when the component is mounted
      Timer(Duration(seconds: 2), () {
        // After 2 seconds, we can show the alert
        infoModal.setValue(!infoModal.value);
        print("ExampleApp mounted and alert set to true");
      });
      return () {
        // This cleanup function runs when the component is unmounted
        print("ExampleApp unmounted");
      };
    }, dependencies: []);

    return DCFView(
      layout: LayoutProps(
        flex: 1,
        flexDirection: YogaFlexDirection.column,
        justifyContent: YogaJustifyContent.flexStart,
        alignItems: YogaAlign.stretch,
        padding: 100,
      ),
      children: [
        DCFModal(
          visible: infoModal.value,
          children: [
            DCFView(
              layout: LayoutProps(
                flex: 1,
                padding: 100,
                justifyContent: YogaJustifyContent.center,
                alignItems: YogaAlign.center,
              ),
              children: [
                DCFText(
                  content: "This is a modal",
                  textProps: TextProps(fontSize: 20, fontWeight: 'bold'),
                ),
                DCFButton(
                  buttonProps: ButtonProps(title: "Close Modal"),
                  onPress: (v) {
                    infoModal.setValue(false);
                    print("Modal closed");
                  },
                ),
              ],
            ),
          ],
          statusBarTranslucent: true,
          onDismiss: () {
            infoModal.setValue(!infoModal.value);
            print("dismissed modal");

            alert.setValue(true);
          },
        ),

        DCFTextInput(
          style: StyleSheet(backgroundColor: Colors.pink),
          value: "Search",
          onChangeText: (v) {
            print("Text input changed: $v");
          },
        ),
        DCFButton(
          buttonProps: ButtonProps(title: "Show Alert"),
          onPress: (v) {
            alert.setValue(!alert.value);
            print("Alert button pressed, alert set to ${alert.value}");
          },
        ),
        DCFButton(
          buttonProps: ButtonProps(title: "Show Modal"),
          onPress: (v) {
            alert.setValue(!infoModal.value);
            print("Modal button pressed, alert set to ${alert.value}");
          },
        ),

        DCFAlert(title: "Alert",
          message: "This is an alert message",
          // visible: alert.value,
          onDismiss: () {
            alert.setValue(false);
            print("Alert dismissed");
          },
        ),

        DCFButton(
          buttonProps: ButtonProps(title: "Show Conntext Menu"),
          onPress: (v) {
            contextMenu.setValue(!infoModal.value);
          },
        ),
      ],
    );
  }
}
