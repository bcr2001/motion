import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_firebase/auth_session_source.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('silently recovers a previous authenticated session on cold launch',
      () async {
    final source = _FakeAuthSessionSource(
      recoveryResult: const AuthSessionRecoveryResult.recovered('user-1'),
    );
    final provider = UserUidProvider(authSessionSource: source);

    await provider.initializeUidSharedPreferences();

    expect(provider.isInitialized, isTrue);
    expect(provider.userUid, 'user-1');
    expect(source.recoveryCalls, 1);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(UserUidProvider.uidKey), 'user-1');

    provider.dispose();
    await source.dispose();
  });

  test('does not treat a stale cached UID as an authenticated session',
      () async {
    SharedPreferences.setMockInitialValues({
      UserUidProvider.uidKey: 'stale-user',
    });
    final source = _FakeAuthSessionSource();
    final provider = UserUidProvider(authSessionSource: source);

    await provider.initializeUidSharedPreferences();

    expect(provider.userUid, isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey(UserUidProvider.uidKey), isFalse);

    provider.dispose();
    await source.dispose();
  });

  test('keeps the last authenticated UID when offline recovery is unavailable',
      () async {
    SharedPreferences.setMockInitialValues({
      UserUidProvider.uidKey: 'user-1',
    });
    final source = _FakeAuthSessionSource(
      recoveryResult: const AuthSessionRecoveryResult.temporarilyUnavailable(),
    );
    final provider = UserUidProvider(authSessionSource: source);

    await provider.initializeUidSharedPreferences();

    expect(provider.userUid, 'user-1');
    source.emit(null);
    await _flushAsyncWork();
    expect(provider.userUid, 'user-1');

    await provider.clearUserUid();
    expect(provider.userUid, isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey(UserUidProvider.uidKey), isFalse);

    provider.dispose();
    await source.dispose();
  });

  test('follows later authentication and sign-out events', () async {
    final source = _FakeAuthSessionSource(currentUid: 'user-1');
    final provider = UserUidProvider(authSessionSource: source);
    await provider.initializeUidSharedPreferences();

    source.emit('user-2');
    await _flushAsyncWork();
    expect(provider.userUid, 'user-2');

    source.emit(null);
    await _flushAsyncWork();
    expect(provider.userUid, isNull);

    provider.dispose();
    await source.dispose();
  });
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeAuthSessionSource implements AuthSessionSource {
  _FakeAuthSessionSource({
    this.currentUid,
    this.recoveryResult = const AuthSessionRecoveryResult.noSession(),
  });

  final StreamController<String?> _controller =
      StreamController<String?>.broadcast();
  final AuthSessionRecoveryResult recoveryResult;
  int recoveryCalls = 0;

  @override
  String? currentUid;

  @override
  Stream<String?> get uidChanges => _controller.stream;

  @override
  Future<AuthSessionRecoveryResult> recoverPreviousSession() async {
    recoveryCalls += 1;
    currentUid = recoveryResult.uid;
    return recoveryResult;
  }

  void emit(String? uid) {
    currentUid = uid;
    _controller.add(uid);
  }

  Future<void> dispose() => _controller.close();
}
