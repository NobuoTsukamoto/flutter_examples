import 'dart:math';
import 'dart:ui';

import 'camera_view_singleton.dart';

class DetectionResult {
  int _id;
  String _label;
  double _score;
  Rect _box;

  DetectionResult(this._id, this._label, this._score, this._box);

  int get id => _id;
  String get label => _label;
  double get score => _score;
  Rect get box => _box;

  Rect get renderLocation {
    double ratioX = CameraViewSingleton.ratio;
    double ratioY = ratioX;

    double transLeft = max(0.1, _box.left * ratioX);
    double transTop = max(0.1, _box.top * ratioY);
    double transWidth = min(
        _box.width * ratioX, CameraViewSingleton.actualPreviewSize.width);
    double transHeight = min(
        _box.height * ratioY, CameraViewSingleton.actualPreviewSize.height);

    Rect transformedRect =
    Rect.fromLTWH(transLeft, transTop, transWidth, transHeight);
    return transformedRect;
  }

  @override
  String toString() {
    return 'Recognition(id: $id, label: $label, score: $score, location: $box)';
  }
}