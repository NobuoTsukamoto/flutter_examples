import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:count_demo/time_series_count.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

import 'count_charts.dart';
import 'custom_axis.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

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
  List<TimeSeriesCount> items = [];
  Uint8List _imageBytes = Uint8List(0);

  Future<void> _getLastImage() async {
    var imageResponse = await http.get(Uri.http('127.0.0.1:5000', 'last_image'));
    String imageBase64 = json.decode(imageResponse.body)['image'];
    _imageBytes = base64Decode(imageBase64);

    setState(() {
      _imageBytes = base64Decode(imageBase64);
    });
  }

  Future<void> _getHistory() async {
    var historyResponse = await http.get(Uri.http('127.0.0.1:5000', 'history'));
    setState(() {
      items = (json.decode(historyResponse.body) as List)
          .map((i) => TimeSeriesCount.fromJson(i)).cast<TimeSeriesCount>()
          .toList();
    });
  }

  @override
  void initState() {

    Timer.periodic(
      const Duration(seconds: 5),
          (Timer timer) {
        _getHistory();
        _getLastImage();

        setState(() {});
      },
    );

    super.initState();
  }

  Future<void> _incrementCounter() async {

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
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Row(
          children: <Widget>[
            Container(
                margin: const EdgeInsets.all(20),
                child: Image.memory(
                _imageBytes,
                gaplessPlayback: true,
                errorBuilder: (c, o, s) {
                  return const Icon(Icons.error, color: Colors.red);
                }
            )
            ),
            Expanded(child: SimpleTimeSeriesChart.withData(items))

          ],
        )
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        // child: SimpleTimeSeriesChart.withData(items),
        //child: CustomAxisTickFormatters.withSampleData(),
        //Image.memory(_imageBytes, gaplessPlayback: true, errorBuilder: (c, o, s) {
        //return const Icon(Icons.error, color: Colors.red);
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
