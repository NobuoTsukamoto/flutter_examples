import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_detection_elinux/detectionResult.dart';

import 'camera_view_singleton.dart';
import 'detector.dart';
import 'isolate_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: CameraPreviewScreen(
        camera: firstCamera,
        title: "Flutter Camera Preview App.",
      ),
    )
  );
}

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key, required this.camera, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final CameraDescription camera;

  final String title;


  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late Detector detector;
  bool inferencing = false;

  late IsolateUtils isolateUtils;

  late List<DetectionResult> results;

  @override
  void initState() {
    super.initState();

    initStateAsync();

    _initializeCamera();

    detector = Detector();
  }

  void initStateAsync() async {
    isolateUtils = IsolateUtils();
    await isolateUtils.start();
  }

  void _initializeCamera() async {
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
      enableAudio: false,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize().then((_) async {
      _controller.startImageStream(onLatestImageAvailable);

      Size? previewSize = _controller.value.previewSize;
      CameraViewSingleton.inputImageSize = previewSize!;

      Size screenSize = MediaQuery.of(context).size;
      CameraViewSingleton.screenSize = screenSize;
      CameraViewSingleton.ratio = screenSize.width / previewSize.height;
    });
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
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
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: CameraPreview(_controller),
            );

          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  void onLatestImageAvailable(CameraImage cameraImage) async {
    print("onLatestImageAvailable");
    /*
    setState(() {
      inferencing = true;
    });

    var isolateData = IsolateData(cameraImage, detector);

    Map<String, dynamic> inferenceResults = await inference(isolateData);

    setState(() {
      results = inferenceResults["result"];

      inferencing = false;
    });
     */
  }

  Future<Map<String, dynamic>> inference(IsolateData isolateData) async {
    print("inference");

    ReceivePort responsePort = ReceivePort();
    isolateUtils.sendPort.send(isolateData..responsePort = responsePort.sendPort);
    var results = await responsePort.first;
    return results;
  }
}

class BoxWidget extends StatelessWidget {
  final DetectionResult result;

  const BoxWidget({required Key key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color = Colors.primaries[
      (result.label.length + result.label.codeUnitAt(0) + result.id) % Colors.primaries.length];

    return Positioned(
      left: result.renderLocation.left,
      top: result.renderLocation.top,
      width: result.renderLocation.width,
      height: result.renderLocation.height,
      child: Container(
        width: result.renderLocation.width,
        height: result.renderLocation.height,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
            borderRadius: const BorderRadius.all(Radius.circular(2))
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: FittedBox(
            child: Container(
              color: color,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(result.label),
                  Text(" ${result.score.toStringAsFixed(2)}"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}