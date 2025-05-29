import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';

class SimpleApp extends StatefulComponent {
  @override
  DCFComponentNode render() {
    final modal = useState(false);
    final textVal = useState("text");
    final bg = useState(Colors.white);

    return DCFView(
      style: StyleSheet(backgroundColor: bg.value),
      layout: LayoutProps(flex: 1, padding: 100),
      children: [
        DCFTextInput(
          value: textVal.value,
          onFocus: () => print("focused ${textVal.value}"),
          onBlur: () => print("blurred ${textVal.value}"),
          onChangeText: (v) {
            textVal.setValue(v);
            print("changed $v");
          },
        ),
        DCFButton(
          buttonProps: ButtonProps(title: "Reset Color"),
          onPress: (v) {
            bg.setValue(Colors.white);
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
        DCFModal(
          visible: modal.value,
          statusBarTranslucent: false,
          presentationStyle: ModalPresentationStyle.formSheet,
          header: ModalHeaderOptions(
            title: "Settings Modal",
            titleColor: Colors.black,
            fontSize: 18,
            fontWeight: "bold",
            leftButton: ModalHeaderButton(
              title: "Cancel",
              style: ModalHeaderButtonStyle.bordered,
              onPress: () => print("Cancel button pressed"),
            ),
            rightButton: ModalHeaderButton(
              title: "Save",
              style: ModalHeaderButtonStyle.done,
              onPress: () => print("Save button pressed"),
            ),
            showCloseButton: false, // We have custom buttons
          ),
          onShow: () {
            print("🔥 MODAL SHOW CALLBACK CALLED!");
          },
          onLeftButtonPress: () {
            print("🔘 Left button pressed - closing modal");
            modal.setValue(false);
          },
          onRightButtonPress: () {
            print("✅ Right button pressed - saving data");
            // You could save data here, then close
            modal.setValue(false);
          },

          onDismiss: () {
            print("🔥 MODAL DISMISS CALLBACK CALLED!");
            modal.setValue(false);
          },

          onRequestClose: () {
            print("🔒 Modal request close - closing modal");
            // modal.setValue(false);
          },

          children: [
            DCFScrollView(
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
                DCFFlatList(
                  data: [
                    "Item 1",
                    "Item 2",
                    "Item 3",
                    "Item 4",
                    "Item 5",
                    "Item 6",
                    "Item 7",
                    "Item 8",
                    "Item 9",
                    "Item 10",
                  ],
                  renderItem: (v, i) {
                    print("value: $v, index: $i");
                    return DCFTextInput(
                      style: StyleSheet(
                        borderColor: Colors.transparent,
                        borderWidth: 0,
                        backgroundColor: Colors.pink,
                      ),
                      value: textVal.value,
                      onFocus:
                          () =>
                              print("modal textinput focused ${textVal.value}"),
                      onBlur:
                          () =>
                              print("modal textinput blurred ${textVal.value}"),
                      onChangeText: (v) {
                        textVal.setValue(v);
                        print("modal textinput changed $v");
                      },
                    );
                  },
                ),
                DCFText(content: "This is a modal"),
                DCFButton(
                  buttonProps: ButtonProps(title: "BG Color change"),
                  onPress: (v) {
                    bg.setValue(Colors.amber);
                  },
                ),
                DCFButton(
                  buttonProps: ButtonProps(title: "Close"),
                  onPress: (v) {
                    modal.setValue(false);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
