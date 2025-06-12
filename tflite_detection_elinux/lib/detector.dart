import 'dart:math';
import 'dart:ui';

import 'package:image/image.dart' as imageLib;
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import 'detectionResult.dart';

class Detector {
  Interpreter? _interpreter;
   List<String>? _labels;

  static const String tfliteModelFile = "efficientdet-lite0_fp32.tflite";
  static const String labelFile = "assets/coco_labels.txt";
  static const int labelOffset = 1;
  static const int numThreads = 4;


  late ImageProcessor _imageProcessor;

  late List<int> _inputShapes;
  late int _inputHeight;
  late int _inputWidth;
  late List<List<int>> _outputShapes;
  late List<TfLiteType> _outputTypes;

  Detector() {
    makeInterpreter();
    loadLabels();
  }

  Future<void> loadLabels() async {
    try {
      _labels = await FileUtil.loadLabels(labelFile);
    } catch (e) {
      if (kDebugMode) {
        print("Error while loading labels: $e");
      }
    }
  }

  Future<void> makeInterpreter() async {
    try {
      _interpreter = await Interpreter.fromAsset(
          tfliteModelFile,
          options: InterpreterOptions()..threads = numThreads
      );

      var inputTensor = _interpreter?.getInputTensor(0);
      _inputShapes = inputTensor!.shape;
      _inputHeight = _inputShapes[1];
      _inputWidth = _inputShapes[2];

      print("Input : $_inputHeight, $_inputWidth");

      _imageProcessor = ImageProcessorBuilder()
          .add(ResizeOp(_inputShapes[1], _inputShapes[2], ResizeMethod.BILINEAR))
          .build();

      var outputTensors = _interpreter?.getOutputTensors();
      _outputShapes = [];
      _outputTypes = [];
      for (var tensor in outputTensors!) {
        _outputShapes.add(tensor.shape);
        _outputTypes.add(tensor.type);
      }

    } catch (e) {
      if (kDebugMode) {
        print("Error while creating interpreter: $e");
      }
    }
  }

  TensorImage getProcessedImage(TensorImage inputImage) {
    return _imageProcessor.process(inputImage);
  }

  Map<String, dynamic> inference(imageLib.Image image) {

    print("inference");

    TensorImage inputImage = TensorImage.fromImage(image);
    inputImage = getProcessedImage(inputImage);
    List<Object> inputs = [inputImage.buffer];

    TensorBuffer outputBoxes = TensorBufferFloat(_outputShapes[0]);
    TensorBuffer outputClasses = TensorBufferFloat(_outputShapes[1]);
    TensorBuffer outputScores = TensorBufferFloat(_outputShapes[2]);
    TensorBuffer outputCounts = TensorBufferFloat(_outputShapes[3]);
    Map<int, Object> outputs = {
      0: outputBoxes.buffer,
      1: outputClasses.buffer,
      2: outputScores.buffer,
      3: outputCounts.buffer,
    };

    _interpreter!.runForMultipleInputs(inputs, outputs);

    // Using bounding box utils for easy conversion of tensorbuffer to List<Rect>
    List<Rect> locations = BoundingBoxUtils.convert(
      tensor: outputBoxes,
      valueIndex: [1, 0, 3, 2],
      boundingBoxAxis: 2,
      boundingBoxType: BoundingBoxType.BOUNDARIES,
      coordinateType: CoordinateType.RATIO,
      height: _inputHeight,
      width: _inputWidth,
    );

    List<DetectionResult> detectionResults = [];

    for (int i = 0; i < outputCounts.getIntValue(0); i++) {
      var score = outputScores.getDoubleValue(i);
      var label = _labels!.elementAt(outputClasses.getIntValue(i) + labelOffset);

      var transformedRect = _imageProcessor.inverseTransformRect(
          locations[i], image.height, image.width
      );
      detectionResults.add(DetectionResult(i, label, score, transformedRect));
    }

    return {"result": detectionResults};
  }

  Interpreter? get interpreter => _interpreter;
  List<String>? get labels => _labels;
}