import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';

class ExampleApp extends StatefulComponent {
  @override
  DCFComponentNode render() {
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

            print("Button pressed!");
          },
          buttonProps: ButtonProps(title: "Show more info Modal"),
        ),
        DCFModal(
          visible: true,
        ),
      ],
    );
  }
}
