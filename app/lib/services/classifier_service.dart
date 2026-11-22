import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/detection.dart';

class ModelUnavailableException implements Exception {
  const ModelUnavailableException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Menjalankan model MobileNetV2 (.tflite) hasil notebook SNAPROAD.
///
/// Kontrak model (lihat notebook):
///  * input  : [1, 224, 224, 3] float32 bernilai 0..255 (normalisasi ada di dalam model)
///  * output : [1, 3] softmax, urutan = labels.txt (ringan, sedang, berat)
class ClassifierService {
  static const modelAsset = 'assets/model/snaproad_mobilenetv2_fp16.tflite';
  static const labelsAsset = 'assets/model/labels.txt';

  Interpreter? _interpreter;
  List<Severity> _labels = Severity.values;
  int _inputSize = 224;
  bool _inputIsUint8 = false;

  /// Pesan error terakhir saat memuat model (null jika berhasil).
  String? loadError;

  bool get isReady => _interpreter != null;

  /// Memuat model dari assets. Tidak melempar error: hasilnya ada di
  /// [isReady] / [loadError] supaya aplikasi tetap bisa dibuka tanpa model.
  Future<bool> load() async {
    if (_interpreter != null) return true;
    try {
      _labels = await _loadLabels();

      final options = InterpreterOptions()..threads = 2;
      final interpreter =
          await Interpreter.fromAsset(modelAsset, options: options);

      final inTensor = interpreter.getInputTensor(0);
      final outTensor = interpreter.getOutputTensor(0);
      final inShape = inTensor.shape; // [1, H, W, 3]
      final outShape = outTensor.shape; // [1, 3]

      if (inShape.length != 4 || inShape[3] != 3) {
        throw StateError('Bentuk input model tidak sesuai: $inShape');
      }
      if (outShape.last != _labels.length) {
        throw StateError(
          'Model punya ${outShape.last} kelas, labels.txt punya ${_labels.length}.',
        );
      }

      _inputSize = inShape[1];
      _inputIsUint8 = inTensor.type.toString().toLowerCase().contains('uint8');
      _interpreter = interpreter;
      loadError = null;
      return true;
    } catch (e) {
      loadError = e.toString();
      debugPrint('[SNAPROAD] Gagal memuat model: $e');
      return false;
    }
  }

  Future<List<Severity>> _loadLabels() async {
    try {
      final text = await rootBundle.loadString(labelsAsset);
      final parsed = <Severity>[];
      for (final line in text.split('\n')) {
        if (line.trim().isEmpty) continue;
        final s = Severity.fromKey(line);
        if (s == null) return Severity.values;
        parsed.add(s);
      }
      return parsed.isEmpty ? Severity.values : parsed;
    } catch (_) {
      return Severity.values;
    }
  }

  Future<ClassificationResult> classify(String imagePath) async {
    if (_interpreter == null) await load();
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw const ModelUnavailableException(
        'Model belum terpasang. Letakkan snaproad_mobilenetv2_fp16.tflite '
        'di folder assets/model/ lalu jalankan ulang aplikasi.',
      );
    }

    final bytes = await File(imagePath).readAsBytes();
    // Decode + resize berat -> jalankan di isolate agar UI tidak macet.
    final pixels = await compute(
      _preprocess,
      _PreprocessArgs(bytes, _inputSize),
    );

    final sw = Stopwatch()..start();
    final classes = _labels.length;
    final output = List.filled(classes, 0.0).reshape([1, classes]);

    final shape = [1, _inputSize, _inputSize, 3];
    if (_inputIsUint8) {
      final ints = Uint8List(pixels.length);
      for (var i = 0; i < pixels.length; i++) {
        ints[i] = pixels[i].round().clamp(0, 255).toInt();
      }
      interpreter.run(ints.reshape(shape), output);
    } else {
      interpreter.run(pixels.reshape(shape), output);
    }
    sw.stop();

    var probs = (output[0] as List)
        .map((e) => (e as num).toDouble())
        .toList(growable: false);
    probs = _ensureProbabilities(probs);

    return ClassificationResult(
      scores: {for (var i = 0; i < classes; i++) _labels[i]: probs[i]},
      inferenceMs: sw.elapsedMilliseconds,
    );
  }

  /// Jika output belum ternormalisasi (bukan softmax), terapkan softmax.
  static List<double> _ensureProbabilities(List<double> v) {
    final sum = v.fold<double>(0, (a, b) => a + b);
    final looksLikeProbs = sum > 0.98 && sum < 1.02 && v.every((x) => x >= 0);
    if (looksLikeProbs) return v;
    final maxV = v.reduce(math.max);
    final exps = v.map((x) => math.exp(x - maxV)).toList();
    final total = exps.fold<double>(0, (a, b) => a + b);
    return exps.map((x) => x / total).toList(growable: false);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

class _PreprocessArgs {
  const _PreprocessArgs(this.bytes, this.size);
  final Uint8List bytes;
  final int size;
}

/// Berjalan di isolate: decode JPEG -> putar sesuai EXIF -> resize
/// (bilinear, sama seperti tf.image.resize di notebook) -> float 0..255 RGB.
Float32List _preprocess(_PreprocessArgs a) {
  final decoded = img.decodeImage(a.bytes);
  if (decoded == null) {
    throw const FormatException('Gambar tidak dapat dibaca.');
  }
  final oriented = img.bakeOrientation(decoded);
  final resized = img.copyResize(
    oriented,
    width: a.size,
    height: a.size,
    interpolation: img.Interpolation.linear,
  );

  final out = Float32List(a.size * a.size * 3);
  var i = 0;
  for (var y = 0; y < a.size; y++) {
    for (var x = 0; x < a.size; x++) {
      final p = resized.getPixel(x, y);
      out[i++] = p.r.toDouble();
      out[i++] = p.g.toDouble();
      out[i++] = p.b.toDouble();
    }
  }
  return out;
}
