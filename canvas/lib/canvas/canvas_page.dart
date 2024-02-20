import 'dart:math';

import 'package:canvas/canvas/canvas_object.dart';
import 'package:canvas/canvas/canvas_painter.dart';
import 'package:canvas/main.dart';
import 'package:canvas/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Different input modes users can perform
enum _DrawMode {
  /// Mode to move around existing objects
  pointer(iconData: Icons.pan_tool_alt_outlined),

  /// Mode to draw circles
  circle(iconData: Icons.circle_outlined),

  /// Mode to draw rectangles
  rectangle(iconData: Icons.rectangle_outlined);

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
              }
              setState(() {});
            })
        .onPresenceLeave((payload) {
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

    /// Fetch the initial data from the database
    final initialData = await supabase
        .from('canvas_objects')
        .select()
        .order('created_at', ascending: true);
    for (final canvasObjectData in initialData) {
      final canvasObject = CanvasObject.fromJson(canvasObjectData['object']);
      _canvasObjects[canvasObject.id] = canvasObject;
    }
    setState(() {});
  }

  /// Syncs the user's cursor position and the currently drawing object with
  /// other users.
  Future<void> _syncCanvasObject(Offset cursorPosition) {
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
    await _saveCanvasObject(_canvasObjects[drawnObjectId]!);
  }

  /// Saves a single canvas object to the database.
  Future<void> _saveCanvasObject(CanvasObject object) async {
    await supabase.from('canvas_objects').upsert({
      'id': object.id,
      'object': object.toJson(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          leadingWidth: 300,
          backgroundColor: Colors.grey[900],
          leading: Row(
            children: _DrawMode.values
                .map((mode) => IconButton(
                      onPressed: () {
                        setState(() {
                          _currentMode = mode;
                        });
                      },
                      icon: Icon(mode.iconData),
                      color: _currentMode == mode ? Colors.green : Colors.white,
                    ))
                .toList(),
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
          _LeftPanel(
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
                _syncCanvasObject(event.position);
              },
              child: GestureDetector(
                onPanDown: _onPanDown,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
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
          _RightPanel(
            object: _canvasObjects[_selectedObjectId],
            onObjectChanged: (object) async {
              setState(() {
                _canvasObjects[object.id] = object;
              });
              await _saveCanvasObject(object);
            },
          ),
        ],
      ),
    );
  }
}

/// Side panel on the left.
///
/// Allows users to view and select the objects drawn on the canvas.
class _LeftPanel extends StatelessWidget {
  const _LeftPanel({
    required this.objects,
    required this.selectedObjectId,
    required this.onObjectSelected,
  });
  final List<CanvasObject> objects;
  final String? selectedObjectId;
  final void Function(String objectId) onObjectSelected;

  IconData _getObjectIcon(object) {
    if (object is Circle) {
      return Icons.circle_outlined;
    } else if (object is Rectangle) {
      return Icons.rectangle_outlined;
    } else {
      throw UnimplementedError('Unknown object type: ${object.runtimeType}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[900],
      child: SizedBox(
        width: 200,
        child: ListView.builder(
          itemCount: objects.length,
          itemBuilder: (context, index) {
            final object = objects[index];
            return ListTile(
              selected: object.id == selectedObjectId,
              selectedTileColor: Colors.indigo[900],
              selectedColor: Colors.white,
              onTap: () {
                onObjectSelected(object.id);
              },
              title: Text(object.runtimeType.toString()),
              leading: Icon(_getObjectIcon(object)),
            );
          },
        ),
      ),
    );
  }
}

/// Side panel on the right.
///
/// Allows users to edit the currently selected object.
class _RightPanel extends StatelessWidget {
  const _RightPanel({
    required this.object,
    required this.onObjectChanged,
  });

  final CanvasObject? object;
  final void Function(CanvasObject object) onObjectChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
      width: 250,
      child: object == null
          ? Container()
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                TextFormField(
                  key: ValueKey('fill-${object?.id}'),
                  initialValue: object?.color.value.toRadixString(16),
                  decoration: InputDecoration(
                    label: const Text('Fill'),
                    prefix: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        width: 12,
                        height: 12,
                        color: object?.color,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    try {
                      final color = Color(int.parse(value, radix: 16));
                      late final CanvasObject newObject;
                      if (object is Circle) {
                        newObject = (object as Circle).copyWith(color: color);
                      } else if (object is Rectangle) {
                        newObject =
                            (object as Rectangle).copyWith(color: color);
                      }
                      onObjectChanged(newObject);
                    } catch (e) {
                      // ignore if not a valid color
                    }
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('width-${object?.id}'),
                        keyboardType: TextInputType.number,
                        initialValue: object?.width.toString(),
                        decoration: const InputDecoration(
                          label: Text('Width'),
                        ),
                        onChanged: (value) {
                          try {
                            late final CanvasObject newObject;
                            if (object is Circle) {
                              newObject = (object as Circle).copyWith(
                                radius: double.parse(value) / 2,
                              );
                            } else if (object is Rectangle) {
                              final currentObject = object as Rectangle;
                              newObject = currentObject.copyWith(
                                bottomRight: Offset(
                                  currentObject.topLeft.dx +
                                      double.parse(value),
                                  currentObject.bottomRight.dy,
                                ),
                              );
                            }
                            onObjectChanged(newObject);
                          } catch (e) {
                            // ignore any parsing error
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('height-${object?.id}'),
                        keyboardType: TextInputType.number,
                        initialValue: object?.height.toString(),
                        decoration: const InputDecoration(
                          label: Text('Height'),
                        ),
                        onChanged: (value) {
                          try {
                            late final CanvasObject newObject;
                            if (object is Circle) {
                              newObject = (object as Circle).copyWith(
                                radius: double.parse(value) / 2,
                              );
                            } else if (object is Rectangle) {
                              final currentObject = object as Rectangle;
                              newObject = currentObject.copyWith(
                                bottomRight: Offset(
                                  currentObject.bottomRight.dx,
                                  currentObject.topLeft.dy +
                                      double.parse(value),
                                ),
                              );
                            }
                            onObjectChanged(newObject);
                          } catch (e) {
                            // ignore any parsing error
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
