import 'package:design/canvas/canvas_object.dart';
import 'package:flutter/material.dart';

class CanvasPainter extends CustomPainter {
  // Map<int, Offset> _otherUsers = {};
  final Map<int, SyncedObject> canvasObjects;

  final SyncedObject? currentlyDrawingObject;

  CanvasPainter({
    required this.canvasObjects,
    required this.currentlyDrawingObject,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFFFF));
    for (final canvasObject
        in canvasObjects.values.where((element) => element is! UserCursor)) {
      if (canvasObject is CanvasCircle) {
        final position = canvasObject.position;
        final radius = canvasObject.radius;
        canvas.drawCircle(
            position, radius, Paint()..color = canvasObject.color);
      } else if (canvasObject is CanvasRectangle) {
        final position = canvasObject.position;
        final bottomRight = canvasObject.bottomRight;
        canvas.drawRect(
            Rect.fromLTRB(
                position.dx, position.dy, bottomRight.dx, bottomRight.dy),
            Paint()..color = canvasObject.color);
      }
    }

    for (final canvasObject in canvasObjects.values.whereType<UserCursor>()) {
      final position = canvasObject.position;
      canvas.drawPath(
          Path()
            ..moveTo(position.dx, position.dy)
            ..lineTo(position.dx + 7.145, position.dy + 22.42)
            ..lineTo(position.dx + 10.175, position.dy + 12.965)
            ..lineTo(position.dx + 19.925, position.dy + 12.255)
            ..lineTo(position.dx, position.dy),
          Paint()..color = canvasObject.color);
    }
  }

  @override
  bool shouldRepaint(CanvasPainter painter) {
    return true;
  }
}
