# Phase: Validation phase 65% (everything is in the template until fully validated then modularised)
# DCNative (MAUI/Multi-platform App UI)

## Flutter Native Sucks but Native UI (in pure dart) + Flutter(Skia/impeller) = 🔥
## 🚧 This CLI is Under Development

Its aim is to simplify cross-platform app development for personal future projects.

## ⚠️ Important Notice

If you want to test it, do not use the CLI as it currently does nothing. However, you can run the example to see how it works. The example serves as an experimental implementation and will eventually be broken down, optimized, and integrated into the complete CLI.

## 📌 Key Points

### 1️⃣ Flutter Engine Usage (Current branch uses C header file to communicates between native and dart, no more abstaction for UI rendering, the Vdom uses direct native communication for UI CRUD i short)

Developers might notice that the framework is built on Flutter—but in actuality, it is not.  
It is almost impossible to decouple the Dart VM from Flutter. To work around this:

- The framework is built parallel to Flutter Engine and not on top(This means we get Dart VM and the rest is handled by the native layer instead of Platform Views or any flutter abstraction while your usual flutter engine runs parallel for the dart runtime as its needed to start the the communication with native side and if flutter View is needed to be spawned for canvas rendering.
- When abstracting the Flutter engine, I separate it into a dedicated package. Currenttly everything is handled as a package.
- This allows communication with the Flutter engine in headless mode, letting the native side handle rendering.

### 2️⃣ Current Syntax Needs Improvement 🤦‍♂️

The current syntax is not great, but I will abstract over it later.

## 📝 Dart Example

```dart

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  developer.log('Starting DCMAUI application', name: 'App');

  // Start performance monitoring
  PerformanceMonitor().startMonitoring();

  // Start the native UI application
  startNativeApp();
}

void startNativeApp() async {
  // Create VDOM instance
  final vdom = VDom();

  // Wait for the VDom to be ready
  await vdom.isReady;
  developer.log('VDom is ready', name: 'App');

  // Create our counter component
  final counterComponent = CounterComponent();

  // Create a component node
  final counterNode = vdom.createComponent(counterComponent);

  // Render the component to native UI
  final viewId =
      await vdom.renderToNative(counterNode, parentId: "root", index: 0);
  developer.log('Rendered counter component with ID: $viewId', name: 'App');

  developer.log('DCMAUI framework started in headless mode', name: 'App');
}

class CounterComponent extends StatefulComponent {
  VDomNode createBox(int index) {
    final hue = (index * 30) % 360;
    final color = HSVColor.fromAHSV(1.0, hue.toDouble(), 0.7, 0.9).toColor();

    return UI.View(
      props: ViewProps(
        width: 80,
        height: 80,
        backgroundColor: color,
        borderRadius: 8,
        margin: 8,
        alignItems: AlignItems.center,
        justifyContent: JustifyContent.center,
      ),
      children: [
        UI.Text(
          content: TextContent((index + 1).toString(),
              props: TextProps(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )),
        ),
      ],
    );
  }

  @override
  VDomNode render() {
    final itemCount = useState<int>(100);
    final boxes = List.generate(
      itemCount.value,
      (i) => createBox(i),
    );

    final counter = useState(0, 'counter');
    final bg =
        useState(Color(Colors.indigoAccent.toARGB32()), 'scrollViewBGColor');

    final borderBgs =
        useState(Color(Colors.indigoAccent.toARGB32()), 'scrollViewBGColor');
    // Use an effect to update the ScrollView background color every second
    useEffect(() {
      final rnd = math.Random();
      Color color() => Color(rnd.nextInt(0xffffffff));
      // Set up a timer to update the color every second
      final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // Update the background color
        bg.setValue(color());

        developer.log('Updated ScrollView background color to: $color',
            name: 'ColorAnimation');
      });

      // Clean up the timer when the component is unmounted
      return () {
        timer.cancel();
        developer.log('Canceled background color animation timer',
            name: 'ColorAnimation');
      };
    }, dependencies: []);

    useEffect(() {
      final rnd = math.Random();
      Color color() => Color(rnd.nextInt(0xffffffff));
      // Set up a timer to update the color every second
      final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // Update the background color
        borderBgs.setValue(color());
        counter.setValue(counter.value + 1);
        developer.log('Updated border color to: $color',
            name: 'ColorAnimation');
      });

      // Clean up the timer when the component is unmounted
      return () {
        timer.cancel();
        developer.log('Canceled background color animation timer',
            name: 'ColorAnimation');
      };
    }, dependencies: []);

    return UI.View(
        props: ViewProps(
            height: '100%',
            width: '100%',
            backgroundColor: Colors.yellow,
            padding: 30),
        children: [
          UI.ScrollView(
              props: ScrollViewProps(
                height: '95%',
                width: '100%',
                padding: 8,
                showsHorizontalScrollIndicator: true,
                backgroundColor: Colors.indigoAccent,
              ),
              children: [
                UI.Image(
                    props: ImageProps(
                  margin: 20,
                  resizeMode: ResizeMode.cover,
                  borderRadius: 20,
                  borderWidth: 10,
                  height: '50%',
                  width: '90%',
                  borderColor: borderBgs.value,
                  source:
                      'https://avatars.githubusercontent.com/u/205313423?s=400&u=2abecc79555be8a9b63ddd607489676ab93b2373&v=4',
                )),
                UI.View(
                    props: ViewProps(
                        padding: 2,
                        margin: 20,
                        borderRadius: 20,
                        borderWidth: 10,
                        width: '90%',
                        alignItems: AlignItems.center,
                        justifyContent: JustifyContent.center,
                        height: '20%',
                        backgroundColor: bg.value),
                    children: [
                      UI.View(
                          props: ViewProps(
                            alignItems: AlignItems.center,
                            justifyContent: JustifyContent.center,
                            borderRadius: 2,
                            borderColor: borderBgs.value,
                            borderWidth: 2,
                            height: '80%',
                            width: '100%',
                            shadowRadius: 2,
                            backgroundColor: Colors.green,
                          ),
                          children: [
                            UI.Text(
                              content: TextContent("Test App",
                                  props: TextProps(
                                    fontSize: 20,
                                    color: Colors.white,
                                    textAlign: TextAlign.center,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ),
                            UI.Text(
                              content: TextContent("Counter Value: ",
                                      props: TextProps(
                                        fontSize: 20,
                                        color: Colors.amber,
                                        textAlign: TextAlign.center,
                                        fontWeight: FontWeight.bold,
                                      ))
                                  .interpolate(counter.value,
                                      props: TextProps(
                                        fontSize: 20,
                                        color: Colors.red,
                                        textAlign: TextAlign.center,
                                        fontWeight: FontWeight.bold,
                                      ))
                                  .interpolate("  value"),
                            )
                          ]),
                    ]),
                UI.View(
                    props: ViewProps(
                        padding: 20,
                        margin: 20,
                        borderRadius: 20,
                        borderWidth: 10,
                        width: '90%',
                        alignItems: AlignItems.center,
                        justifyContent: JustifyContent.center,
                        height: '20%',
                        backgroundColor: bg.value),
                    children: [
                      UI.View(
                          props: ViewProps(
                            alignItems: AlignItems.center,
                            justifyContent: JustifyContent.center,
                            borderRadius: 2,
                            borderColor: borderBgs.value,
                            borderWidth: 10,
                            height: '80%',
                            width: '100%',
                            backgroundColor: Colors.green,
                          ),
                          children: [
                            UI.Text(
                              content: TextContent("Color Change ",
                                  props: TextProps(
                                    fontSize: 20,
                                    color: Colors.orange,
                                    textAlign: TextAlign.center,
                                    fontWeight: FontWeight.bold,
                                  )).interpolate(borderBgs.value),
                            ),
                            UI.View(
                                props: ViewProps(
                                  flexDirection: FlexDirection.row,
                                  justifyContent: JustifyContent.center,
                                ),
                                children: [
                                  UI.Text(
                                    content: TextContent("Counter Value: ",
                                        props: TextProps(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        )),
                                  ),
                                  UI.Text(
                                    content: TextContent("",
                                        props: TextProps(
                                          fontSize: 20,
                                          color: Color(0xFFFFBF00),
                                          fontWeight: FontWeight.bold,
                                        )).interpolate(counter.value),
                                  )
                                ])
                          ]),
                    ]),
                UI.ScrollView(
                    props: ScrollViewProps(
                        height: '70%',
                        width: '100%',
                        showsHorizontalScrollIndicator: true,
                        backgroundColor: borderBgs.value,
                        // Add flexDirection row to make flex wrap work horizontally
                        flexDirection: FlexDirection.row,
                        flexWrap: FlexWrap.wrap),
                    children: [
                      ...boxes,
                    ]),
              ]),
         
        ]);
  }
}
```


### 3️⃣ Initially Inspired by .NET MAUI and React

The architecture is loosely inspired by .NET MAUI, Flutter and React, but instead of .NET, Flutter serves as the toolset. The syntax has been made flutter-like for familiarity and has borrowed concepts like state hooks and vdom-like architecture.

### 4️⃣ Hot Reload/Restart Issues ⚡

- Hot Reload does not work yet ❌.
---

This project is still in early development, and many improvements will be made along the way.  
Contributions, suggestions, and feedback are always welcome! 🚀
