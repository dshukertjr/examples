import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:uuid/uuid.dart';

/// Handy extension method to create random colors
extension RandomColor on Color {
  static Color getRandom() {
    return Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  }

  /// Quick and dirty method to create a random color from the userID
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

/// Data model for the cursors displayed on the canvas.
class UserCursor extends SyncedObject {
  static String type = 'cursor';

  final Offset? position;
  final Color color;

  UserCursor({
    required super.id,
    required this.position,
  }) : color = RandomColor.getRandomFromId(id);

  UserCursor.fromJson(Map<String, dynamic> json)
      : position = json['position'] == null
            ? null
            : Offset(json['position']['x'], json['position']['y']),
        color = RandomColor.getRandomFromId(json['id']),
        super(id: json['id']);

  @override
  Map<String, dynamic> toJson() {
    return {
      'object_type': type,
      'id': id,
      if (position != null)
        'position': {
          'x': position!.dx,
          'y': position!.dy,
        }
    };
  }
}

/// Base model for any design objects displayed on the canvas.
abstract class CanvasObject extends SyncedObject {
  final Color color;
  final String? imagePath;
  final Image? image;
  final double width;
  final double height;

  CanvasObject({
    required super.id,
    required this.color,
    required this.imagePath,
    required this.image,
    required this.width,
    required this.height,
  });

  factory CanvasObject.fromJson(Map<String, dynamic> json) {
    if (json['object_type'] == Circle.type) {
      return Circle.fromJson(json);
    } else if (json['object_type'] == Rectangle.type) {
      return Rectangle.fromJson(json);
    } else if (json['object_type'] == Polygon.type) {
      return Polygon.fromJson(json);
    } else {
      throw UnimplementedError('Unknown object_type: ${json['object_type']}');
    }
  }

  /// Standard copyWith to create a new instance with updated values
  CanvasObject copyWith({
    String? imagePath,
    Image? image,
  }) {
    if (this is Circle) {
      return copyWith(
        imagePath: imagePath ?? this.imagePath,
        image: image ?? this.image,
      );
    } else if (this is Rectangle) {
      return copyWith(
        imagePath: imagePath ?? this.imagePath,
        image: image ?? this.image,
      );
    }
    throw UnimplementedError('Unknown object type');
  }

  /// Whether or not the object intersects with the given point.
  bool intersectsWith(Offset point);

  /// Moves the object to a new position
  CanvasObject move(Offset delta);

  Rect get boundingRect;
}

/// Circle displayed on the canvas.
class Circle extends CanvasObject {
  static String type = 'circle';

  final Offset center;
  final double radius;

  Circle({
    required super.id,
    required super.width,
    required super.height,
    required super.color,
    required super.imagePath,
    required super.image,
    required this.radius,
    required this.center,
  });

  Circle.fromJson(Map<String, dynamic> json)
      : radius = json['radius'],
        center = Offset(json['center']['x'], json['center']['y']),
        super(
            id: json['id'],
            color: Color(json['color']),
            imagePath: json['image_path'],
            image: null,
            width: json['radius'] * 2,
            height: json['radius'] * 2);

  /// Constructor to be used when first starting to draw the object on the canvas
  Circle.createNew(this.center)
      : radius = 0,
        super(
          id: const Uuid().v4(),
          color: RandomColor.getRandom(),
          imagePath: null,
          image: null,
          width: 0,
          height: 0,
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'object_type': type,
      'id': id,
      'color': color.value,
      if (imagePath != null) 'image_path': imagePath,
      'center': {
        'x': center.dx,
        'y': center.dy,
      },
      'radius': radius,
    };
  }

  @override
  Circle copyWith({
    double? radius,
    Offset? center,
    Color? color,
    String? imagePath,
    Image? image,
  }) {
    return Circle(
      radius: radius ?? this.radius,
      center: center ?? this.center,
      id: id,
      color: color ?? this.color,
      imagePath: imagePath ?? this.imagePath,
      image: image ?? this.image,
      width: (radius ?? this.radius) * 2,
      height: (radius ?? this.radius) * 2,
    );
  }

  @override
  bool intersectsWith(Offset point) {
    final centerToPointerDistance = (point - center).distance;
    return radius > centerToPointerDistance;
  }

  @override
  Circle move(Offset delta) {
    return copyWith(center: center + delta);
  }

  @override
  Rect get boundingRect =>
      Rect.fromCenter(center: center, width: width, height: height);
}

/// Rectangle displayed on the canvas.
class Rectangle extends CanvasObject {
  static String type = 'rectangle';

  final Offset topLeft;
  final Offset bottomRight;

  Rectangle({
    required super.id,
    required super.width,
    required super.height,
    required super.color,
    required super.imagePath,
    required super.image,
    required this.topLeft,
    required this.bottomRight,
  });

