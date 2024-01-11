import 'package:design/canvas/art_board_painter.dart';
import 'package:design/canvas/canvas_object.dart';
import 'package:design/main.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Different input modes users can perform
enum _DrawMode {
  /// Mode to move around existing objects
  pointer,

  /// Mode to draw rectangles
  rectangle,

  /// Mode to draw ovals
  oval,
}

/// Interactive art board page to draw and collaborate with other users.
class ArtBoardPage extends StatefulWidget {
  const ArtBoardPage({super.key});

  @override
  State<ArtBoardPage> createState() => _ArtBoardPageState();
}

class _ArtBoardPageState extends State<ArtBoardPage> {
  final Map<int, CanvasObject> _canvasObjects = {};

  late final RealtimeChannel _cursorChannel;

  late final Color _myColor;

  _DrawMode _currentMode = _DrawMode.pointer;

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
                  if (_currentMode == _DrawMode.pointer) {
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
                  } else if (_currentMode == _DrawMode.oval) {
                    setState(() {
                      _currentlyDrawingObject = CanvasCircle(
                          radius: 0,
                          position: details.globalPosition,
                          color: RandomColor.getRandom());
                    });
                  } else if (_currentMode == _DrawMode.rectangle) {
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
                  if (_currentMode == _DrawMode.pointer) {
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
                  } else if (_currentMode == _DrawMode.oval) {
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
                  } else if (_currentMode == _DrawMode.rectangle) {
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
                          _currentMode = _DrawMode.pointer;
                        });
                      },
                      icon: const Icon(FeatherIcons.mousePointer),
                      color: _currentMode == _DrawMode.pointer
                          ? Colors.green
                          : null,
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _currentMode = _DrawMode.oval;
                        });
                      },
                      icon: const Icon(Icons.circle_outlined),
                      color:
                          _currentMode == _DrawMode.oval ? Colors.green : null,
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _currentMode = _DrawMode.rectangle;
                        });
                      },
                      icon: const Icon(Icons.rectangle_outlined),
                      color: _currentMode == _DrawMode.rectangle
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
