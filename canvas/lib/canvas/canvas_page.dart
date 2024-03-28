import 'dart:math';
import 'dart:ui' as ui show Image;

import 'package:canvas/canvas/canvas_object.dart';
import 'package:canvas/canvas/canvas_painter.dart';
import 'package:canvas/canvas/left_panel.dart';
import 'package:canvas/canvas/right_panel.dart';
import 'package:canvas/main.dart';
import 'package:canvas/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Different input modes users can perform
enum _DrawMode {
  /// Mode to move around existing objects
  pointer(iconData: Icons.pan_tool_alt_outlined),

  /// Mode to draw circles
  circle(iconData: Icons.circle_outlined),

  /// Mode to draw rectangles
  rectangle(iconData: Icons.rectangle_outlined),

  /// Mode to draw polygons using the pen tool
  pen(iconData: Icons.edit_outlined);

  const _DrawMode({required this.iconData});

  /// Icon used in the IconButton to toggle the mode
  final IconData iconData;
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
  late final RealtimeChannel _canvasChanel;

  /// Randomly generated UUID for the user
  late final String _myId;

  /// Whether the user is using the pointer to move things around, or in drawing mode.
  _DrawMode _currentMode = _DrawMode.pointer;

  /// A single Canvas object that is being drawn by the user if any.
  String? _selectedObjectId;

  /// The point where the pan started
  Offset? _panStartPoint;

  /// Cursor position of the user.
  Offset _cursorPosition = const Offset(0, 0);

  bool _isTextFieldFocused = false;

  final Map<String, ui.Image> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Generate a random UUID for the user.
    // We could replace this with Supabase auth user ID if we want to make it
    // more like Figma.
    _myId = const Uuid().v4();

