import 'package:flutter/material.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';

void showMotionSnackBar(
  BuildContext context, {
  required String message,
  IconData icon = Icons.check_circle_outline_rounded,
  Color iconColor = AppColor.blueMainColor,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, size: 19, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
}
