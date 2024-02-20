import 'package:canvas/canvas/canvas_object.dart';
import 'package:flutter/material.dart';

class CanvasPainter extends CustomPainter {
  final Map<String, UserCursor> userCursors;
  final Map<String, CanvasObject> canvasObjects;
  final String? selectedObjectId;

  CanvasPainter({
    required this.userCursors,
    required this.canvasObjects,
    required this.selectedObjectId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw each canvas objects
    for (final canvasObject in canvasObjects.values) {
      if (canvasObject is Circle) {
        canvas.drawCircle(
          canvasObject.center,
          canvasObject.radius,
          Paint()..color = canvasObject.color,
        );
      } else if (canvasObject is Rectangle) {
        final topLeft = canvasObject.topLeft;
        final bottomRight = canvasObject.bottomRight;
        canvas.drawRect(
          Rect.fromLTRB(topLeft.dx, topLeft.dy, bottomRight.dx, bottomRight.dy),
          Paint()..color = canvasObject.color,
        );
      }
    }

    // Draw blue rectangle around selected object
    if (selectedObjectId != null) {
      final selectedObject = canvasObjects[selectedObjectId!];
      late final Offset topLeft;
      late final Offset bottomRight;
      if (selectedObject is Circle) {
        topLeft = Offset(
          selectedObject.center.dx - selectedObject.radius,
          selectedObject.center.dy - selectedObject.radius,
        );
        bottomRight = Offset(
          selectedObject.center.dx + selectedObject.radius,
          selectedObject.center.dy + selectedObject.radius,
        );
      } else if (selectedObject is Rectangle) {
        topLeft = selectedObject.topLeft;
        bottomRight = selectedObject.bottomRight;
      }
      canvas.drawRect(
        Rect.fromLTRB(
          topLeft.dx,
          topLeft.dy,
          bottomRight.dx,
          bottomRight.dy,
        ),
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Draw the cursors
    for (final userCursor in userCursors.values) {
      final position = userCursor.position;
      canvas.drawPath(
          Path()
            ..moveTo(position.dx, position.dy)
            ..lineTo(position.dx + 14.29, position.dy + 44.84)
            ..lineTo(position.dx + 20.35, position.dy + 25.93)
            ..lineTo(position.dx + 39.85, position.dy + 24.51)
            ..lineTo(position.dx, position.dy),
          Paint()..color = userCursor.color);
    }
  }

  @override
  bool shouldRepaint(oldDelegate) => true;
}
