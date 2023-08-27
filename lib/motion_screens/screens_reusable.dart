import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firestore_pvd/firestore_provider.dart';
import 'package:provider/provider.dart';

class UserSettingsInfo extends StatelessWidget {
  const UserSettingsInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // username
        // user name
        Consumer<FirestoreProvider>(
          builder: (context, username, child) {
            return SettingsOptions(
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                ),
                settingsTitle: username.userName,
                settingsDesciption: "Change your username");
          },
        )
      ],
    );
  }
}

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
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        subtitle: Text(
          settingsDesciption,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        trailing: trailing,
      ),
    );
  }
}
