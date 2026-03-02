import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class DetectionResult {
  final List<double> boundingBox;
  final double confidence;
  final int classId;

  DetectionResult({
    required this.boundingBox,
    required this.confidence,
    required this.classId,
  });
}

class TFLiteService {
  static const String modelPath = 'assets/models/yol_best_float16.tflite';
  static const int inputSize = 640;
  static const double confidenceThreshold = 0.5;
  static const double iouThreshold = 0.45;

  Interpreter? _interpreter;
  bool _isInitialized = false;
  bool _isSupported = true;
  String? _errorMessage;

  bool get isInitialized => _isInitialized;
  bool get isSupported => _isSupported;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Check platform support
    if (kIsWeb || Platform.isWindows || Platform.isLinux) {
      _isSupported = false;
      _errorMessage = 'TFLite bu platformda desteklenmiyor. Android veya iOS cihazda çalıştırın.';
      print(_errorMessage);
      return;
    }

    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(modelPath, options: options);
      _isInitialized = true;
      print('TFLite model loaded successfully');
    } catch (e) {
      _isSupported = false;
      _errorMessage = 'Model yüklenirken hata: $e';
      print('Error loading TFLite model: $e');
    }
  }

  Future<List<DetectionResult>> detectPotholes(Uint8List imageBytes) async {
    if (!_isSupported) {
      return []; // Return empty on unsupported platforms
    }
    
    if (!_isInitialized || _interpreter == null) {
      return []; // Return empty if not initialized
    }

    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image to model input size
      final resizedImage = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
      );

      // Prepare input tensor - normalize to 0-1
      final input = _prepareInput(resizedImage);

      // Run inference
      final output = _runInference(input);

      // Process output
      final detections = _processOutput(output, image.width, image.height);

      return detections;
    } catch (e) {
      print('Error during detection: $e');
      return [];
    }
  }

  List<List<List<List<double>>>> _prepareInput(img.Image image) {
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = image.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
    return input;
  }

  List<List<List<double>>> _runInference(
      List<List<List<List<double>>>> input) {
    // YOLOv8 output shape: [1, 5, 8400] for detection
    // 5 = x, y, w, h, confidence (for single class)
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    
    // Create output buffer based on actual output shape
    final output = List.generate(
      outputShape[0],
      (_) => List.generate(
        outputShape[1],
        (_) => List.filled(outputShape[2], 0.0),
      ),
    );

    _interpreter!.run(input, output);

    return output;
  }

  List<DetectionResult> _processOutput(
    List<List<List<double>>> output,
    int originalWidth,
    int originalHeight,
  ) {
    final detections = <DetectionResult>[];
    
    // YOLOv8 output format: [1, 5, 8400]
    // Transpose to [8400, 5] for easier processing
    final numDetections = output[0][0].length;
    
    for (int i = 0; i < numDetections; i++) {
      // Get confidence (last attribute for single class model)
      final confidence = output[0][4][i];
      
      if (confidence >= confidenceThreshold) {
        // Get bounding box (center x, center y, width, height)
        final cx = output[0][0][i];
        final cy = output[0][1][i];
        final w = output[0][2][i];
        final h = output[0][3][i];
        
        // Convert to corner format and scale to original image size
        final scaleX = originalWidth / inputSize;
        final scaleY = originalHeight / inputSize;
        
        final x1 = (cx - w / 2) * scaleX;
        final y1 = (cy - h / 2) * scaleY;
        final x2 = (cx + w / 2) * scaleX;
        final y2 = (cy + h / 2) * scaleY;
        
        detections.add(DetectionResult(
          boundingBox: [x1, y1, x2, y2],
          confidence: confidence,
          classId: 0, // Single class: pothole
        ));
      }
    }

    // Apply NMS
    return _nonMaxSuppression(detections);
  }

  List<DetectionResult> _nonMaxSuppression(List<DetectionResult> detections) {
    if (detections.isEmpty) return [];

    // Sort by confidence
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final selected = <DetectionResult>[];

    while (detections.isNotEmpty) {
      final best = detections.removeAt(0);
      selected.add(best);

      detections.removeWhere((detection) {
        return _calculateIoU(best.boundingBox, detection.boundingBox) >
            iouThreshold;
      });
    }

    return selected;
  }

  double _calculateIoU(List<double> box1, List<double> box2) {
    final x1 = box1[0].clamp(0, double.infinity);
    final y1 = box1[1].clamp(0, double.infinity);
    final x2 = box1[2];
    final y2 = box1[3];

    final x1b = box2[0].clamp(0, double.infinity);
    final y1b = box2[1].clamp(0, double.infinity);
    final x2b = box2[2];
    final y2b = box2[3];

    final intersectX1 = x1 > x1b ? x1 : x1b;
    final intersectY1 = y1 > y1b ? y1 : y1b;
    final intersectX2 = x2 < x2b ? x2 : x2b;
    final intersectY2 = y2 < y2b ? y2 : y2b;

    final intersectArea = (intersectX2 - intersectX1).clamp(0, double.infinity) *
        (intersectY2 - intersectY1).clamp(0, double.infinity);

    final box1Area = (x2 - x1) * (y2 - y1);
    final box2Area = (x2b - x1b) * (y2b - y1b);

    final unionArea = box1Area + box2Area - intersectArea;

    return intersectArea / unionArea;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
