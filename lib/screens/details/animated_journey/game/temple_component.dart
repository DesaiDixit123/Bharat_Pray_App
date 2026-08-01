import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TempleComponent extends PositionComponent {
  final String templeName;
  final bool isOnRightSide;

  final Paint _templePaint = Paint()..color = Colors.redAccent;
  final Paint _roofPaint = Paint()..color = Colors.amber;

  TempleComponent({
    required this.templeName,
    this.isOnRightSide = true,
  }) : super(size: Vector2(100, 100), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw Temple Building
    canvas.drawRect(Rect.fromLTWH(10, 40, 80, 60), _templePaint);
    
    // Draw Temple Roof (Triangle)
    final path = Path()
      ..moveTo(50, 0)
      ..lineTo(100, 40)
      ..lineTo(0, 40)
      ..close();
    canvas.drawPath(path, _roofPaint);

    // Draw Door
    canvas.drawRect(Rect.fromLTWH(35, 70, 30, 30), Paint()..color = Colors.brown);

    // Draw Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: templeName,
        style: const TextStyle(color: Colors.white, fontSize: 12, backgroundColor: Colors.black54),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(maxWidth: size.x);
    textPainter.paint(canvas, Offset(0, -20));
  }
}
