import 'dart:async';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum PlayerState { idle, walking, praying }

class PlayerComponent extends PositionComponent with HasGameRef {
  PlayerState state = PlayerState.idle;
  
  double _time = 0;
  double baseY = 0;

  PlayerComponent() : super(anchor: Anchor.bottomCenter, size: Vector2(100, 140));

  @override
  void update(double dt) {
    super.update(dt);
    
    if (baseY == 0) {
      baseY = position.y;
    }
    
    if (state == PlayerState.walking) {
      _time += dt * 8; // Animation speed for leg swinging
      // Gentle body bobbing
      position.y = baseY + (math.sin(_time * 2).abs() * -2);
    } else {
      // Smoothly reset legs and position
      _time = 0;
      position.y = baseY;
    }
  }

  @override
  void render(Canvas canvas) {
    // Hidden intentionally to show the Flutter native GIF overlay instead
  }
  
  void _drawLeg(Canvas canvas, double x, double y, Paint skin, Paint leather) {
    // Calf/Ankle
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y - 5), width: 14, height: 20), const Radius.circular(6)),
      skin,
    );
    // Sandal sole
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y + 8), width: 16, height: 6), const Radius.circular(3)),
      leather,
    );
    // Sandal strap (V shape)
    canvas.drawLine(Offset(x - 6, y + 5), Offset(x, y + 8), Paint()..color = Colors.black87..strokeWidth = 2);
    canvas.drawLine(Offset(x + 6, y + 5), Offset(x, y + 8), Paint()..color = Colors.black87..strokeWidth = 2);
  }
  
  void _drawArm(Canvas canvas, double x, double y, double swing, Paint skin, Paint robe) {
    // Upper arm (Sleeve)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y + 15), width: 18, height: 32), const Radius.circular(9)),
      robe,
    );
    // Lower arm (Skin)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y + 36 + swing), width: 13, height: 26), const Radius.circular(6)),
      skin,
    );
  }
}
