import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

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

    test('June 1 to June 3 2026 seed rows have shadeable intensity', () {
      final subcategoryCsv =
          File('assets/data_csv/subcategory.csv').readAsStringSync();
      final rows = subcategoryCsv.split(RegExp(r'\r?\n'));

      for (final date in ['6/1/2026', '6/2/2026', '6/3/2026']) {
        final dailyMinutes =
            rows.where((row) => row.startsWith('$date,')).map((row) {
          final columns = row.split(',');
          return double.tryParse(columns[3].replaceAll('mins', '').trim()) ??
              0.0;
        }).fold<double>(0.0, (sum, minutes) => sum + minutes);

        final heatMapData = datasetFormatConverter(data: [
          {
            'date': date,
            'intensity': int.parse(calculateScoreFromMinutes(dailyMinutes)),
          },
        ]);

        expect(dailyMinutes, greaterThan(0));
        expect(heatMapData[parseHeatMapDate(date)], greaterThan(0));
      }
    });
  });
}
