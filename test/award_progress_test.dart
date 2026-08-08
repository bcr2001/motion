import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_awards/award_definition.dart';

void main() {
  group('lifetime award progress', () {
    test('measures progress from zero toward the next award', () {
      expect(MotionAwards.lifetimeProgressToNext(12), closeTo(0.5, 0.0001));
    });

    test('uses all lifetime hours after an award has been earned', () {
      expect(
        MotionAwards.lifetimeProgressToNext(29864),
        closeTo(0.59728, 0.000001),
      );
    });

    test('returns complete after every milestone is unlocked', () {
      expect(MotionAwards.lifetimeProgressToNext(100000), 1);
    });

    test('clamps invalid negative totals to zero', () {
      expect(MotionAwards.lifetimeProgressToNext(-10), 0);
    });
  });
}
