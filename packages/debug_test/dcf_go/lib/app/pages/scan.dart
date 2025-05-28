import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';

class ScanPage extends StatelessComponent{
  @override
  DCFComponentNode render() {
   return DCFView(layout: LayoutProps(flex: 1),children: [
    DCFView(layout: LayoutProps(flex: 3),style: StyleSheet(backgroundColor: Colors.black)),
    DCFView(layout: LayoutProps(flex: 1),children: [
      DCFButton(buttonProps: ButtonProps(title: "Scan"),onPress: (v){
        print("scanned $v");
      })
    ])
   ]);
  }
}