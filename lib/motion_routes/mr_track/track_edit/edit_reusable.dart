import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:provider/provider.dart';

// edit page trailing buttons for delete and update
class TrailingEditButtons extends StatelessWidget {
  final int itemIndexId;
  
  const TrailingEditButtons({super.key, required this.itemIndexId});

  // icon button builder
  IconButton _buildIcon(
      {required VoidCallback onPressed, required Icon iconImage}) {
    return IconButton(iconSize: 20, onPressed: onPressed, icon: iconImage);
  }

  @override
  Widget build(BuildContext context) {
    final deleteItem = context.read<AssignerMainProvider>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // edit icon
        _buildIcon(onPressed: () {}, iconImage: const Icon(Icons.edit)),

        // delete icon
        _buildIcon(
            onPressed: () => deleteItem.deleteAssignedItems(itemIndexId),
            iconImage: const Icon(Icons.delete_outline))
      ],
    );
  }
}
