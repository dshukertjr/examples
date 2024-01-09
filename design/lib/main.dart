// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';

import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  Supabase.initialize(
      url: 'http://127.0.0.1:54321',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 60,
      ));
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ArtBoardPage(),
    );
  }
}

class ArtBoardPainter extends CustomPainter {
  // Map<int, Offset> _otherUsers = {};
  final Map<int, CanvasObject> canvasObjects;

  final CanvasObject? currentlyDrawingObject;

  ArtBoardPainter({
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
  bool shouldRepaint(ArtBoardPainter painter) {
    return true;
  }
}

enum DrawMode {
  pointer,
  rectangle,
  oval,
  line,
}

class ArtBoardPage extends StatefulWidget {
  const ArtBoardPage({super.key});

  @override
  State<ArtBoardPage> createState() => _ArtBoardPageState();
}

extension RandomColor on Color {
  static Color getRandom() {
    return Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  }
}

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

class _ArtBoardPageState extends State<ArtBoardPage> {
  final Map<int, CanvasObject> _canvasObjects = {};

  late final RealtimeChannel _cursorChannel;

  late final Color _myColor;

  DrawMode _currentMode = DrawMode.pointer;

  CanvasObject? _currentlyDrawingObject;

  Offset _cursorPosition = const Offset(0, 0);

  @override
  void initState() {
    super.initState();

    _myColor = RandomColor.getRandom();

    _cursorChannel = supabase
        .channel('cursor', opts: const RealtimeChannelConfig(self: true))
        .onBroadcast(
            event: 'cursor',
            callback: (payload) {
              final cursor = UserCursor.fromJson(payload['cursor']);
              if (cursor.color != _myColor) {
                _canvasObjects[cursor.color.value] = cursor;
              }

              if (payload['object'] != null) {
                final object = CanvasObject.fromJson(payload['object']);
                _canvasObjects[object.color.value] = object;
              }
              setState(() {});
            })
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        return MouseRegion(
          onHover: (event) {
            final myCursor =
                UserCursor(position: event.position, color: _myColor);
            _cursorChannel.sendBroadcastMessage(
              event: 'cursor',
              payload: {
                'cursor': myCursor.toJson(),
              },
            );
          },
          child: Stack(
            children: [
              GestureDetector(
                onPanDown: (details) {
                  if (_currentMode == DrawMode.pointer) {
                    final nonCursorObjects = _canvasObjects.values
                        .where((element) => element is! UserCursor)
                        .toList();
                    for (final canvasObject in nonCursorObjects.reversed) {
                      if (canvasObject is CanvasCircle) {
                        if (canvasObject
                            .intersectsWith(details.globalPosition)) {
                          _currentlyDrawingObject = canvasObject;
                          break;
                        }
                      } else if (canvasObject is CanvasRectangle) {
                        if (canvasObject
                            .intersectsWith(details.globalPosition)) {
                          _currentlyDrawingObject = canvasObject;
                          break;
                        }
                      }
                      setState(() {});
                    }
                  } else if (_currentMode == DrawMode.oval) {
                    setState(() {
                      _currentlyDrawingObject = CanvasCircle(
                          radius: 0,
                          position: details.globalPosition,
                          color: RandomColor.getRandom());
                    });
                  } else if (_currentMode == DrawMode.rectangle) {
                    setState(() {
                      _currentlyDrawingObject = CanvasRectangle(
                        position: details.globalPosition,
                        color: RandomColor.getRandom(),
                        bottomRight: details.globalPosition,
                      );
                    });
                  }
                  _cursorPosition = details.globalPosition;
                },
                onPanUpdate: (details) {
                  if (_currentMode == DrawMode.pointer) {
                    if (_currentlyDrawingObject is CanvasCircle) {
                      _currentlyDrawingObject =
                          (_currentlyDrawingObject as CanvasCircle).copyWith(
                              position:
                                  (_currentlyDrawingObject as CanvasCircle)
                                          .position +
                                      details.delta);
                    } else if (_currentlyDrawingObject is CanvasRectangle) {
                      _currentlyDrawingObject =
                          (_currentlyDrawingObject as CanvasRectangle).copyWith(
                        position: (_currentlyDrawingObject as CanvasRectangle)
                                .position +
                            details.delta,
                        bottomRight:
                            (_currentlyDrawingObject as CanvasRectangle)
                                    .bottomRight +
                                details.delta,
                      );
                    }
                    if (_currentlyDrawingObject != null) {
                      setState(() {});
                      final myCursor = UserCursor(
                        position: details.globalPosition,
                        color: _myColor,
                      );

                      _cursorChannel.sendBroadcastMessage(
                        event: 'cursor',
                        payload: {
                          'cursor': myCursor.toJson(),
                          'object': _currentlyDrawingObject!.toJson(),
                        },
                      );
                    }
                  } else if (_currentMode == DrawMode.oval) {
                    setState(() {
                      _currentlyDrawingObject =
                          (_currentlyDrawingObject as CanvasCircle).copyWith(
                        radius: (details.globalPosition -
                                _currentlyDrawingObject!.position)
                            .distance,
                      );
                    });
                    final myCursor = UserCursor(
                      position: details.globalPosition,
                      color: _myColor,
                    );

                    _cursorChannel.sendBroadcastMessage(
                      event: 'cursor',
                      payload: {
                        'cursor': myCursor.toJson(),
                        'object': _currentlyDrawingObject!.toJson(),
                      },
                    );
                  } else if (_currentMode == DrawMode.rectangle) {
                    setState(() {
                      _currentlyDrawingObject =
                          (_currentlyDrawingObject as CanvasRectangle).copyWith(
                        bottomRight: details.globalPosition,
                      );
                    });
                    final myCursor = UserCursor(
                      position: details.globalPosition,
                      color: _myColor,
                    );

                    _cursorChannel.sendBroadcastMessage(
                      event: 'cursor',
                      payload: {
                        'cursor': myCursor.toJson(),
                        'object': _currentlyDrawingObject!.toJson(),
                      },
                    );
                  }
                  _cursorPosition = details.globalPosition;
                },
                onPanEnd: (details) {
                  if (_currentlyDrawingObject != null) {
                    final myCursor = UserCursor(
                      position: _cursorPosition,
                      color: _myColor,
                    );
                    _cursorChannel.sendBroadcastMessage(
                      event: 'cursor',
                      payload: {
                        'cursor': myCursor.toJson(),
                        'object': _currentlyDrawingObject!.toJson(),
                      },
                    );
                  }

                  setState(() {
                    _currentlyDrawingObject = null;
                  });
                },
                child: CustomPaint(
                  size: Size(maxWidth, maxHeight),
                  painter: ArtBoardPainter(
                    canvasObjects: _canvasObjects,
                    currentlyDrawingObject: _currentlyDrawingObject,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _currentMode = DrawMode.pointer;
                        });
                      },
                      icon: const Icon(FeatherIcons.mousePointer),
                      color: _currentMode == DrawMode.pointer
                          ? Colors.green
                          : null,
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _currentMode = DrawMode.oval;
                        });
                      },
                      icon: const Icon(Icons.circle_outlined),
                      color:
                          _currentMode == DrawMode.oval ? Colors.green : null,
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _currentMode = DrawMode.rectangle;
                        });
                      },
                      icon: const Icon(Icons.rectangle_outlined),
                      color: _currentMode == DrawMode.rectangle
                          ? Colors.green
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
