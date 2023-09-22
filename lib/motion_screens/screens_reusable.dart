import 'package:flutter/material.dart';

// setting options list tile constructors
class SettingsOptions extends StatelessWidget {
  final String settingsTitle;
  final String settingsDesciption;
  final VoidCallback? onTap;
  final IconButton? trailing;

  const SettingsOptions(this.trailing,
      {super.key,
      required this.settingsTitle,
      required this.settingsDesciption,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        onTap: onTap,
        title: Text(
          settingsTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        subtitle: Text(
          settingsDesciption,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: trailing,
      ),
    );
  }
}
