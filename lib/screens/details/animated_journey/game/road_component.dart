import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class RoadComponent extends PositionComponent with HasGameRef {
  double _scrollOffset = 0.0;
  
  final Paint _grassPaint = Paint()..color = const Color(0xFF4CAF50);
  final Paint _roadPaint = Paint()..color = const Color(0xFF6B6B6B);
  final Paint _linePaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 5
    ..style = PaintingStyle.stroke;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = gameRef.size;
  }
  
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  void scroll(double delta) {
    _scrollOffset += delta;
    if (_scrollOffset > 100) {
      _scrollOffset -= 100; // Reset offset to keep lines looping
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Draw Grass background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _grassPaint);

    // 2. Draw Main Road
    final roadWidth = size.x * 0.6;
    final roadRect = Rect.fromLTWH(
      (size.x - roadWidth) / 2, 
      0, 
      roadWidth, 
      size.y
    );
    canvas.drawRect(roadRect, _roadPaint);

    // 3. Draw Dashed Center Line
    double startY = -100 + _scrollOffset;
    while (startY < size.y) {
      canvas.drawLine(
        Offset(size.x / 2, startY),
        Offset(size.x / 2, startY + 50),
        _linePaint,
      );
      startY += 100;
    }
  }
}
