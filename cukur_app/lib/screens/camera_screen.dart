import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../providers/pothole_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isDetecting = false;
  Timer? _processingTimer;
  int _detectionCount = 0;
  String _statusMessage = 'Başlatılıyor...';

  // Frame processing interval (RAM optimization)
  static const int _frameInterval = 2000; // 2 seconds between frames

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    // Initialize model after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeModel();
    });
  }

  Future<void> _initializeModel() async {
    if (!mounted) return;
    
    try {
      final provider = context.read<PotholeProvider>();
      await provider.initialize();
      
      if (!provider.isSupported && mounted) {
        setState(() {
          _statusMessage = provider.error ?? 'TFLite bu platformda desteklenmiyor';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Model başlatma hatası: $e';
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    // Small delay to let UI render first
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          setState(() {
            _statusMessage = 'Kamera bulunamadı';
          });
        }
        return;
      }

      // Use the back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      // Try with low resolution first for better compatibility
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.low, // Low resolution for better compatibility
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _statusMessage = 'Hazır';
        });
      }
    } catch (e) {
      // Try fallback without any special settings
      try {
        if (_cameras != null && _cameras!.isNotEmpty) {
          _cameraController = CameraController(
            _cameras!.first,
            ResolutionPreset.low,
            enableAudio: false,
          );
          await _cameraController!.initialize();
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _statusMessage = 'Hazır (düşük çözünürlük)';
            });
          }
        }
      } catch (e2) {
        if (mounted) {
          setState(() {
            _statusMessage = 'Kamera başlatılamadı. Emülatörde kamera desteklenmeyebilir.';
          });
        }
      }
    }
  }

  void _startDetection() {
    if (_isDetecting || !_isInitialized) return;

    setState(() {
      _isDetecting = true;
      _statusMessage = 'Tespit aktif';
    });

    // Process frames at intervals to save RAM
    _processingTimer = Timer.periodic(
      const Duration(milliseconds: _frameInterval),
      (_) => _captureAndProcess(),
    );
  }

  void _stopDetection() {
    _processingTimer?.cancel();
    _processingTimer = null;

    setState(() {
      _isDetecting = false;
      _statusMessage = 'Tespit durduruldu';
    });
  }

  Future<void> _captureAndProcess() async {
    if (!_isInitialized || _cameraController == null) return;
    if (!_cameraController!.value.isInitialized) return;

    final provider = context.read<PotholeProvider>();
    if (provider.isProcessing) return;

    try {
      // Capture image
      final XFile image = await _cameraController!.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();

      // Process with TFLite
      final detections = await provider.processFrame(imageBytes);

      if (detections.isNotEmpty) {
        setState(() {
          _detectionCount += detections.length;
          _statusMessage = 'Çukur tespit edildi! (${detections.length} adet)';
        });

        // Show snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${detections.length} çukur tespit edildi!'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Capture error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopDetection();
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _processingTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Çukur Tespiti'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          Consumer<PotholeProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Chip(
                  label: Text(
                    '${provider.detections.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildCameraPreview(),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isInitialized || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _initializeCamera,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),
        // Detection overlay
        if (_isDetecting)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'CANLI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Status message
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Text(
              _statusMessage,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey[900],
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Detection count
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_detectionCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Tespit',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            // Start/Stop button
            GestureDetector(
              onTap: _isInitialized
                  ? (_isDetecting ? _stopDetection : _startDetection)
                  : null,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isDetecting ? Colors.red : Colors.orange,
                  boxShadow: [
                    BoxShadow(
                      color: (_isDetecting ? Colors.red : Colors.orange)
                          .withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _isDetecting ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            // Manual capture
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _isInitialized ? _captureAndProcess : null,
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  iconSize: 32,
                ),
                const Text(
                  'Manuel',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
