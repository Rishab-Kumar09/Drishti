import 'package:flutter/material.dart';
import 'dart:math' as math;

enum AvatarEmotion { neutral, thinking, happy, surprised, confused }

enum AvatarState { idle, speaking, listening, processing }

class AIAvatarPainter extends CustomPainter {
  final AvatarEmotion emotion;
  final AvatarState state;
  final double animationValue;
  final Color primaryColor;
  final Color accentColor;

  AIAvatarPainter({
    this.emotion = AvatarEmotion.neutral,
    this.state = AvatarState.idle,
    required this.animationValue,
    this.primaryColor = Colors.cyanAccent,
    this.accentColor = Colors.pinkAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw pulsing background
    final bgPaint =
        Paint()
          ..color = primaryColor.withOpacity(
            0.1 + 0.1 * math.sin(animationValue * math.pi * 2),
          )
          ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw orbital rings
    _drawOrbitalRings(canvas, center, radius);

    // Draw core
    final corePaint =
        Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius * 0.3, corePaint);

    // Draw emotion expression
    switch (emotion) {
      case AvatarEmotion.neutral:
        _drawNeutralExpression(canvas, center, radius);
      case AvatarEmotion.thinking:
        _drawThinkingExpression(canvas, center, radius);
      case AvatarEmotion.happy:
        _drawHappyExpression(canvas, center, radius);
      case AvatarEmotion.surprised:
        _drawSurprisedExpression(canvas, center, radius);
      case AvatarEmotion.confused:
        _drawConfusedExpression(canvas, center, radius);
    }

    // Draw state animation
    switch (state) {
      case AvatarState.idle:
        _drawIdleState(canvas, center, radius);
      case AvatarState.speaking:
        _drawSpeakingState(canvas, center, radius);
      case AvatarState.listening:
        _drawListeningState(canvas, center, radius);
      case AvatarState.processing:
        _drawProcessingState(canvas, center, radius);
    }
  }

  void _drawOrbitalRings(Canvas canvas, Offset center, double radius) {
    final orbitalPaint =
        Paint()
          ..color = primaryColor.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // Draw rotating orbital rings
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animationValue * math.pi * 2);

    for (int i = 0; i < 3; i++) {
      final angle = (i * math.pi * 2 / 3) + animationValue;
      final path =
          Path()..addOval(
            Rect.fromCircle(
              center: Offset.zero,
              radius: radius * (0.5 + i * 0.15),
            ),
          );
      canvas.drawPath(path, orbitalPaint);
    }

    canvas.restore();
  }

  void _drawNeutralExpression(Canvas canvas, Offset center, double radius) {
    final paint =
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    // Draw simple line for neutral expression
    canvas.drawLine(
      center.translate(-radius * 0.15, 0),
      center.translate(radius * 0.15, 0),
      paint,
    );
  }

  void _drawThinkingExpression(Canvas canvas, Offset center, double radius) {
    final paint =
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    // Draw spiral pattern
    final path = Path();
    for (double i = 0; i < 2 * math.pi; i += 0.1) {
      final x = math.cos(i + animationValue) * (i * radius * 0.05);
      final y = math.sin(i + animationValue) * (i * radius * 0.05);
      if (i == 0) {
        path.moveTo(center.dx + x, center.dy + y);
      } else {
        path.lineTo(center.dx + x, center.dy + y);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawHappyExpression(Canvas canvas, Offset center, double radius) {
    final paint =
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    // Draw smile
    final rect = Rect.fromCenter(
      center: center,
      width: radius * 0.4,
      height: radius * 0.4,
    );
    canvas.drawArc(rect, 0, math.pi, false, paint);
  }

  void _drawSurprisedExpression(Canvas canvas, Offset center, double radius) {
    final paint =
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    // Draw expanding circles
    for (int i = 0; i < 3; i++) {
      final currentRadius =
          radius *
          0.2 *
          (1 + i * 0.3) *
          (1 + 0.1 * math.sin(animationValue * math.pi * 2));
      canvas.drawCircle(center, currentRadius, paint);
    }
  }

  void _drawConfusedExpression(Canvas canvas, Offset center, double radius) {
    final paint =
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    // Draw question mark-like pattern
    final path = Path();
    for (double i = 0; i < math.pi; i += 0.1) {
      final x = math.cos(i * 2 + animationValue) * (radius * 0.2);
      final y = math.sin(i * 3) * (radius * 0.2);
      if (i == 0) {
        path.moveTo(center.dx + x, center.dy + y);
      } else {
        path.lineTo(center.dx + x, center.dy + y);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawIdleState(Canvas canvas, Offset center, double radius) {
    // Subtle pulsing already handled in background
  }

  void _drawSpeakingState(Canvas canvas, Offset center, double radius) {
    final paint =
        Paint()
          ..color = primaryColor.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // Draw audio wave-like pattern
    for (int i = 0; i < 3; i++) {
      final wave = math.sin(animationValue * math.pi * 4 + i);
      final rect = Rect.fromCenter(
        center: center,
        width: radius * (0.8 + wave * 0.1),
        height: radius * (0.8 + wave * 0.1),
      );
      canvas.drawOval(rect, paint);
    }
  }

  void _drawListeningState(Canvas canvas, Offset center, double radius) {
    final paint =
        Paint()
          ..color = primaryColor.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // Draw ripple effect
    for (int i = 0; i < 3; i++) {
      final progress = (animationValue + i / 3) % 1.0;
      canvas.drawCircle(
        center,
        radius * progress,
        paint..color = primaryColor.withOpacity(0.5 * (1 - progress)),
      );
    }
  }

  void _drawProcessingState(Canvas canvas, Offset center, double radius) {
    final paint =
        Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    // Draw rotating dots
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animationValue * math.pi * 2);

    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final x = math.cos(angle) * radius * 0.5;
      final y = math.sin(angle) * radius * 0.5;
      final dotRadius =
          radius *
          0.05 *
          (1 + 0.5 * math.sin(animationValue * math.pi * 2 + i));
      canvas.drawCircle(Offset(x, y), dotRadius, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(AIAvatarPainter oldDelegate) {
    return oldDelegate.emotion != emotion ||
        oldDelegate.state != state ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
