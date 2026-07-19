import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_user/mu_ops/auth_page.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows a session loader while authentication is restored',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserUidProvider(),
        child: const MaterialApp(home: AuthPage()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(AuthPage), findsOneWidget);
  });
}
