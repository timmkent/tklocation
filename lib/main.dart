import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tklocation/tklocation.dart';

// Use case: Location cannot be retrieved because there is a network problem. OK

// Use case: Location service is disabled.
// Use case: Location cannot be retrieved but we can fall back to a last known location.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp();
  TKLocation.initialize(appShort: 'ca', tkuuid: "loeschmich", appVersion: "4711");
  TKLocation.enableDebugMode(true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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

  String lastResult = "";
  String latitude = "";
  String city = "";
  String country = "";
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () async {
                  final location = await TKLocation.getUserLocation();
                  setState(() {
                    latitude = location?.lat.toString() ?? "N/A";
                    lastResult = TKLocation.getLastResult();
                    city = TKLocation.getCity();
                    country = TKLocation.getCountry();
                  });
                },
                child: const Text("Get Location")),
            ElevatedButton(
                onPressed: () async {
                  try {
                    // Super wichtig, dass wir await haben, sonst wuerde catch NICHT greifen!
                    await Geolocator.requestPermission();
                  } catch (e) {
                    debugPrint(e.toString());
                  }
                },
                child: const Text("Request Permissions")),
            ElevatedButton(
                onPressed: () async {
                  try {
                    FirebaseAuth.instance.signInWithEmailAndPassword(email: 'dani@madetk.com', password: "willrein");
                  } catch (e) {
                    debugPrint(e.toString());
                  }
                },
                child: const Text("Authenticate user")),
            ElevatedButton(
                onPressed: () async {
                  try {
                    FirebaseAuth.instance.signOut();
                  } catch (e) {
                    debugPrint(e.toString());
                  }
                },
                child: const Text("Signout User")),
            const Text('Last Result:'),
            Text(latitude),
            Text("$city in $country"),
            Text(lastResult),
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
