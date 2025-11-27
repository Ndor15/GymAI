import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';

class RepAI {
  late Interpreter _interpreter;

  /// Appelle load() AVANT d’utiliser predict()
  Future<void> load() async {
    _interpreter = await Interpreter.fromAsset('assets/models/imu_model.tflite');

  }

  /// window = List<List<double>> de taille 125 × 6
  List<double> predict(List<List<double>> window) {
    final input = List.generate(
      1,
          (_) => List.generate(
        125,
            (i) => Float32List.fromList(window[i].map((v) => v.toDouble()).toList()),
      ),
    );

    final output = List.filled(2, 0.0).reshape([1, 2]);

    _interpreter.run(input, output);
    return List<double>.from(output[0]);
  }
}
