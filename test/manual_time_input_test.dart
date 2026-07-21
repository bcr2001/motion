import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';

void main() {
  group('manual time input', () {
    test('treats all empty components as zero', () {
      expect(timeAdder(h: '', m: '', s: ''), 0);
    });

    test('treats missing components as zero', () {
      expect(timeAdder(h: '', m: '12', s: ''), 12);
      expect(timeAdder(h: '1', m: '', s: '30'), 60.5);
    });

    test('still rejects non-numeric components', () {
      expect(
        () => timeAdder(h: 'one', m: '', s: ''),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
