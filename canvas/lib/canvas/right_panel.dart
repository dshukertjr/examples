import 'package:canvas/canvas/canvas_object.dart';
import 'package:canvas/main.dart';
import 'package:canvas/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hsvcolor_picker/flutter_hsvcolor_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Side panel on the right.
///
/// Allows users to edit the currently selected object.
class RightPanel extends StatefulWidget {
  const RightPanel({
    super.key,
    required this.object,
    required this.onObjectChanged,
    required this.onFocusChange,
  });

  static const rightPanelWidth = 200.0;

  final CanvasObject? object;
  final void Function(CanvasObject object) onObjectChanged;
  final void Function(bool hasFocus) onFocusChange;

  @override
  State<RightPanel> createState() => _RightPanelState();
}

class _RightPanelState extends State<RightPanel> {
  final OverlayPortalController _overlayPortalController =
      OverlayPortalController();

  final _widthController = TextEditingController();
  final _heightController = TextEditingController();

  bool _hasFocus = false;

  @override
  void didUpdateWidget(covariant RightPanel oldWidget) {
    if (!_hasFocus) {
      _widthController.text = widget.object?.width.round().toString() ?? '';
      _heightController.text = widget.object?.height.round().toString() ?? '';
    }
    super.didUpdateWidget(oldWidget);
  }

  /// Uploads an image to the storage and updates the object's fill to the image.
  Future<void> _uploadImage() async {
    assert(widget.object != null,
        'An object needs to be selected before uploading an image.');
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final imageBytes = await image.readAsBytes();
    final storagePath = 'objects/${widget.object!.id}.png';
    await supabase.storage.from(Constants.storageBucketName).uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: const FileOptions(
            contentType: 'image/png',
            upsert: true,
          ),
        );

    widget.onObjectChanged(widget.object!.copyWith(imagePath: storagePath));
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {
            _hasFocus = hasFocus;
          });
          widget.onFocusChange(hasFocus);
        },
        child: Container(
          color: Colors.grey[900],
          width: RightPanel.rightPanelWidth,
          child: widget.object == null
              ? const SizedBox.expand()
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('width-${widget.object?.id}'),
                            controller: _widthController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              prefixText: 'W ',
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              try {
                                late final CanvasObject newObject;
                                if (widget.object is Circle) {
                                  newObject =
                                      (widget.object as Circle).copyWith(
                                    radius: double.parse(value) / 2,
                                  );
                                } else if (widget.object is Rectangle) {
                                  final currentObject =
                                      widget.object as Rectangle;
                                  newObject = currentObject.copyWith(
                                    bottomRight: Offset(
                                      currentObject.topLeft.dx +
                                          double.parse(value),
                                      currentObject.bottomRight.dy,
                                    ),
                                  );
                                }
                                widget.onObjectChanged(newObject);
                              } catch (e) {
                                // ignore any parsing error
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('height-${widget.object?.id}'),
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              prefixText: 'H ',
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              try {
                                late final CanvasObject newObject;
                                if (widget.object is Circle) {
                                  newObject =
                                      (widget.object as Circle).copyWith(
                                    radius: double.parse(value) / 2,
                                  );
                                } else if (widget.object is Rectangle) {
                                  final currentObject =
                                      widget.object as Rectangle;
                                  newObject = currentObject.copyWith(
                                    bottomRight: Offset(
                                      currentObject.bottomRight.dx,
                                      currentObject.topLeft.dy +
                                          double.parse(value),
                                    ),
                                  );
                                }
                                widget.onObjectChanged(newObject);
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
                    ElevatedButton(
                        onPressed: () {
                          _uploadImage();
                        },
                        child: const Text('Upload Image')),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _overlayPortalController.toggle,
                          icon: OverlayPortal(
                            controller: _overlayPortalController,
                            overlayChildBuilder: (context) {
                              return Positioned(
                                top: 0,
                                right: RightPanel.rightPanelWidth,
                                child: Container(
                                  color: Colors.grey[900],
                                  padding: const EdgeInsets.all(8),
                                  width: 250,
                                  child: ColorPicker(
                                    color: widget.object?.color ?? Colors.black,
                                    onChanged: (color) {
                                      late final CanvasObject newObject;
                                      if (widget.object is Circle) {
                                        newObject = (widget.object as Circle)
                                            .copyWith(color: color);
                                      } else if (widget.object is Rectangle) {
                                        newObject = (widget.object as Rectangle)
                                            .copyWith(color: color);
                                      }
                                      widget.onObjectChanged(newObject);
                                    },
                                    pickerOrientation:
                                        PickerOrientation.portrait,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 12,
                              height: 12,
                              color: widget.object?.color,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('fill-${widget.object?.id}'),
                            initialValue:
                                widget.object?.color.value.toRadixString(16),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              try {
                                final color =
                                    Color(int.parse(value, radix: 16));
                                late final CanvasObject newObject;
                                if (widget.object is Circle) {
                                  newObject = (widget.object as Circle)
                                      .copyWith(color: color);
                                } else if (widget.object is Rectangle) {
                                  newObject = (widget.object as Rectangle)
                                      .copyWith(color: color);
                                }
                                widget.onObjectChanged(newObject);
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
        ),
      ),
    );
  }
}