    // Start listening to broadcast messages to display other users' cursors and objects.
    _canvasChanel = supabase
        .channel(Constants.channelName)
        .onBroadcast(
            event: Constants.broadcastEventName,
            callback: (payload) {
              final cursor = UserCursor.fromJson(payload['cursor']);
              _userCursors[cursor.id] = cursor;

              if (payload['object'] != null) {
                final object = CanvasObject.fromJson(payload['object']);
                _canvasObjects[object.id] = object;
                _loadImage(object);
              }

              if (payload['delete_object'] != null) {
                final objectId = payload['delete_object'] as String;
                _canvasObjects.remove(objectId);
              }
              setState(() {});
            })
        .onPresenceJoin((payload) {
      final joinedId = payload.newPresences.first.payload['id'] as String;
      if (_myId == joinedId) return;
      if (!_userCursors.containsKey(joinedId)) {
        setState(() {
          _userCursors[joinedId] = UserCursor(
            position: const Offset(-100, -100),
            id: joinedId,
          );
        });
      }
    }).onPresenceLeave((payload) {
      final leftId = payload.leftPresences.first.payload['id'];
      setState(() {
        _userCursors.remove(leftId);
      });
    }).subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        _canvasChanel.track({
          'id': _myId,
        });
      }
    });

    // Listen to keyboard events to handle deleting objects
    ServicesBinding.instance.keyboard.addHandler((event) {
      final key = event.logicalKey.keyLabel;

      if (event is KeyDownEvent &&
          key == 'Backspace' &&
          !_isTextFieldFocused &&
          _selectedObjectId != null) {
        _deleteCanvasObject(_selectedObjectId!);
        return true;
      }

      return false;
    });

    /// Fetch the initial data from the database
    final initialData = await supabase
        .from('canvas_objects')
        .select()
        .order('created_at', ascending: true);
    for (final canvasObjectData in initialData) {
      final canvasObject = CanvasObject.fromJson(canvasObjectData['object']);
      _canvasObjects[canvasObject.id] = canvasObject;
      if (canvasObject.imagePath != null) {
        _loadImage(canvasObject);
      }
    }
    setState(() {});
  }

  // Loads the image data so that they can be displayed on canvas
  Future<void> _loadImage(CanvasObject object) async {
    final ui.Image image;
    if (object.imagePath == null) return;
    if (_imageCache.containsKey(object.imagePath!)) {
      image = _imageCache[object.imagePath!]!;
    } else {
      final imageByteList = await supabase.storage
          .from(Constants.storageBucketName)
          .download(object.imagePath!);

      image = await decodeImageFromList(imageByteList);
      _imageCache[object.imagePath!] = image;
    }
    setState(() {
      _canvasObjects[object.id] = object.copyWith(image: image);
    });
  }

  /// Syncs the user's cursor position and the currently drawing object with
  /// other users.
  Future<void> _syncCanvasObject([Offset? cursorPosition]) {
    final myCursor = UserCursor(
      position: cursorPosition,
      id: _myId,
    );
    return _canvasChanel.sendBroadcastMessage(
      event: Constants.broadcastEventName,
      payload: {
        'cursor': myCursor.toJson(),
        if (_selectedObjectId != null)
          'object': _canvasObjects[_selectedObjectId]?.toJson(),
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
        final selectedObject = _canvasObjects[_selectedObjectId ?? ''];
        if (selectedObject == null ||
            !selectedObject.intersectsWith(details.localPosition)) {
          _selectedObjectId = null;
          // Loop through the canvas objects to find if there are any
          // that intersects with the current mouse position.
          for (final canvasObject in _canvasObjects.values.toList().reversed) {
            if (canvasObject.intersectsWith(details.localPosition)) {
              _selectedObjectId = canvasObject.id;
              break;
            }
          }
        }
        break;
      case _DrawMode.circle:
        final newObject = Circle.createNew(details.localPosition);
        _canvasObjects[newObject.id] = newObject;
        _selectedObjectId = newObject.id;
        break;
      case _DrawMode.rectangle:
        final newObject = Rectangle.createNew(details.localPosition);
        _canvasObjects[newObject.id] = newObject;
        _selectedObjectId = newObject.id;
        break;
      case _DrawMode.pen:
        // The user is drawing a polygon if the selected object is an open polygon
        final isDrawingPolygon = _selectedObjectId != null &&
            _canvasObjects[_selectedObjectId!] is Polygon &&
            !(_canvasObjects[_selectedObjectId!] as Polygon).isClosed;

        print(isDrawingPolygon);

        if (isDrawingPolygon) {
          _canvasObjects[_selectedObjectId!] =
              (_canvasObjects[_selectedObjectId!] as Polygon).addPoint(
            details.localPosition,
          );
        } else {
          final newObject = Polygon.createNew(details.localPosition);
          _canvasObjects[newObject.id] = newObject;
          _selectedObjectId = newObject.id;
        }
        break;
    }
    _cursorPosition = details.localPosition;
    _panStartPoint = details.localPosition;
    setState(() {});
  }

  /// Called when the user clicks and drags the canvas.
  ///
  /// Performs different actions depending on the current mode.
  void _onPanUpdate(DragUpdateDetails details) {
    switch (_currentMode) {
      // Moves the object to [details.delta] amount.
      case _DrawMode.pointer:
        if (_selectedObjectId != null) {
          _canvasObjects[_selectedObjectId!] =
              _canvasObjects[_selectedObjectId!]!.move(details.delta);
        }
        break;

      // Updates the size of the Circle
      case _DrawMode.circle:
        final currentlyDrawingCircle =
            _canvasObjects[_selectedObjectId!]! as Circle;
        _canvasObjects[_selectedObjectId!] = currentlyDrawingCircle.copyWith(
          center: (details.localPosition + _panStartPoint!) / 2,
          radius: min((details.localPosition.dx - _panStartPoint!.dx).abs(),
                  (details.localPosition.dy - _panStartPoint!.dy).abs()) /
              2,
        );
        break;

      // Updates the size of the rectangle
      case _DrawMode.rectangle:
        _canvasObjects[_selectedObjectId!] =
            (_canvasObjects[_selectedObjectId!] as Rectangle).copyWith(
          bottomRight: details.localPosition,
        );
        break;
      case _DrawMode.pen:
        // Do nothing on pan update for the pen tool
        break;
    }

    _cursorPosition = details.localPosition;
    if (_selectedObjectId != null) {
      setState(() {});
      _syncCanvasObject(_cursorPosition);
    }
  }

  void _onPanEnd(DragEndDetails _) async {
    _panStartPoint = null;

    final drawnObjectId = _selectedObjectId;
    // Save whatever was drawn to Supabase DB
    if (drawnObjectId == null) {
      return;
    }

    if (_currentMode != _DrawMode.pen) {
      setState(() {
        _currentMode = _DrawMode.pointer;
      });

      await _saveCanvasObject(_canvasObjects[drawnObjectId]!);
    }
  }

  /// Saves a single canvas object to the database.
  Future<void> _saveCanvasObject(CanvasObject object) async {
    await supabase.from('canvas_objects').upsert({
      'id': object.id,
      'object': object.toJson(),
    });
  }

  Future<void> _deleteCanvasObject(String objectId) async {
    setState(() {
      _selectedObjectId = null;
      _canvasObjects.remove(objectId);
    });

    _canvasChanel
        .sendBroadcastMessage(event: Constants.broadcastEventName, payload: {
      'cursor': UserCursor(position: _cursorPosition, id: _myId).toJson(),
      'delete_object': objectId,
    });

    await supabase.from('canvas_objects').delete().eq('id', objectId);
  }

  @override
  Widget build(BuildContext context) {
    final isDrawingPolygon = _selectedObjectId != null &&
        _canvasObjects[_selectedObjectId] is Polygon &&
        !(_canvasObjects[_selectedObjectId] as Polygon).isClosed;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          leadingWidth: 300,
          backgroundColor: Colors.grey[900],
          leading: Row(
            children: [
              if (!isDrawingPolygon)
                ..._DrawMode.values
                    .map((mode) => IconButton(
                          onPressed: () {
                            setState(() {
                              _currentMode = mode;
                            });
                          },
                          icon: Icon(mode.iconData),
                          color: _currentMode == mode
                              ? Colors.green
                              : Colors.white,
                        ))
                    .toList(),

              // Button to save the state of the polygon
              if (isDrawingPolygon)
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _canvasObjects[_selectedObjectId!] =
                          (_canvasObjects[_selectedObjectId!] as Polygon)
                              .close();
                      _currentMode = _DrawMode.pointer;
                    });
                    _saveCanvasObject(_canvasObjects[_selectedObjectId]!);
                  },
                  child: const Text('Done'),
                ),
            ],
          ),
          // Displays the list of users currently drawing on the canvas
          actions: [
            ...[..._userCursors.values.map((e) => e.id), _myId]
                .map(
                  (id) => Align(
                    widthFactor: 0.8,
                    child: CircleAvatar(
                      backgroundColor: RandomColor.getRandomFromId(id),
                      child: Text(id.substring(0, 2)),
                    ),
                  ),
                )
                .toList(),
            const SizedBox(width: 20),
          ]),
      body: Row(
        children: [
          LeftPanel(
            objects: _canvasObjects.values.toList().reversed.toList(),
            selectedObjectId: _selectedObjectId,
            onObjectSelected: (objectId) {
              setState(() {
                _selectedObjectId = objectId;
              });
            },
          ),
          Expanded(
            child: MouseRegion(
              onHover: (event) {
                _syncCanvasObject(event.localPosition);
              },
              child: GestureDetector(
                onPanDown: _onPanDown,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: ClipRect(
                  child: CustomPaint(
                    painter: CanvasPainter(
                      userCursors: _userCursors,
                      canvasObjects: _canvasObjects,
                      selectedObjectId: _selectedObjectId,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
          RightPanel(
            object: _canvasObjects[_selectedObjectId],
            onObjectChanged: (object) async {
              setState(() {
                _canvasObjects[object.id] = object;
              });
              _syncCanvasObject();
              if (object.imagePath != null) {
                await _loadImage(object);
              }
              await _saveCanvasObject(object);
            },
            onFocusChange: (hasFocus) {
              setState(() {
                _isTextFieldFocused = hasFocus;
              });
            },
          ),
        ],
      ),
    );
  }
}
