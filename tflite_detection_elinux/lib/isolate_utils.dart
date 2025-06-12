import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:tflite_detection_elinux/detectionResult.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imageLib;

import 'detector.dart';
import 'image_utils.dart';

class IsolateUtils {
  static const String debugName = "InferenceIsolate";

  late Isolate _isolate;
  final ReceivePort _receivePort= ReceivePort();
  late SendPort _sendPort;

  SendPort get sendPort => _sendPort;

  Future<void> start() async {
    _isolate = await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: debugName,
    );
    _sendPort = await _receivePort.first;
  }

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();

    await for (final IsolateData isolateData in port) {
      imageLib.Image image =
      ImageUtils.convertCameraImage(isolateData.cameraImage);
      Map<String, dynamic> results = isolateData.detector.inference(image);
      isolateData.responsePort.send(results);
    }
  }
}

class IsolateData {
  late CameraImage cameraImage;
  late Detector detector;
  late SendPort responsePort;

  IsolateData(this.cameraImage, this.detector);
}