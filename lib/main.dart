import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'avatar/avatar_painter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: MainScreen(cameras: cameras),
    );
  }
}

class MainScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const MainScreen({super.key, required this.cameras});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late CameraController _cameraController;
  late AnimationController _avatarAnimationController;
  late FlutterTts _flutterTts;
  late TextRecognizer _textRecognizer;
  late ImageLabeler _imageLabeler;
  late OnDeviceTranslator _translator;

  // Add chat-related variables
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  final ScrollController _scrollController = ScrollController();
  bool _showChat = false;

  bool _isInitialized = false;
  AvatarEmotion _currentEmotion = AvatarEmotion.neutral;
  AvatarState _currentState = AvatarState.idle;
  String _lastSpokenText = '';
  String _currentFilter = 'none';
  bool _isProcessingFrame = false;
  Timer? _processingTimer;
  String _lastDetectedText = '';
  bool _isAutoProcessing = false;

  // Available filters
  final Map<String, List<double>> _filters = {
    'none': [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
    'vintage': [
      0.9,
      0.1,
      0.1,
      0,
      0,
      0.1,
      0.9,
      0.1,
      0,
      0,
      0.1,
      0.1,
      0.9,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ],
    'cyberpunk': [
      1.1,
      0,
      0.2,
      0,
      0,
      0.2,
      1.0,
      0,
      0,
      0,
      0,
      0.2,
      1.1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ],
    'noir': [
      0.33,
      0.33,
      0.33,
      0,
      0,
      0.33,
      0.33,
      0.33,
      0,
      0,
      0.33,
      0.33,
      0.33,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ],
    'vivid': [1.2, 0, 0, 0, 0, 0, 1.2, 0, 0, 0, 0, 0, 1.2, 0, 0, 0, 0, 0, 1, 0],
  };

  bool _isTranslating = false;
  String _translatedText = '';
  TranslateLanguage _sourceLanguage = TranslateLanguage.english;
  TranslateLanguage _targetLanguage = TranslateLanguage.hindi;
  late OnDeviceTranslator _englishHindiTranslator;
  late OnDeviceTranslator _hindiEnglishTranslator;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeServices();

    _avatarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Modify timer to only process objects, not text
    _processingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isProcessingFrame && _isInitialized) {
        _processObjectsOnly();
      }
    });
  }

  Future<void> _initializeCamera() async {
    final camera = widget.cameras.first;
    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController.initialize();
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _initializeServices() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.8);

    _textRecognizer = TextRecognizer();
    _imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.7),
    );

    // Initialize both translators
    _englishHindiTranslator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: TranslateLanguage.hindi,
    );

    _hindiEnglishTranslator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.hindi,
      targetLanguage: TranslateLanguage.english,
    );
  }

  void _toggleTranslationDirection() {
    setState(() {
      if (_sourceLanguage == TranslateLanguage.english) {
        _sourceLanguage = TranslateLanguage.hindi;
        _targetLanguage = TranslateLanguage.english;
      } else {
        _sourceLanguage = TranslateLanguage.english;
        _targetLanguage = TranslateLanguage.hindi;
      }
    });
    _processCurrentFrame(); // Reprocess frame with new translation direction
  }

  Future<void> _processObjectsOnly() async {
    if (_isProcessingFrame || !_isInitialized) return;
    _isProcessingFrame = true;
    _isAutoProcessing = true;

    try {
      final image = await _cameraController.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);

      // Only process image labels, skip text recognition
      final labels = await _imageLabeler.processImage(inputImage);

      setState(() {
        if (labels.isNotEmpty) {
          _currentEmotion = AvatarEmotion.surprised;
          _currentState = AvatarState.processing;
          _handleAIResponse("I see: ${labels.map((e) => e.label).join(", ")}");
        } else {
          _currentEmotion = AvatarEmotion.neutral;
          _currentState = AvatarState.idle;
        }
      });
    } catch (e) {
      debugPrint('Error processing frame: $e');
    } finally {
      _isProcessingFrame = false;
      _isAutoProcessing = false;
    }
  }

  Future<void> _processCurrentFrame() async {
    if (_isProcessingFrame || !_isInitialized) return;
    _isProcessingFrame = true;

    try {
      final image = await _cameraController.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);

      // Process image with ML Kit
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final labels = await _imageLabeler.processImage(inputImage);

      String detectedText = recognizedText.text.trim();

      // Only translate if text is different from last detection or manual capture
      if (detectedText.isNotEmpty &&
          (detectedText != _lastDetectedText || !_isAutoProcessing)) {
        setState(() => _isTranslating = true);
        _lastDetectedText = detectedText;

        try {
          // Choose translator based on detected script
          final translator =
              _isHindiText(detectedText)
                  ? _hindiEnglishTranslator
                  : _englishHindiTranslator;

          final translatedText = await translator.translateText(detectedText);

          setState(() {
            _translatedText = translatedText;
            _currentEmotion = AvatarEmotion.thinking;
            _currentState = AvatarState.processing;
          });

          _handleAIResponse("""Detected Text: $detectedText
Translation: $translatedText""");
        } catch (e) {
          debugPrint('Translation error: $e');
        } finally {
          setState(() => _isTranslating = false);
        }
      }

      // Update avatar state based on findings
      setState(() {
        if (labels.isNotEmpty && detectedText.isEmpty) {
          _currentEmotion = AvatarEmotion.surprised;
          _currentState = AvatarState.processing;
          _handleAIResponse("I see: ${labels.map((e) => e.label).join(", ")}");
        } else if (detectedText.isEmpty) {
          _currentEmotion = AvatarEmotion.neutral;
          _currentState = AvatarState.idle;
        }
      });
    } catch (e) {
      debugPrint('Error processing frame: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  bool _isHindiText(String text) {
    // Unicode range for Devanagari script (Hindi)
    final devanagariRange = RegExp(r'[\u0900-\u097F]');
    return devanagariRange.hasMatch(text);
  }

  void _handleAIResponse(String response) {
    setState(() {
      _chatMessages.add({'sender': 'ai', 'message': response});
    });
    _speakResponse(response);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text;
    setState(() {
      _chatMessages.add({'sender': 'user', 'message': userMessage});

      // Simple response logic
      final response = "I'm analyzing what you said about '$userMessage'";
      _chatMessages.add({'sender': 'ai', 'message': response});

      _speakResponse(response);
    });

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _speakResponse(String text) async {
    if (text == _lastSpokenText) return;

    setState(() {
      _currentState = AvatarState.speaking;
      _lastSpokenText = text;
    });

    await _flutterTts.speak(text);

    setState(() {
      _currentState = AvatarState.idle;
    });
  }

  void _cycleFilter() {
    final filters = _filters.keys.toList();
    final currentIndex = filters.indexOf(_currentFilter);
    setState(() {
      _currentFilter = filters[(currentIndex + 1) % filters.length];
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _avatarAnimationController.dispose();
    _flutterTts.stop();
    _textRecognizer.close();
    _imageLabeler.close();
    _translator.close();
    _processingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _englishHindiTranslator.close();
    _hindiEnglishTranslator.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview with filter
          Transform.scale(
            scale: 1.0,
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(_filters[_currentFilter]!),
              child: CameraPreview(_cameraController),
            ),
          ),

          // AI Avatar overlay
          Positioned(
            top: 40,
            right: 40,
            child: GestureDetector(
              onTap: () {
                setState(() => _showChat = !_showChat);
                _speakResponse(
                  "Hi! I'm your AI assistant. I can help you understand what I see.",
                );
              },
              child: SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: AIAvatarPainter(
                    emotion: _currentEmotion,
                    state: _currentState,
                    animationValue: _avatarAnimationController.value,
                  ),
                ),
              ),
            ),
          ),

          // Quick Action Buttons (Always visible)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: 20,
            child: Column(
              children: [
                _buildQuickActionButton(
                  "What do you see?",
                  Icons.visibility,
                  Colors.blue,
                ),
                const SizedBox(height: 10),
                _buildQuickActionButton(
                  "Analyze this scene",
                  Icons.analytics,
                  Colors.green,
                ),
              ],
            ),
          ),

          // Chat Interface
          if (_showChat)
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.6,
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(10),
                        itemCount: _chatMessages.length,
                        itemBuilder: (context, index) {
                          final message = _chatMessages[index];
                          final isAI = message['sender'] == 'ai';

                          return Align(
                            alignment:
                                isAI
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    isAI
                                        ? Colors.blue.withOpacity(0.3)
                                        : Colors.green.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                message['message']!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Controls overlay
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.filter_vintage,
                  label: 'Filter: ${_currentFilter.toUpperCase()}',
                  onPressed: _cycleFilter,
                ),
                _buildControlButton(
                  icon: Icons.translate,
                  label:
                      '${_sourceLanguage.name.toUpperCase()} → ${_targetLanguage.name.toUpperCase()}',
                  onPressed: _toggleTranslationDirection,
                ),
                _buildControlButton(
                  icon: Icons.camera,
                  label: 'Capture',
                  onPressed: () async {
                    setState(() => _currentState = AvatarState.processing);
                    await _processCurrentFrame();
                  },
                ),
              ],
            ),
          ),

          // Translation Overlay
          if (_translatedText.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.1,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Translation',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _translatedText,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),

          // Loading indicator for translation
          if (_isTranslating)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.5,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.cyanAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Translating...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String text, IconData icon, Color color) {
    return Material(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          _messageController.text = text;
          _sendMessage();
          _processCurrentFrame();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
