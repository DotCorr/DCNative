import 'package:dcf_go/app/simple_app/app.dart';
import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';
import 'package:flutter/material.dart';

class SampleModal extends StatelessComponent {
 
  @override
  render() { 
    return DCFModal(
      visible: modalStore.state,
      statusBarTranslucent: false,
      presentationStyle: ModalPresentationStyle.popover,
      borderRadius: 100,
      header: ModalHeaderOptions(
        title: "Settings modalStore",
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
          style: ModalHeaderButtonStyle.bordered,
          onPress: () => print("Save button pressed"),
        ),
     
      ),
      onShow: () {
        print("🔥 modalStore SHOW CALLBACK CALLED!");
      },
      onLeftButtonPress: () {
        print("🔘 Left button pressed - closing modalStore");
        modalStore.setState(false);
      },
      onRightButtonPress: () {
        print("✅ Right button pressed - saving data");
        // You could save data here, then close
        modalStore.setState(false);
      },

      onDismiss: () {
        print("🔥 modalStore DISMISS CALLBACK CALLED!");
        modalStore.setState(false);
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
                  value: textValStore.state,
                  textColor: Colors.amber,
                  onFocus:
                      () => print("modalStore textinput focused ${textValStore.state}"),
                  onBlur:
                      () => print("modalStore textinput blurred ${textValStore.state}"),
                  onChangeText: (v) {
                    textValStore.setState(v);
                    print("modalStore textinput changed $v");
                  },
                );
              },
            ),
            DCFText(content: "This is a modalStore"),
            DCFButton(
              buttonProps: ButtonProps(title: "BG Color change"),
              onPress: (v) {
                bgStore.setState(Colors.amber);
              },
            ),
            DCFButton(
              buttonProps: ButtonProps(title: "Close"),
              onPress: (v) {
                modalStore.setState(false);
              },
            ),
          ],
        ),
      ],
    );
  }
}
