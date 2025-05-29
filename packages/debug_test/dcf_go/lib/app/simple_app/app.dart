
import 'package:dcf_go/app/simple_app/modal.dart';
import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';



    final modalStore = Store<bool>(false);
    final textValStore = Store<String>("text");
    final bgStore = Store<Color>(Colors.white);
class SimpleApp extends StatefulComponent {
  @override
  DCFComponentNode render() {


    return DCFView(
      style: StyleSheet(backgroundColor: bgStore.state),
      layout: LayoutProps(flex: 1, padding: 100),
      children: [
        DCFTextInput(
          value: textValStore.state,
          textColor: Colors.teal,
          onFocus: () => print("focused ${textValStore.state}"),
          onBlur: () => print("blurred ${textValStore.state}"),
          onChangeText: (v) {
            textValStore.setState(v);
            print("changed $v");
          },
        ),
        DCFButton(
          buttonProps: ButtonProps(title: "Reset Color"),
          onPress: (v) {
            bgStore.setState(Colors.white);
          },
        ),
        DCFButton(
          buttonProps: ButtonProps(title: "Scan"),
          onPress: (v) {
            print("scanned $v");
          },
        ),
        DCFButton(
          buttonProps: ButtonProps(title: "Open modalStore"),
          onPress: (v) {
            modalStore.setState(true);
          },
        ),
        // Triggerbles
       SampleModal()
      ],
    );
  }
}
