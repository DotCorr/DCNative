import 'package:dcf_go/app/test/simple_app/modal.dart';
import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';

final modalStore = Store<bool>(false);
final textValStore = Store<String>("text");
final bgStore = Store<Color>(Colors.white);

class SimpleApp extends StatefulComponent {
  @override
  DCFComponentNode render() {
    // Use hooks for store access
    final textVal = useStore(textValStore);
    final bg = useStore(bgStore);
    final modal = useStore(modalStore);

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
          buttonProps: ButtonProps(title: "Open modalStore"),
          onPress: (v) {
            modal.setState(true);
          },
        ),
        // Triggerbles
        SampleModal(),
      ],
    );
  }
}





// import 'package:dcf_go/app/simple_app/modal.dart';
// import 'package:dcf_primitives/dcf_primitives.dart';
// import 'package:dcflight/dcflight.dart';




// class SimpleApp extends StatefulComponent {
//   @override
//   DCFComponentNode render() {

//     final modal = useState<bool>(false);
//     final textVal = useState<String>("text");
//     final bg = useState<Color>(Colors.white);
//     return DCFView(
//       style: StyleSheet(backgroundColor: bg.state),
//       layout: LayoutProps(flex: 1, padding: 100),
//       children: [
//         DCFTextInput(
//           value: textVal.state,
//           textColor: Colors.teal,
//           onFocus: () => print("focused ${textVal.state}"),
//           onBlur: () => print("blurred ${textVal.state}"),
//           onChangeText: (v) {
//             textVal.setState(v);
//             print("changed $v");
//           },
//         ),
//         DCFButton(
//           buttonProps: ButtonProps(title: "Reset Color"),
//           onPress: (v) {
//             bg.setState(Colors.white);
//           },
//         ),
//         DCFButton(
//           buttonProps: ButtonProps(title: "Scan"),
//           onPress: (v) {
//             print("scanned $v");
//           },
//         ),
//         DCFButton(
//           buttonProps: ButtonProps(title: "Open modalStore"),
//           onPress: (v) {
//             modal.setState(true);
//           },
//         ),
//         // Triggerbles
//       DCFModal(
//       visible: modal.state,
//       statusBarTranslucent: false,
//       presentationStyle: ModalPresentationStyle.popover,
//       borderRadius: 100,
//       header: ModalHeaderOptions(
//         title: "Settings Modal",
//         titleColor: Colors.black,
//         fontSize: 18,
//         fontWeight: "bold",
//         leftButton: ModalHeaderButton(
//           title: "Cancel",
//           style: ModalHeaderButtonStyle.bordered,
//           onPress: () => print("Cancel button pressed"),
//         ),
//         rightButton: ModalHeaderButton(
//           title: "Save",
//           style: ModalHeaderButtonStyle.bordered,
//           onPress: () => print("Save button pressed"),
//         ),
     
//       ),
//       onShow: () {
//         print("🔥 MODAL SHOW CALLBACK CALLED!");
//       },
//       onLeftButtonPress: () {
//         print("🔘 Left button pressed - closing modal");
//         modal.setState(false);
//       },
//       onRightButtonPress: () {
//         print("✅ Right button pressed - saving data");
//         // You could save data here, then close
//         modal.setState(false);
//       },

//       onDismiss: () {
//         print("🔥 MODAL DISMISS CALLBACK CALLED!");
//         modal.setState(false);
//       },


//       children: [
//         DCFScrollView(
//           layout: LayoutProps(
//             width: "100%",
//             height: "100%",
//             padding: 100,
//             justifyContent: YogaJustifyContent.center,
//             alignItems: YogaAlign.center,
//           ),
//           style: StyleSheet(
//             backgroundColor: Colors.white,
//             borderRadius: 12,
//             shadowColor: Colors.black.withOpacity(0.1),
//             shadowRadius: 4,
//             shadowOffsetY: 2,
//           ),
//           children: [
//             DCFFlatList(
//               data: [
//                 "Item 1",
//                 "Item 2",
//                 "Item 3",
//                 "Item 4",
//                 "Item 5",
//                 "Item 6",
//                 "Item 7",
//                 "Item 8",
//                 "Item 9",
//                 "Item 10",
//               ],
//               renderItem: (v, i) {
//                 print("state: $v, index: $i");
//                 return DCFTextInput(
//                   style: StyleSheet(
//                     borderColor: Colors.transparent,
//                     borderWidth: 0,
//                     backgroundColor: Colors.pink,
//                   ),
//                   value: textVal.state,
//                   textColor: Colors.amber,
//                   onFocus:
//                       () => print("modal textinput focused ${textVal.state}"),
//                   onBlur:
//                       () => print("modal textinput blurred ${textVal.state}"),
//                   onChangeText: (v) {
//                     textVal.setState(v);
//                     print("modal textinput changed $v");
//                   },
//                 );
//               },
//             ),
//             DCFText(content: "This is a modal"),
//             DCFButton(
//               buttonProps: ButtonProps(title: "BG Color change"),
//               onPress: (v) {
//                 bg.setState(Colors.amber);
//               },
//             ),
//             DCFButton(
//               buttonProps: ButtonProps(title: "Close"),
//               onPress: (v) {
//                 modal.setState(false);
//               },
//             ),
//           ],
//         ),
//       ],
//     )
//       ],
//     );
//   }
// }
