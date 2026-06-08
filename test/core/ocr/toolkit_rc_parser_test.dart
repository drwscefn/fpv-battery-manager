// test/core/ocr/toolkit_rc_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpv_battery_manager/core/ocr/toolkit_rc_parser.dart';

void main() {
  group('voltage parsing', () {
    test('parses 6 cell voltages from clean ToolkitRC output', () {
      const text = '''
        1: 4.200V  2: 4.199V  3: 4.200V
        4: 4.198V  5: 4.200V  6: 4.199V
      ''';
      final result = ToolkitRcParser.parse(text);
      expect(result.voltages.length, 6);
      expect(result.voltages[0], closeTo(4.200, 0.001));
      expect(result.voltages[2], closeTo(4.200, 0.001));
    });

    test('parses storage voltages', () {
      const text = '3.850V 3.849V 3.851V 3.850V';
      final result = ToolkitRcParser.parse(text);
      expect(result.voltages.length, 4);
      expect(result.voltages[0], closeTo(3.850, 0.001));
    });

    test('returns empty list when no voltages found', () {
      final result = ToolkitRcParser.parse('no voltages here');
      expect(result.voltages, isEmpty);
    });
  });

  group('IR parsing', () {
    test('parses IR values with mΩ symbol', () {
      const text = '3mΩ 3mΩ 4mΩ 3mΩ 3mΩ 3mΩ';
      final result = ToolkitRcParser.parse(text);
      expect(result.irValues.length, 6);
      expect(result.irValues[2], 4);
    });

    test('parses IR values when OCR mangles omega to O or 0', () {
      const text = '3mO 12mO 4m0 5mR';
      final result = ToolkitRcParser.parse(text);
      expect(result.irValues.length, 4);
      expect(result.irValues[1], 12);
    });

    test('parses mixed case', () {
      const text = '5MΩ 6MΩ';
      final result = ToolkitRcParser.parse(text);
      expect(result.irValues.length, 2);
    });
  });

  group('isEmpty', () {
    test('isEmpty true when both lists empty', () {
      final result = ToolkitRcParser.parse('garbage text 123');
      expect(result.isEmpty, isTrue);
    });

    test('isEmpty false when voltages found', () {
      final result = ToolkitRcParser.parse('3.87V');
      expect(result.isEmpty, isFalse);
    });
  });
}
