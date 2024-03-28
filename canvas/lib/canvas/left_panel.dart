import 'package:canvas/canvas/canvas_object.dart';
import 'package:flutter/material.dart';

/// Side panel on the left.
///
/// Allows users to view and select the objects drawn on the canvas.
class LeftPanel extends StatelessWidget {
  const LeftPanel({
    super.key,
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
    } else if (object is Polygon) {
      return Icons.edit;
    } else {
      throw UnimplementedError('Unknown object type: ${object.runtimeType}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[900],
      child: SizedBox(
        width: 170,
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
