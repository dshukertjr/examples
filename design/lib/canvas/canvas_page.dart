import 'package:design/canvas/canvas_object.dart';
import 'package:design/canvas/canvas_painter.dart';
import 'package:design/main.dart';
import 'package:design/utils/constants.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Different input modes users can perform
enum _DrawMode {
  /// Mode to move around existing objects
  pointer,

  /// Mode to draw rectangles
  rectangle,

  /// Mode to draw ovals
  circle,
}

/// Interactive art board page to draw and collaborate with other users.
class CanvasPage extends StatefulWidget {
  const CanvasPage({super.key});

  @override
  State<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends State<CanvasPage> {
  /// Holds the cursor information of other users
  final Map<String, UserCursor> _userCursors = {};

  /// Holds the list of objects drawn on the canvas
  final Map<String, CanvasObject> _canvasObjects = {};

  /// Supabase realtime channel to communicate to other clients
  late final RealtimeChannel _cursorChannel;

  /// Randomly generated UUID for the user
  late final String _myId;

  /// Whether the user is using the pointer to move things around, or in drawing mode.
  _DrawMode _currentMode = _DrawMode.pointer;

  /// A single Canvas object that is being drawn by the user if any.
  CanvasObject? _currentlyDrawingObject;

  /// Cursor position of the user.
  Offset _cursorPosition = const Offset(0, 0);

  @override
  void initState() {
    super.initState();

    // Generate a random UUID for the user.
    // We could replace this with Supabase auth user ID if we want to make it
    // more like Figma.
    _myId = const Uuid().v4();

    // Start listening to broadcast messages to display other users' cursors and objects.
    _cursorChannel = supabase
        .channel(Constants.channelName,
            opts: const RealtimeChannelConfig(self: true))
        .onBroadcast(
            event: Constants.broadcastEventName,
            callback: (payload) {
              final cursor = UserCursor.fromJson(payload['cursor']);
              if (cursor.id != _myId) {
                _userCursors[cursor.id] = cursor;
              }

              if (payload['object'] != null) {
                final object = CanvasObject.fromJson(payload['object']);
                _canvasObjects[object.id] = object;
              }
              setState(() {});
            })
        .subscribe();
  }

  /// Syncs the user's cursor position and the currently drawing object with
  /// other users.
  Future<void> _syncCanvasObject(Offset cursorPosition) {
    final myCursor = UserCursor(
      position: cursorPosition,
      id: _myId,
    );
    return _cursorChannel.sendBroadcastMessage(
      event: Constants.broadcastEventName,
      payload: {
        'cursor': myCursor.toJson(),
        'object': _currentlyDrawingObject?.toJson(),
      },
    );
  }

  /// Called when pan starts.
  ///
  /// For [_DrawMode.pointer], it will find the first object under the cursor.
  ///
  /// For other draw modes, it will start drawing the respective canvas objects.
  void _onPanDown(DragDownDetails details) {
    switch (_currentMode) {
      case _DrawMode.pointer:
        // Loop through the canvas objects to find if there are any
        // that intersects with the current mouse position.
        for (final canvasObject in _canvasObjects.values.toList().reversed) {
          if (canvasObject.intersectsWith(details.globalPosition)) {
            _currentlyDrawingObject = canvasObject;
            break;
          }
        }
        break;
      case _DrawMode.circle:
        _currentlyDrawingObject =
            CanvasCircle.createNew(details.globalPosition);
        break;
      case _DrawMode.rectangle:
        _currentlyDrawingObject =
            CanvasRectangle.createNew(details.globalPosition);
        break;
    }
    _cursorPosition = details.globalPosition;
    setState(() {});
  }

  /// Called when the user clicks and drags the canvas.
  ///
  /// Performs different actions depending on the current mode.
  void _onPanUpdate(DragUpdateDetails details) {
    switch (_currentMode) {
      // Moves the object to [details.delta] amount.
      case _DrawMode.pointer:
        if (_currentlyDrawingObject != null) {
          _currentlyDrawingObject =
              _currentlyDrawingObject!.move(details.delta);
        }
        break;

      // Updates the size of the Circle
      case _DrawMode.circle:
        final currentlyDrawingCircle = _currentlyDrawingObject as CanvasCircle;
        _currentlyDrawingObject = currentlyDrawingCircle.copyWith(
          radius:
              (details.globalPosition - currentlyDrawingCircle.center).distance,
        );
        break;

      // Updates the size of the rectangle
      case _DrawMode.rectangle:
        _currentlyDrawingObject =
            (_currentlyDrawingObject as CanvasRectangle).copyWith(
          bottomRight: details.globalPosition,
        );
        break;
    }

    if (_currentlyDrawingObject != null) {
      setState(() {});
    }
    _cursorPosition = details.globalPosition;
    _syncCanvasObject(_cursorPosition);
  }

  void onPanEnd(DragEndDetails _) {
    if (_currentlyDrawingObject != null) {
      _syncCanvasObject(_cursorPosition);
    }

    setState(() {
      _currentlyDrawingObject = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        return MouseRegion(
          onHover: (event) {
            _syncCanvasObject(event.position);
          },
          child: Stack(
            children: [
              GestureDetector(
                onPanDown: _onPanDown,
                onPanUpdate: _onPanUpdate,
                onPanEnd: onPanEnd,
                child: CustomPaint(
                  size: Size(maxWidth, maxHeight),
                  painter: CanvasPainter(
                    userCursors: _userCursors,
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
                      iconSize: 48,
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
                      iconSize: 48,
                      onPressed: () {
                        setState(() {
                          _currentMode = _DrawMode.circle;
                        });
                      },
                      icon: const Icon(Icons.circle_outlined),
                      color: _currentMode == _DrawMode.circle
                          ? Colors.green
                          : null,
                    ),
                    IconButton(
                      iconSize: 48,
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
