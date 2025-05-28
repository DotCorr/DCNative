import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';

class ExampleApp extends StatefulComponent {
  @override
  DCFComponentNode render() {
  final infoModal = useState(false);
    return DCFScrollView(
      layout: LayoutProps(flex: 1),
      children: [
        DCFText(
          content: "Hello, DCF Go!",
          textProps: TextProps(
            fontSize: 24,
            fontWeight: 'bold',
            color: Colors.black,
          ),
        ),

        DCFButton(
          layout: LayoutProps(height: 50, width: 200),
          onPress: (context) {
            // Handle button press
infoModal.setValue(true);
            print("Button pressed!");
          },
          buttonProps: ButtonProps(title: "Show more info Modal"),
        ),
        DCFModal(
          visible: infoModal.value,
          children: [
            DCFView(
              layout: LayoutProps(
                height: 200,
                width: "90%",
                justifyContent: YogaJustifyContent.center,
                alignItems: YogaAlign.center,
              ),
              style: StyleSheet(
                backgroundColor: Colors.white,
                borderRadius: 10,
              ),
              children: [
                DCFText(
                  content: "This is a modal!",
                  textProps: TextProps(fontSize: 18, fontWeight: 'bold'),
                ),
                DCFButton(
                  buttonProps: ButtonProps(title: "Close"),
                  onPress: (context) {
                    infoModal.setValue(false);
                  },
                ),
              ],
            ),
          ]
        ),
      ],
    );
  }
}
