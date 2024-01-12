import 'dart:convert';
import 'dart:math';
import 'dart:ui';

extension RandomColor on Color {
  static Color getRandom() {
    return Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  }

  static Color getRandomFromId(String id) {
    final seed = utf8.encode(id).reduce((value, element) => value + element);
    return Color((Random(seed).nextDouble() * 0xFFFFFF).toInt())
        .withOpacity(1.0);
  }
}

/// Objects that are being synced in realtime over broadcast
///
/// Includes mouse cursor and design objects
abstract class SyncedObject {
  /// UUID unique identifier of the object
  final String id;

  factory SyncedObject.fromJson(Map<String, dynamic> json) {
    final objectType = json['object_type'];
    if (objectType == UserCursor.type) {
      return UserCursor.fromJson(json);
    } else {
      return CanvasObject.fromJson(json);
    }
  }

  SyncedObject({
    required this.id,
  });

  Map<String, dynamic> toJson();
}

class UserCursor extends SyncedObject {
  static String type = 'cursor';

  final Offset position;
  final Color color;

  UserCursor({
    required super.id,
    required this.position,
  }) : color = RandomColor.getRandomFromId(id);

  UserCursor.fromJson(Map<String, dynamic> json)
      : position = Offset(json['position']['x'], json['position']['y']),
        color = RandomColor.getRandomFromId(json['id']),
        super(id: json['id']);

  @override
  Map<String, dynamic> toJson() {
    return {
      'object_type': type,
      'id': id,
      'position': {
        'x': position.dx,
        'y': position.dy,
      }
    };
  }
}

abstract class CanvasObject extends SyncedObject {
  final Color color;

  CanvasObject({
    required super.id,
    required this.color,
  });

  factory CanvasObject.fromJson(Map<String, dynamic> json) {
    if (json['object_type'] == CanvasCircle.type) {
      return CanvasCircle.fromJson(json);
    } else if (json['object_type'] == CanvasRectangle.type) {
      return CanvasRectangle.fromJson(json);
    } else {
      throw UnimplementedError('Unknown object_type: ${json['object_type']}');
    }
  }

  /// Whether or not the object intersects with the given point.
  bool intersectsWith(Offset point);

  CanvasObject copyWith();
}

class CanvasCircle extends CanvasObject {
  static String type = 'circle';

  final Offset center;
  final double radius;

  CanvasCircle({
    required super.id,
    required super.color,
    required this.radius,
    required this.center,
  });

  CanvasCircle.fromJson(Map<String, dynamic> json)
      : radius = json['radius'],
        center = Offset(json['center']['x'], json['center']['y']),
        super(id: json['id'], color: Color(json['color']));

  @override
  Map<String, dynamic> toJson() {
    return {
      'object_type': type,
      'id': id,
      'color': color.value,
      'center': {
        'x': center.dx,
        'y': center.dy,
      },
      'radius': radius,
    };
  }

  @override
  CanvasCircle copyWith({
    double? radius,
    Offset? center,
    Color? color,
  }) {
    return CanvasCircle(
      radius: radius ?? this.radius,
      center: center ?? this.center,
      id: id,
      color: color ?? this.color,
    );
  }

  @override
  bool intersectsWith(Offset point) {
    final centerToPointerDistance = (point - center).distance;
    return radius > centerToPointerDistance;
  }
}

class CanvasRectangle extends CanvasObject {
  static String type = 'rectangle';

  final Offset topLeft;
  final Offset bottomRight;

  CanvasRectangle({
    required super.id,
    required super.color,
    required this.topLeft,
    required this.bottomRight,
  });

  CanvasRectangle.fromJson(Map<String, dynamic> json)
      : bottomRight =
            Offset(json['bottom_right']['x'], json['bottom_right']['y']),
        topLeft = Offset(json['top_left']['x'], json['top_left']['y']),
        super(id: json['id'], color: Color(json['color']));

  @override
  Map<String, dynamic> toJson() {
    return {
      'object_type': type,
      'id': id,
      'color': color.value,
      'top_left': {
        'x': topLeft.dx,
        'y': topLeft.dy,
      },
      'bottom_right': {
        'x': bottomRight.dx,
        'y': bottomRight.dy,
      },
    };
  }

  @override
  CanvasRectangle copyWith({
    Offset? topLeft,
    Offset? bottomRight,
    Color? color,
  }) {
    return CanvasRectangle(
      topLeft: topLeft ?? this.topLeft,
      id: id,
      bottomRight: bottomRight ?? this.bottomRight,
      color: color ?? this.color,
    );
  }

  @override
  bool intersectsWith(Offset point) {
    final minX = min(topLeft.dx, bottomRight.dx);
    final maxX = max(topLeft.dx, bottomRight.dx);
    final minY = min(topLeft.dy, bottomRight.dy);
    final maxY = max(topLeft.dy, bottomRight.dy);
    return minX < point.dx &&
        point.dx < maxX &&
        minY < point.dy &&
        point.dy < maxY;
  }
}