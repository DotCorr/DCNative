
import 'package:dcf_go/app/simple_app/modal.dart';
import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';



    final modal = Store<bool>(false);
    final textVal = Store<String>("text");
    final bg = Store<Color>(Colors.white);
class SimpleApp extends StatefulComponent {
  @override
  DCFComponentNode render() {


    return DCFView(
      style: StyleSheet(backgroundColor: bg.state),
      layout: LayoutProps(flex: 1, padding: 100),
      children: [
        DCFTextInput(
          value: textVal.state,
          textColor: Colors.teal,
          onFocus: () => print("focused ${textVal.state}"),
          onBlur: () => print("blurred ${textVal.state}"),
          onChangeText: (v) {
            textVal.setState(v);
            print("changed $v");
          },
        ),
        DCFButton(
          buttonProps: ButtonProps(title: "Reset Color"),
          onPress: (v) {
            bg.setState(Colors.white);
          },
        ),
        DCFButton(
          buttonProps: ButtonProps(title: "Scan"),
          onPress: (v) {
            print("scanned $v");
          },
        ),
        DCFButton(
          buttonProps: ButtonProps(title: "Open Modal"),
          onPress: (v) {
            modal.setState(true);
          },
        ),
        // Triggerbles
       SampleModal()
      ],
    );
  }
}
