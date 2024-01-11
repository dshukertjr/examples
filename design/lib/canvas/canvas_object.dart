import 'dart:math';
import 'dart:ui';

abstract class CanvasObject {
  final Offset position;
  final Color color;

  factory CanvasObject.fromJson(Map<String, dynamic> json) {
    final objectType = json['object_type'];
    if (objectType == UserCursor.type) {
      return UserCursor.fromJson(json);
    } else if (objectType == CanvasCircle.type) {
      return CanvasCircle.fromJson(json);
    } else if (objectType == CanvasRectangle.type) {
      return CanvasRectangle.fromJson(json);
    } else {
      throw UnimplementedError('Unknown type ${json['object_type']}');
    }
  }

  CanvasObject({
    required this.position,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    if (this is UserCursor) {
      return toJson();
    } else if (this is CanvasRectangle) {
      return toJson();
    } else {
      throw UnimplementedError(
          'toJson not yet implemented for type $runtimeType');
    }
  }
}

class UserCursor extends CanvasObject {
  static String type = 'cursor';

  UserCursor({
    required super.position,
    required super.color,
  });

  UserCursor.fromJson(Map<String, dynamic> json)
      : super(
            position: Offset(json['position']['x'], json['position']['y']),
            color: Color(json['color']));

  @override
  Map<String, dynamic> toJson() {
    return {
      'object_type': type,
      'color': color.value,
      'position': {
        'x': position.dx,
        'y': position.dy,
      }
    };
  }
}

class CanvasCircle extends CanvasObject {
  static String type = 'circle';

  final double radius;

  CanvasCircle({
    required this.radius,
    required super.position,
    required super.color,
  });

  CanvasCircle.fromJson(Map<String, dynamic> json)
      : radius = json['radius'],
        super(
          position: Offset(json['position']['x'], json['position']['y']),
          color: Color(json['color']),
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'object_type': type,
      'color': color.value,
      'position': {
        'x': position.dx,
        'y': position.dy,
      },
      'radius': radius,
    };
  }

  CanvasCircle copyWith({
    double? radius,
    Offset? position,
    Color? color,
  }) {
    return CanvasCircle(
      radius: radius ?? this.radius,
      position: position ?? this.position,
      color: color ?? this.color,
    );
  }

  bool intersectsWith(Offset point) {
    final circleCenter = position;
    final centerToPointerDistance = (point - circleCenter).distance;
    return radius > centerToPointerDistance;
  }
}

class CanvasRectangle extends CanvasObject {
  static String type = 'rectangle';

  final Offset bottomRight;

  CanvasRectangle({
    required super.position,
    required super.color,
    required this.bottomRight,
  });

  CanvasRectangle.fromJson(Map<String, dynamic> json)
      : bottomRight = Offset(
          json['bottom_right']['x'],
          json['bottom_right']['y'],
        ),
        super(
          position: Offset(json['position']['x'], json['position']['y']),
          color: Color(json['color']),
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'object_type': type,
      'color': color.value,
      'position': {
        'x': position.dx,
        'y': position.dy,
      },
      'bottom_right': {
        'x': bottomRight.dx,
        'y': bottomRight.dy,
      },
    };
  }

  CanvasRectangle copyWith({
    Offset? position,
    Color? color,
    Offset? bottomRight,
  }) {
    return CanvasRectangle(
      position: position ?? this.position,
      color: color ?? this.color,
      bottomRight: bottomRight ?? this.bottomRight,
    );
  }

  bool intersectsWith(Offset point) {
    final minX = min(position.dx, bottomRight.dx);
    final maxX = max(position.dx, bottomRight.dx);
    final minY = min(position.dy, bottomRight.dy);
    final maxY = max(position.dy, bottomRight.dy);
    return minX < point.dx &&
        point.dx < maxX &&
        minY < point.dy &&
        point.dy < maxY;
  }
}
