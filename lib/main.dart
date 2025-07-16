import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force landscape mode for immersive experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Get available cameras
  final cameras = await availableCameras();

  runApp(DrishtiApp(cameras: cameras));
}

class DrishtiApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const DrishtiApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme),
      ),
      home: CameraScreen(cameras: cameras),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  late CameraController _controller;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late FlutterTts _flutterTts;

  bool _isInitialized = false;
  String _currentMode = 'Object Detection';
  bool _isScanning = false;
  int _simulatedObjectCount = 0;
  List<SimulatedObject> _simulatedObjects = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeTTS();

    // Setup animation for HUD elements
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    final camera = widget.cameras.first;
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller.initialize();
      setState(() => _isInitialized = true);
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _initializeTTS() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.8);
    await _flutterTts.setVolume(0.8);
    await _flutterTts.setPitch(1.0);
    print('TTS initialized successfully');
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
    });

    print('Scanning mode: $_isScanning');

    if (_isScanning) {
      _flutterTts.speak('Scanning mode activated');
      _startSimulatedDetection();
    } else {
      _flutterTts.speak('Scanning mode deactivated');
      _stopSimulatedDetection();
    }
  }

  void _startSimulatedDetection() {
    // Simulate object detection for demo purposes
    Future.delayed(Duration(seconds: 2), () {
      if (_isScanning && mounted) {
        setState(() {
          _simulatedObjectCount = Random().nextInt(5) + 1;
          _simulatedObjects = _generateSimulatedObjects();
        });

        List<String> objects = ['Table', 'Chair', 'Phone', 'Laptop', 'Book'];
        String detectedObject = objects[Random().nextInt(objects.length)];
        _flutterTts.speak('Detected: $detectedObject');

        // Continue simulation
        _startSimulatedDetection();
      }
    });
  }

  void _stopSimulatedDetection() {
    setState(() {
      _simulatedObjectCount = 0;
      _simulatedObjects = [];
    });
  }

  List<SimulatedObject> _generateSimulatedObjects() {
    List<SimulatedObject> objects = [];
    List<String> labels = [
      'Table',
      'Chair',
      'Phone',
      'Laptop',
      'Book',
      'Cup',
      'Monitor',
    ];

    for (int i = 0; i < _simulatedObjectCount; i++) {
      objects.add(
        SimulatedObject(
          label: labels[Random().nextInt(labels.length)],
          confidence: 0.7 + Random().nextDouble() * 0.3,
          rect: Rect.fromLTWH(
            Random().nextDouble() * 300 + 50,
            Random().nextDouble() * 200 + 50,
            Random().nextDouble() * 150 + 100,
            Random().nextDouble() * 100 + 80,
          ),
        ),
      );
    }

    return objects;
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.cyanAccent),
              SizedBox(height: 20),
              Text(
                'Initializing DRISHTI...',
                style: TextStyle(color: Colors.cyanAccent, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Transform.scale(
            scale: 1.0,
            child: Center(child: CameraPreview(_controller)),
          ),

          // HUD Overlay with simulated objects
          CustomPaint(
            painter: HUDPainter(
              animation: _animation.value,
              simulatedObjects: _simulatedObjects,
              screenSize: MediaQuery.of(context).size,
            ),
            size: Size.infinite,
          ),

          // Status Text
          Positioned(
            top: 20,
            left: 20,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: _animation.value,
                      child: Text(
                        'DRISHTI v1.0',
                        style: TextStyle(
                          color: Colors.cyanAccent.withOpacity(0.8),
                          fontSize: 16,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Mode: $_currentMode',
                      style: TextStyle(
                        color: Colors.cyanAccent.withOpacity(0.6),
                        fontSize: 12,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    Text(
                      'Objects: $_simulatedObjectCount',
                      style: TextStyle(
                        color: Colors.cyanAccent.withOpacity(0.6),
                        fontSize: 12,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    if (_isScanning)
                      Text(
                        'SCANNING ACTIVE',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Simulated Object Labels
          ..._buildSimulatedObjectLabels(),

          // Mode Selector FAB
          Positioned(
            right: 20,
            bottom: 20,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _animation.value,
                  child: FloatingActionButton(
                    onPressed: _toggleScanning,
                    backgroundColor: Colors.transparent,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              _isScanning
                                  ? Colors.greenAccent.withOpacity(0.8)
                                  : Colors.cyanAccent.withOpacity(0.8),
                          width: 2,
                        ),
                        gradient: RadialGradient(
                          colors:
                              _isScanning
                                  ? [
                                    Colors.greenAccent.withOpacity(0.2),
                                    Colors.green.withOpacity(0.1),
                                  ]
                                  : [
                                    Colors.cyanAccent.withOpacity(0.2),
                                    Colors.blue.withOpacity(0.1),
                                  ],
                        ),
                      ),
                      child: Icon(
                        _isScanning ? Icons.stop : Icons.play_arrow,
                        color:
                            _isScanning
                                ? Colors.greenAccent
                                : Colors.cyanAccent,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSimulatedObjectLabels() {
    return _simulatedObjects.map((object) {
      return Positioned(
        left: object.rect.left,
        top: object.rect.top - 25,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.cyanAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
          ),
          child: Text(
            '${object.label} ${(object.confidence * 100).toInt()}%',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 12,
              fontFamily: 'Orbitron',
            ),
          ),
        ),
      );
    }).toList();
  }
}

class SimulatedObject {
  final String label;
  final double confidence;
  final Rect rect;

  SimulatedObject({
    required this.label,
    required this.confidence,
    required this.rect,
  });
}

class HUDPainter extends CustomPainter {
  final double animation;
  final List<SimulatedObject> simulatedObjects;
  final Size screenSize;

  HUDPainter({
    required this.animation,
    required this.simulatedObjects,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.cyanAccent.withOpacity(0.3 * animation)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    // Draw corner brackets
    final bracketSize = size.width * 0.1;

    // Top-left corner
    canvas.drawLine(const Offset(20, 20), Offset(20 + bracketSize, 20), paint);
    canvas.drawLine(const Offset(20, 20), Offset(20, 20 + bracketSize), paint);

    // Top-right corner
    canvas.drawLine(
      Offset(size.width - 20, 20),
      Offset(size.width - 20 - bracketSize, 20),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 20, 20),
      Offset(size.width - 20, 20 + bracketSize),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(20, size.height - 20),
      Offset(20 + bracketSize, size.height - 20),
      paint,
    );
    canvas.drawLine(
      Offset(20, size.height - 20),
      Offset(20, size.height - 20 - bracketSize),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width - 20, size.height - 20),
      Offset(size.width - 20 - bracketSize, size.height - 20),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 20, size.height - 20),
      Offset(size.width - 20, size.height - 20 - bracketSize),
      paint,
    );

    // Draw scanning line
    final scanLineY =
        (size.height * 0.5) + (size.height * 0.3 * sin(animation * 3.14));
    canvas.drawLine(
      Offset(40, scanLineY),
      Offset(size.width - 40, scanLineY),
      Paint()
        ..color = Colors.cyanAccent.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Draw simulated object bounding boxes
    final objectPaint =
        Paint()
          ..color = Colors.cyanAccent.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    for (final object in simulatedObjects) {
      final rect = object.rect;
      canvas.drawRect(rect, objectPaint);

      // Draw corner markers for detected objects
      final cornerSize = 10.0;

      // Top-left corner
      canvas.drawLine(
        Offset(rect.left, rect.top),
        Offset(rect.left + cornerSize, rect.top),
        objectPaint,
      );
      canvas.drawLine(
        Offset(rect.left, rect.top),
        Offset(rect.left, rect.top + cornerSize),
        objectPaint,
      );

      // Top-right corner
      canvas.drawLine(
        Offset(rect.right, rect.top),
        Offset(rect.right - cornerSize, rect.top),
        objectPaint,
      );
      canvas.drawLine(
        Offset(rect.right, rect.top),
        Offset(rect.right, rect.top + cornerSize),
        objectPaint,
      );

      // Bottom-left corner
      canvas.drawLine(
        Offset(rect.left, rect.bottom),
        Offset(rect.left + cornerSize, rect.bottom),
        objectPaint,
      );
      canvas.drawLine(
        Offset(rect.left, rect.bottom),
        Offset(rect.left, rect.bottom - cornerSize),
        objectPaint,
      );

      // Bottom-right corner
      canvas.drawLine(
        Offset(rect.right, rect.bottom),
        Offset(rect.right - cornerSize, rect.bottom),
        objectPaint,
      );
      canvas.drawLine(
        Offset(rect.right, rect.bottom),
        Offset(rect.right, rect.bottom - cornerSize),
        objectPaint,
      );
    }
  }

  @override
  bool shouldRepaint(HUDPainter oldDelegate) => true;
}
