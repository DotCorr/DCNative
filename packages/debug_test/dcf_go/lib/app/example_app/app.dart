import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';

class ExampleApp extends StatefulComponent{
  @override
  DCFComponentNode render() {
   return DCFScrollView(children: [
      DCFText(
        content: "Hello, DCF Go!",
        textProps: TextProps(
          fontSize: 24,
          fontWeight: 'bold',
          color: Colors.black,
        ),
      ),
      DCFButton(
       buttonProps: ButtonProps(title: "Show more info Modal")
      ),
    ],
    layout: LayoutProps(
      flexDirection: YogaFlexDirection.column,
      justifyContent: YogaJustifyContent.center,
      alignItems: YogaAlign.center,
      padding: 16,
    ),
   );
   
  }
  
}