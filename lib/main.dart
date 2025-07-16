import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

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

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
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

          // HUD Overlay
          CustomPaint(
            painter: HUDPainter(animation: _animation.value),
            size: Size.infinite,
          ),

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
                    onPressed: () {
                      // TODO: Implement mode switching
                    },
                    backgroundColor: Colors.transparent,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.cyanAccent.withOpacity(0.8),
                          width: 2,
                        ),
                        gradient: RadialGradient(
                          colors: [
                            Colors.cyanAccent.withOpacity(0.2),
                            Colors.blue.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: const Icon(Icons.camera, color: Colors.cyanAccent),
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
}

class HUDPainter extends CustomPainter {
  final double animation;

  HUDPainter({required this.animation});

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
  }

  @override
  bool shouldRepaint(HUDPainter oldDelegate) => true;
}
