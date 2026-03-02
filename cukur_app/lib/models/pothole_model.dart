import 'dart:typed_data';

class PotholeDetection {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime detectedAt;
  final Uint8List? imageBytes;
  final double confidence;
  final List<double> boundingBox; // [x, y, width, height]

  PotholeDetection({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.detectedAt,
    this.imageBytes,
    required this.confidence,
    required this.boundingBox,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'detectedAt': detectedAt.toIso8601String(),
        'confidence': confidence,
        'boundingBox': boundingBox,
      };

  factory PotholeDetection.fromJson(Map<String, dynamic> json) {
    return PotholeDetection(
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      detectedAt: DateTime.parse(json['detectedAt']),
      confidence: json['confidence'],
      boundingBox: List<double>.from(json['boundingBox']),
    );
  }

  PotholeDetection copyWith({
    String? id,
    double? latitude,
    double? longitude,
    DateTime? detectedAt,
    Uint8List? imageBytes,
    double? confidence,
    List<double>? boundingBox,
  }) {
    return PotholeDetection(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      detectedAt: detectedAt ?? this.detectedAt,
      imageBytes: imageBytes ?? this.imageBytes,
      confidence: confidence ?? this.confidence,
      boundingBox: boundingBox ?? this.boundingBox,
    );
  }
}
