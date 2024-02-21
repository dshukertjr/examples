import 'package:canvas/canvas/canvas_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hsvcolor_picker/flutter_hsvcolor_picker.dart';

/// Side panel on the right.
///
/// Allows users to edit the currently selected object.
class RightPanel extends StatelessWidget {
  RightPanel({
    super.key,
    required this.object,
    required this.onObjectChanged,
  });

  final CanvasObject? object;
  final void Function(CanvasObject object) onObjectChanged;

  final OverlayPortalController _overlayPortalController =
      OverlayPortalController();

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
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('width-${object?.id}'),
                        keyboardType: TextInputType.number,
                        initialValue: object?.width.round().toString(),
                        decoration: const InputDecoration(
                          prefixText: 'W ',
                          border: InputBorder.none,
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
                        initialValue: object?.height.round().toString(),
                        decoration: const InputDecoration(
                          prefixText: 'H ',
                          border: InputBorder.none,
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
                const Divider(),
                const Text('Fill'),
                Row(
                  children: [
                    IconButton(
                      onPressed: _overlayPortalController.toggle,
                      icon: OverlayPortal(
                        controller: _overlayPortalController,
                        overlayChildBuilder: (context) {
                          return Positioned(
                            top: 0,
                            right: 250,
                            child: Container(
                              color: Colors.grey[900],
                              padding: const EdgeInsets.all(8),
                              width: 250,
                              child: ColorPicker(
                                color: object?.color ?? Colors.black,
                                onChanged: (color) {
                                  late final CanvasObject newObject;
                                  if (object is Circle) {
                                    newObject = (object as Circle)
                                        .copyWith(color: color);
                                  } else if (object is Rectangle) {
                                    newObject = (object as Rectangle)
                                        .copyWith(color: color);
                                  }
                                  onObjectChanged(newObject);
                                },
                                pickerOrientation: PickerOrientation.portrait,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 12,
                          height: 12,
                          color: object?.color,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('fill-${object?.id}'),
                        initialValue: object?.color.value.toRadixString(16),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          try {
                            final color = Color(int.parse(value, radix: 16));
                            late final CanvasObject newObject;
                            if (object is Circle) {
                              newObject =
                                  (object as Circle).copyWith(color: color);
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
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
