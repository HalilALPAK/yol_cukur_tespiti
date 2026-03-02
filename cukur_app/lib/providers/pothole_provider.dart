import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/pothole_model.dart';
import '../services/tflite_service.dart';
import '../services/location_service.dart';

class PotholeProvider extends ChangeNotifier {
  final TFLiteService _tfliteService = TFLiteService();
  final LocationService _locationService = LocationService();
  final Uuid _uuid = const Uuid();

  List<PotholeDetection> _detections = [];
  bool _isProcessing = false;
  bool _isInitialized = false;
  bool _isSupported = true;
  String? _error;

  List<PotholeDetection> get detections => List.unmodifiable(_detections);
  bool get isProcessing => _isProcessing;
  bool get isInitialized => _isInitialized;
  bool get isSupported => _isSupported;
  String? get error => _error;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _error = null;
      await _tfliteService.initialize();
      
      _isSupported = _tfliteService.isSupported;
      _isInitialized = _tfliteService.isInitialized || !_isSupported;
      
      if (!_isSupported) {
        _error = _tfliteService.errorMessage;
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Model yüklenirken hata: $e';
      _isInitialized = true; // Allow app to continue
      notifyListeners();
    }
  }

  Future<List<PotholeDetection>> processFrame(Uint8List imageBytes) async {
    if (_isProcessing) return [];
    if (!_isSupported) return [];

    _isProcessing = true;
    notifyListeners();

    try {
      // Run detection
      final results = await _tfliteService.detectPotholes(imageBytes);

      if (results.isEmpty) {
        _isProcessing = false;
        notifyListeners();
        return [];
      }

      // Get current location
      final position = await _locationService.getCurrentPosition();

      if (position == null) {
        _isProcessing = false;
        notifyListeners();
        return [];
      }

      // Create detections
      final newDetections = <PotholeDetection>[];

      for (final result in results) {
        // Check if similar detection exists nearby
        final exists = _detections.any((d) =>
            _calculateDistance(
                d.latitude, d.longitude, position.latitude, position.longitude) <
            10); // 10 meters threshold

        if (!exists) {
          final detection = PotholeDetection(
            id: _uuid.v4(),
            latitude: position.latitude,
            longitude: position.longitude,
            detectedAt: DateTime.now(),
            imageBytes: imageBytes,
            confidence: result.confidence,
            boundingBox: result.boundingBox,
          );

          newDetections.add(detection);
          _detections.add(detection);
        }
      }

      _isProcessing = false;
      notifyListeners();

      return newDetections;
    } catch (e) {
      _error = 'İşleme hatası: $e';
      _isProcessing = false;
      notifyListeners();
      return [];
    }
  }

  void removeDetection(String id) {
    _detections.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  void markAsFalseAlarm(String id) {
    removeDetection(id);
  }

  void markAsRepaired(String id) {
    removeDetection(id);
  }

  void clearAll() {
    _detections.clear();
    notifyListeners();
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula
    const earthRadius = 6371000; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);

    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * 3.14159265359 / 180;
  double _sin(double x) => _taylorSin(x);
  double _cos(double x) => _taylorCos(x);
  double _sqrt(double x) => x >= 0 ? _newtonSqrt(x) : 0;
  double _atan2(double y, double x) {
    if (x > 0) return _taylorAtan(y / x);
    if (x < 0 && y >= 0) return _taylorAtan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _taylorAtan(y / x) - 3.14159265359;
    if (x == 0 && y > 0) return 3.14159265359 / 2;
    if (x == 0 && y < 0) return -3.14159265359 / 2;
    return 0;
  }

  double _taylorSin(double x) {
    // Normalize x to [-pi, pi]
    while (x > 3.14159265359) x -= 2 * 3.14159265359;
    while (x < -3.14159265359) x += 2 * 3.14159265359;
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  double _taylorCos(double x) {
    while (x > 3.14159265359) x -= 2 * 3.14159265359;
    while (x < -3.14159265359) x += 2 * 3.14159265359;
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _newtonSqrt(double x) {
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _taylorAtan(double x) {
    if (x > 1) return 3.14159265359 / 2 - _taylorAtan(1 / x);
    if (x < -1) return -3.14159265359 / 2 - _taylorAtan(1 / x);
    double result = x;
    double term = x;
    for (int i = 1; i <= 20; i++) {
      term *= -x * x;
      result += term / (2 * i + 1);
    }
    return result;
  }

  @override
  void dispose() {
    _tfliteService.dispose();
    super.dispose();
  }
}