  Rectangle.fromJson(Map<String, dynamic> json)
      : bottomRight =
            Offset(json['bottom_right']['x'], json['bottom_right']['y']),
        topLeft = Offset(json['top_left']['x'], json['top_left']['y']),
        super(
            id: json['id'],
            color: Color(json['color']),
            imagePath: json['image_path'],
            image: null,
            width: (json['top_left']['x'] - json['bottom_right']['x'] as double)
                .abs(),
            height:
                (json['top_left']['y'] - json['bottom_right']['y'] as double)
                    .abs());

  /// Constructor to be used when first starting to draw the object on the canvas
  Rectangle.createNew(Offset startingPoint)
      : topLeft = startingPoint,
        bottomRight = startingPoint,
        super(
          color: RandomColor.getRandom(),
          imagePath: null,
          image: null,
          id: const Uuid().v4(),
          width: 0,
          height: 0,
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'object_type': type,
      'id': id,
      'color': color.value,
      if (imagePath != null) 'image_path': imagePath,
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
  Rectangle copyWith({
    Offset? topLeft,
    Offset? bottomRight,
    Color? color,
    String? imagePath,
    Image? image,
  }) {
    return Rectangle(
      id: id,
      topLeft: topLeft ?? this.topLeft,
      bottomRight: bottomRight ?? this.bottomRight,
      color: color ?? this.color,
      imagePath: imagePath ?? this.imagePath,
      image: image ?? this.image,
      width: ((topLeft ?? this.topLeft) - (bottomRight ?? this.bottomRight))
          .dx
          .abs(),
      height: ((topLeft ?? this.topLeft) - (bottomRight ?? this.bottomRight))
          .dy
          .abs(),
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

  @override
  Rectangle move(Offset delta) {
    return copyWith(
      topLeft: topLeft + delta,
      bottomRight: bottomRight + delta,
    );
  }

  @override
  Rect get boundingRect => Rect.fromPoints(topLeft, bottomRight);
}

/// A polygon drawn using the pen tool.
class Polygon extends CanvasObject {
  static String type = 'polygon';

  Polygon({
    required this.points,
    required this.isClosed,
    required super.id,
    required super.color,
    required super.imagePath,
    required super.image,
    required super.width,
    required super.height,
  });

  /// List of points that the pen tool has drawn
  final List<Offset> points;

  /// Whether the polygon is closed or not
  final bool isClosed;

  Polygon.fromJson(Map<String, dynamic> json)
      : points =
            json['points'].map<Offset>((e) => Offset(e['x'], e['y'])).toList(),
        isClosed = true,
        super(
          id: json['id'],
          color: Color(json['color']),
          imagePath: json['image_path'],
          image: null,
          width: 0,
          height: 0,
        );

  @override
  double get width {
    return points.map<double>((e) => e.dx).reduce(max) -
        List.from(points).map<double>((e) => e.dx).reduce(min);
  }

  @override
  double get height {
    return points.map<double>((e) => e.dy).reduce(max) -
        List.from(points).map<double>((e) => e.dy).reduce(min);
  }

  Polygon.createNew(Offset startingPoint)
      : points = [startingPoint],
        isClosed = false,
        super(
          id: const Uuid().v4(),
          color: RandomColor.getRandom(),
          imagePath: null,
          image: null,
          width: 0,
          height: 0,
        );

  @override
  Rect get boundingRect {
    final minX = points.map((e) => e.dx).reduce(min);
    final maxX = points.map((e) => e.dx).reduce(max);
    final minY = points.map((e) => e.dy).reduce(min);
    final maxY = points.map((e) => e.dy).reduce(max);
    return Rect.fromPoints(Offset(minX, minY), Offset(maxX, maxY));
  }

  @override
  bool intersectsWith(Offset point) {
    final path = Path();
    path.addPolygon(points, true);
    return path.contains(point);
  }

  @override
  CanvasObject move(Offset delta) {
    return copyWith(
      points: points.map((e) => e + delta).toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'object_type': type,
      'id': id,
      'color': color.value,
      if (imagePath != null) 'image_path': imagePath,
      'points': points.map((e) => {'x': e.dx, 'y': e.dy}).toList(),
    };
  }

  @override
  Polygon copyWith({
    List<Offset>? points,
    bool? isClosed,
    Color? color,
    String? imagePath,
    Image? image,
  }) {
    return Polygon(
      points: points ?? this.points,
      isClosed: isClosed ?? this.isClosed,
      id: id,
      color: color ?? this.color,
      imagePath: imagePath ?? this.imagePath,
      image: image ?? this.image,
      width: width,
      height: height,
    );
  }

  CanvasObject addPoint(Offset newPoint) {
    return copyWith(points: [...points, newPoint]);
  }

  CanvasObject close() {
    return copyWith(isClosed: true);
  }
}
