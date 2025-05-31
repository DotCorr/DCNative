import 'package:dcf_go/app/test/component+state/validation_test.dart';
import 'package:dcf_go/app/test/flatlist+state/list_state_perf.dart';
import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';

final pagestate = Store<int>(0);

class Index extends StatefulComponent {
  
  @override
  DCFComponentNode render() {
    final pagestateLocal = useStore(pagestate);
    return DCFView(
      layout: LayoutProps(flex: 1),
      children: [
        pagestateLocal.state == 0 ? ValidationTestApp() : ListStatePerf()
      ]
    );
  }
}
