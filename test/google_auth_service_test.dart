import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_firebase/google_services.dart';

void main() {
  test('interactive Google sign-in clears the cached account before choosing',
      () async {
    final calls = <String>[];

    final account = await GoogleAuthService.selectGoogleAccount(
      clearCachedSelection: () async {
        calls.add('clear');
      },
      showAccountChooser: () async {
        calls.add('choose');
        return null;
      },
    );

    expect(account, isNull);
    expect(calls, <String>['clear', 'choose']);
  });

  test('interactive Google sign-in does not open chooser when clearing fails',
      () async {
    var chooserOpened = false;

    await expectLater(
      GoogleAuthService.selectGoogleAccount(
        clearCachedSelection: () => Future<void>.error(StateError('failed')),
        showAccountChooser: () async {
          chooserOpened = true;
          return null;
        },
      ),
      throwsStateError,
    );

    expect(chooserOpened, isFalse);
  });
}
