import 'package:dcf_go/app/simple_app/app.dart';
import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';


class SampleModal extends StatelessComponent{

@override
render(){
  return  DCFModal(
          visible: modal.state,
          statusBarTranslucent: false,
          presentationStyle: ModalPresentationStyle.pageSheet,
          borderRadius: 100,
          header: ModalHeaderOptions(
            title: "Settings Modal",
            titleColor: Colors.orange,
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
            modal.setState(false);
          },
          onRightButtonPress: () {
            print("✅ Right button pressed - saving data");
            // You could save data here, then close
            modal.setState(false);
          },

          onDismiss: () {
            print("🔥 MODAL DISMISS CALLBACK CALLED!");
            modal.setState(false);
          },

          onRequestClose: () {
            print("🔒 Modal request close - closing modal");
            // modal.setState(false);
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
                    print("state: $v, index: $i");
                    return DCFTextInput(
                      style: StyleSheet(
                        borderColor: Colors.transparent,
                        borderWidth: 0,
                        backgroundColor: Colors.pink,
                      ),
                      value: textVal.state,
                      textColor: Colors.amber,
                      onFocus:
                          () =>
                              print("modal textinput focused ${textVal.state}"),
                      onBlur:
                          () =>
                              print("modal textinput blurred ${textVal.state}"),
                      onChangeText: (v) {
                        textVal.setState(v);
                        print("modal textinput changed $v");
                      },
                    );
                  },
                ),
                DCFText(content: "This is a modal"),
                DCFButton(
                  buttonProps: ButtonProps(title: "BG Color change"),
                  onPress: (v) {
                    bg.setState(Colors.amber);
                  },
                ),
                DCFButton(
                  buttonProps: ButtonProps(title: "Close"),
                  onPress: (v) {
                    modal.setState(false);
                  },
                ),
              ],
            ),
          ],
        );
}
}