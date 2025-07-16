# Dṛiṣhṭi (VisionJar) 🔥

> *Sanskrit for "Vision" or "Perception"*

An Iron Man-style visual assistant mobile app that transforms your phone into a futuristic HUD interface with real-time object detection, voice feedback, and live translation capabilities.

## 🚀 Features

### Current Implementation (v1.0)
- **📱 Fullscreen Camera Preview** - High-performance 30 FPS camera feed
- **🎯 Iron Man HUD Overlay** - Animated corner brackets and scanning lines
- **✨ Smooth Animations** - Hardware-accelerated UI with pulsing effects
- **🌌 Sci-Fi Design** - Orbitron font and cyan neon aesthetics
- **📐 Landscape Mode** - Optimized for immersive experience

### Planned Features (Roadmap)
- **🤖 Real-time Object Detection** - ML Kit integration for instant object recognition
- **🗣️ Jarvis-style Voice Feedback** - TTS announcements of detected objects
- **🌍 Multi-language Translation** - Sanskrit/English/Hindi live translation
- **🔄 Mode Switching** - Object Mode, Text Mode, Plant Mode
- **🎭 Face Recognition** - Identify known faces with emotion detection
- **🧠 GPT-4 Vision Integration** - Deep insights and analysis

## 🛠️ Tech Stack

- **Framework**: Flutter (Dart)
- **Camera**: Flutter Camera Plugin
- **ML/AI**: Google ML Kit, TensorFlow Lite
- **Voice**: Flutter TTS
- **Translation**: Google Translate API
- **Fonts**: Google Fonts (Orbitron)
- **Platform**: Android & iOS

## 📋 Prerequisites

- Flutter SDK (3.7.2 or higher)
- Android Studio / VS Code
- Android device with camera
- Developer mode enabled on device

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/Rishab-Kumar09/Drishti.git
   cd Drishti
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Screenshots

*Coming soon - Iron Man HUD interface in action!*

## 🎯 Performance Targets

- **Detection Latency**: < 300ms per frame
- **Object Recognition**: 80%+ accuracy on common objects
- **Translation Speed**: < 1 second per word/phrase
- **Wow Factor**: Users say "Whoa that's cool!" ✨

## 🔧 Development Setup

### Android Configuration
- **Min SDK**: 21
- **Target SDK**: 33
- **NDK Version**: 27.0.12077973
- **Permissions**: Camera, Hardware Camera, Autofocus

### Dependencies
```yaml
dependencies:
  flutter: sdk: flutter
  camera: ^0.11.2
  google_mlkit_object_detection: ^0.15.0
  flutter_tts: ^4.2.3
  google_mlkit_translation: ^0.13.0
  google_fonts: ^6.2.1
```

## 🏗️ Architecture

```
lib/
├── main.dart              # App entry point & camera setup
├── screens/
│   └── camera_screen.dart # Main camera interface
├── widgets/
│   └── hud_painter.dart   # Custom HUD overlay
├── services/
│   ├── ml_service.dart    # ML Kit integration
│   ├── tts_service.dart   # Text-to-speech
│   └── translation_service.dart # Translation API
└── models/
    └── detection_result.dart # Data models
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by Iron Man's JARVIS interface
- Built with Flutter's powerful camera capabilities
- Powered by Google's ML Kit for object detection


