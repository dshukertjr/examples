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
      final paint = Paint();
      final image = canvasObject.image;

      if (image != null) {
        canvas.saveLayer(canvasObject.boundingRect, paint);
      } else {
        paint.color = canvasObject.color;
      }

      if (canvasObject is Circle) {
        canvas.drawCircle(
          canvasObject.center,
          canvasObject.radius,
          paint,
        );
      } else if (canvasObject is Rectangle) {
        final topLeft = canvasObject.topLeft;
        final bottomRight = canvasObject.bottomRight;
        canvas.drawRect(
          Rect.fromLTRB(topLeft.dx, topLeft.dy, bottomRight.dx, bottomRight.dy),
          paint,
        );
      }
      if (image != null) {
        paintImage(
          canvas: canvas,
          rect: canvasObject.boundingRect,
          image: image,
          fit: BoxFit.cover,
          blendMode: BlendMode.srcIn,
        );
        canvas.restore();
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

      // Draw the blue stroke surrounding the selected object
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

      // Display the dimention of the selected object below it
      const textStyle = TextStyle(
        color: Colors.white,
        fontSize: 12,
      );
      final textSpan = TextSpan(
        text:
            '${selectedObject!.width.round()} x ${selectedObject.height.round()}',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(
        minWidth: 0,
        maxWidth: double.infinity,
      );
      final textPositionX =
          topLeft.dx + (selectedObject.width - textPainter.width) / 2;
      final textPositionY = bottomRight.dy + 8;
      final offset = Offset(textPositionX, textPositionY);
      const paddingX = 4.0;
      const paddingY = 2.0;
      canvas.drawRect(
          Rect.fromLTWH(
              textPositionX - paddingX,
              textPositionY - paddingY,
              textPainter.width + paddingX * 2,
              textPainter.height + paddingY * 2),
          Paint()..color = Colors.blue);
      textPainter.paint(canvas, offset);
    }

    // Draw the cursors
    for (final userCursor in userCursors.values) {
      final position = userCursor.position;
      if (position != null) {
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
  }

  @override
  bool shouldRepaint(oldDelegate) => true;
}
