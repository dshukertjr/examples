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
      if (canvasObject is CanvasRectangle) {
        final position = canvasObject.position;
        final bottomRight = canvasObject.bottomRight;
        canvas.drawRect(
            Rect.fromLTRB(
                position.dx, position.dy, bottomRight.dx, bottomRight.dy),
            Paint()..color = canvasObject.color);
      }
    }

    final currentObject = currentlyDrawingObject;
    if (currentObject != null) {
      if (currentObject is CanvasRectangle) {
        final position = currentObject.position;
        final bottomRight = currentObject.bottomRight;
        canvas.drawRect(
            Rect.fromLTRB(
                position.dx, position.dy, bottomRight.dx, bottomRight.dy),
            Paint()..color = currentObject.color);
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

  factory CanvasObject.fromJson(Map<String, dynamic> json) {
    if (json['object_type'] == UserCursor.type) {
      return UserCursor.fromJson(json);
    } else if (json['object_type'] == CanvasRectangle.type) {
      return CanvasRectangle.fromJson(json);
    } else {
      throw UnimplementedError('Unknown type ${json['object_type']}');
    }
  }

  CanvasObject({required this.position});

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
  final Color color;

  UserCursor({
    required super.position,
    required this.color,
  });

  UserCursor.fromJson(Map<String, dynamic> json)
      : color = Color(json['color']),
        super(position: Offset(json['position']['x'], json['position']['y']));

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

class CanvasRectangle extends CanvasObject {
  static String type = 'cursor';

  final Color color;
  final Offset bottomRight;

  CanvasRectangle({
    required super.position,
    required this.color,
    required this.bottomRight,
  });

  CanvasRectangle.fromJson(Map<String, dynamic> json)
      : color = Color(json['color']),
        bottomRight = Offset(
          json['bottom_right']['x'],
          json['bottom_right']['y'],
        ),
        super(position: Offset(json['position']['x'], json['position']['y']));

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
}

class _ArtBoardPageState extends State<ArtBoardPage> {
  final Map<int, CanvasObject> _canvasObjects = {};

  late final RealtimeChannel _cursorChannel;

  late final int _myColorCode;

  DrawMode _currentMode = DrawMode.pointer;

  CanvasObject? _currentlyDrawingObject;

  @override
  void initState() {
    super.initState();

    _myColorCode = RandomColor.getRandom().value;
    _cursorChannel = supabase
        .channel('cursor')
        .onBroadcast(
            event: 'cursor',
            callback: (payload) {
              setState(() {
                _canvasObjects[payload['color']] =
                    CanvasObject.fromJson(payload);
              });
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
            final myCursor = UserCursor(
                position: event.position, color: Color(_myColorCode));
            _cursorChannel.sendBroadcastMessage(
              event: 'cursor',
              payload: myCursor.toJson(),
            );
          },
          child: Stack(
            children: [
              GestureDetector(
                onPanDown: (details) {
                  print('pan down');
                  if (_currentMode == DrawMode.oval) {
                  } else if (_currentMode == DrawMode.rectangle) {
                    setState(() {
                      _currentlyDrawingObject = CanvasRectangle(
                        position: details.globalPosition,
                        color: RandomColor.getRandom(),
                        bottomRight: details.globalPosition,
                      );
                    });
                  }
                },
                onPanUpdate: (details) {
                  print('pan update');

                  if (_currentMode == DrawMode.oval) {
                  } else if (_currentMode == DrawMode.rectangle) {
                    setState(() {
                      _currentlyDrawingObject =
                          (_currentlyDrawingObject as CanvasRectangle).copyWith(
                        bottomRight: details.globalPosition,
                      );
                    });
                  }
                },
                onPanEnd: (details) {
                  if (_currentMode == DrawMode.oval) {
                  } else if (_currentMode == DrawMode.rectangle) {
                    _cursorChannel.sendBroadcastMessage(
                      event: 'cursor',
                      payload: _currentlyDrawingObject!.toJson(),
                    );
                    print(_currentlyDrawingObject!.toJson());
                    setState(() {
                      _currentlyDrawingObject = null;
                    });
                  }
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
                  )),
            ],
          ),
        );
      }),
    );
  }
}
