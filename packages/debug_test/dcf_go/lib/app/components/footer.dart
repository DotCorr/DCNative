import 'package:dcf_go/app/store.dart';
import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';

class GobalStateCounterComp extends StatefulComponent {
  @override
  VDomNode render() {
    final globalCounter = useStore(globalCounterState);
    return DCFView(
      style: StyleSheet(
        backgroundColor:   globalCounter.state % 2 == 0 ? Colors.amber :Colors.teal

      ),
      layout: LayoutProps(
        height: 100,
        marginVertical: 20,
        flexDirection: YogaFlexDirection.column,
      ),
      children: [
        DCFText(
          content: "State change for global ${globalCounter.state}",
          textProps: TextProps(fontSize: 20, fontWeight: 'normal')
        ),
        DCFButton(
          buttonProps: ButtonProps(
            title: "Increment Global",
            color: Colors.white,
            backgroundColor: Colors.blueAccent,
            disabled: false,
          ),
          onPress: () {
            globalCounter.setState(globalCounter.state + 1);
          },

      
        ),
      ],
    );
  }
}
