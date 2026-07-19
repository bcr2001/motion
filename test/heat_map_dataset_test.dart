import 'package:flutter_test/flutter_test.dart';

import 'package:motion/motion_screens/ms_report/report_heat_map.dart';

void main() {
  group('datasetFormatConverter', () {
    test('normalizes ISO dates to date-only heat-map keys', () {
      final data = datasetFormatConverter(data: [
        {'date': '2026-06-01 12:34:56.000', 'intensity': 25},
      ]);

      expect(data[DateTime(2026, 6, 1)], 25);
    });

    test('supports slash dates used by historical imported data', () {
      final data = datasetFormatConverter(data: [
        {'date': '6/1/2026', 'intensity': 25},
        {'date': '6/2/2026', 'intensity': 15.0},
        {'date': '6/3/2026', 'intensity': '20'},
      ]);

      expect(data[DateTime(2026, 6, 1)], 25);
      expect(data[DateTime(2026, 6, 2)], 15);
      expect(data[DateTime(2026, 6, 3)], 20);
    });

    test('skips rows with invalid dates instead of breaking the heat map', () {
      final data = datasetFormatConverter(data: [
        {'date': '', 'intensity': 25},
        {'date': 'not-a-date', 'intensity': 25},
        {'date': '2026-06-04', 'intensity': 25},
      ]);

      expect(data.length, 1);
      expect(data[DateTime(2026, 6, 4)], 25);
    });

    test('tracked minutes produce shadeable heat-map intensity', () {
      const dailyMinutesByDate = {
        '6/1/2026': 360.0,
        '6/2/2026': 180.0,
        '6/3/2026': 45.0,
      };

      for (final entry in dailyMinutesByDate.entries) {
        final heatMapData = datasetFormatConverter(data: [
          {
            'date': entry.key,
            'intensity':
                int.parse(calculateScoreFromMinutes(entry.value)),
          },
        ]);

        expect(heatMapData[parseHeatMapDate(entry.key)], greaterThan(0));
      }
    });
  });
}
