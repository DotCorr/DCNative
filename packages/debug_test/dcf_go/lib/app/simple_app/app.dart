import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';


class SimpleApp extends StatefulComponent{
  @override
  DCFComponentNode render() {
    final modal = useState(false);
    final textVal = useState("text");
    return DCFView(
      layout: LayoutProps(flex: 1,padding: 100),
      children: [
       
       
            DCFTextInput(
              value: textVal.value,
              onBlur: () => print("blurred ${textVal.value}"),
              onChangeText: (v) {
                textVal.setValue(v);
                print("changed $v");
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
                modal.setValue(true);
              },
            ),
            // Triggerbles
            DCFModal(visible: modal.value, onDismiss: () {
              modal.setValue(false);
            }, children: [
              DCFView(
                layout: LayoutProps(
                  width: "100%",
                  height: "100%",
                  padding: 100,
                  justifyContent: YogaJustifyContent.center,
                  alignItems: YogaAlign.center,
                ),
                style: StyleSheet(
                  backgroundColor: Colors.white,
                  borderRadius: 12,
                  shadowColor: Colors.black.withOpacity(0.1),
                  shadowRadius: 4,
                  shadowOffsetY: 2,
                ),
                children: [
                  DCFTextInput(
                    value: textVal.value,
                    onBlur: () => print("blurred ${textVal.value}"),
                    onChangeText: (v) {
                      textVal.setValue(v);
                      print("changed $v");
                    },
                  ),
                  DCFText(content: "This is a modal"),
                  DCFButton(
                    buttonProps: ButtonProps(title: "Close"),
                    onPress: (v) {
                      modal.setValue(false);
                    },
                  ),
                ],
              ),
            ]),
       
      ],
    );
  }
}