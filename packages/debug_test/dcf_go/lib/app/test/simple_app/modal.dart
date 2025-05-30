import 'package:dcf_go/app/test/simple_app/app.dart';
import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';
import 'package:flutter/material.dart';

class SampleModal extends StatefulComponent {
 
  @override
  render() {
    // Use hooks consistently for ALL stores this component needs
    final modalStoreHook = useStore(modalStore);
    final textValStoreHook = useStore(textValStore);
    final bgStoreHook = useStore(bgStore);
    
    return DCFModal(
      visible: modalStoreHook.state,
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
        modalStoreHook.setState(false);
      },
      onRightButtonPress: () {
        print("✅ Right button pressed - saving data");
        // You could save data here, then close
        modalStoreHook.setState(false);
      },

      onDismiss: () {
        print("🔥 modalStore DISMISS CALLBACK CALLED!");
        modalStoreHook.setState(false);
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
                  value: textValStoreHook.state, // Use hook consistently
                  textColor: Colors.amber,
                  onFocus:
                      () => print("modalStore textinput focused ${textValStoreHook.state}"),
                  onBlur:
                      () => print("modalStore textinput blurred ${textValStoreHook.state}"),
                  onChangeText: (v) {
                    textValStoreHook.setState(v); // Use hook consistently
                    print("modalStore textinput changed $v");
                  },
                );
              },
            ),
            DCFText(content: "This is a modalStore"),
            DCFButton(
              buttonProps: ButtonProps(title: "BG Color change"),
              onPress: (v) {
                bgStoreHook.setState(Colors.amber); // Use hook consistently
              },
            ),
            DCFButton(
              buttonProps: ButtonProps(title: "Close"),
              onPress: (v) {
                modalStoreHook.setState(false); // Use hook consistently
              },
            ),
          ],
        ),
      ],
    );
  }
}
