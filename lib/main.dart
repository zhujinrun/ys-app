import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 设置状态栏透明
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // 强制横屏
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YS App',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      home: const WebViewPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage>
    with AutomaticKeepAliveClientMixin {
  late WebViewController _webViewController;
  DateTime? _lastPressedTime;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInputDialog(context);
    });
  }

  void _showInputDialog(BuildContext context) {
    final urlController =
        TextEditingController(text: 'http://192.168.31.234:8080');
    showDialog(
      context: context,
      barrierDismissible: false, // 禁止点击外部关闭
      builder: (context) {
        return AlertDialog(
          title: const Text('请输入影视地址'),
          content: TextField(
            controller: urlController,
            // decoration: const InputDecoration(hintText: 'http://192.168.31.234:8080'),
            keyboardType: TextInputType.url,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Uri? validUri = Uri.tryParse(urlController.text.trim());
                if (validUri != null && validUri.hasScheme) {
                  _webViewController
                    ..setJavaScriptMode(JavaScriptMode.unrestricted)
                    ..loadRequest(validUri);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('输入格式错误，请重试')),
                  );
                }
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 调用 super.build(context) 以支持状态保持
    return PopScope(
      canPop: false, // 设置为 false，拦截返回手势
      onPopInvokedWithResult: (didPop, result) async {
        // 使用 onPopInvokedWithResult
        if (didPop) return; // 如果已经处理了返回，则直接返回
        final allowed = await _handlePop(); // 调用自定义的返回逻辑
        if (allowed && mounted) {
          SystemNavigator.pop(); // 退出程序
        }
      },
      child: Scaffold(
        body: WebViewWidget(controller: _webViewController),
      ),
    );
  }

  Future<bool> _handlePop() async {
    // 检查 WebView 是否可以返回上一个页面
    if (await _webViewController.canGoBack()) {
      _webViewController.goBack();
      return false; // 阻止默认的返回行为
    }
    if (_lastPressedTime == null ||
        DateTime.now().difference(_lastPressedTime!) >
            const Duration(seconds: 2)) {
      // 如果两次点击间隔超过 2 秒，则显示提示消息
      _lastPressedTime = DateTime.now();
      return false; // 阻止退出
    } else {
      // 如果两次点击间隔小于 2 秒，则退出应用
      return true; // 允许退出
    }
  }

  @override
  bool get wantKeepAlive => true; // 返回 true 以启用状态保持
}
