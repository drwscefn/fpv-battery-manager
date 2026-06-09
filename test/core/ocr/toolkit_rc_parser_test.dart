// test/core/ocr/toolkit_rc_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpv_battery_manager/core/ocr/toolkit_rc_parser.dart';

void main() {
  group('voltage parsing', () {
    test('parses 6 cell voltages from cell-prefixed ToolkitRC output', () {
      const text = '''
14.200v 44.200v
24.199v 54.200v
34.200v 64.199v
''';
      final result = ToolkitRcParser.parse(text);
      expect(result.voltages.length, 6);
      expect(result.voltages[0], closeTo(4.200, 0.001));
      expect(result.voltages[2], closeTo(4.200, 0.001));
    });

    test('parses storage voltages via fallback (no cell prefix)', () {
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
    test('parses IR values with cell-prefixed mΩ symbol', () {
      const text = '13mΩ 23mΩ 34mΩ 43mΩ 53mΩ 63mΩ';
      final result = ToolkitRcParser.parse(text);
      expect(result.irValues.length, 6);
      expect(result.irValues[2], 4);
    });

    test('parses IR values when OCR mangles omega to O or 0', () {
      const text = '13mO 212mO 34m0 45mR';
      final result = ToolkitRcParser.parse(text);
      expect(result.irValues.length, 4);
      expect(result.irValues[1], 12);
    });

    test('parses mixed case', () {
      const text = '15MΩ 26MΩ';
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
      final result = ToolkitRcParser.parse('13.870v');
      expect(result.isEmpty, isFalse);
    });
  });

  group('dual-channel layout', () {
    test('dual-channel layout parses cell-prefixed voltages in correct order', () {
      const text = '''
14.200v 44.200v
24.201v 54.199v
34.200v 64.198v
''';
      final result = ToolkitRcParser.parse(text);
      expect(result.voltages, [4.200, 4.201, 4.200, 4.200, 4.199, 4.198]);
    });

    test('dual-channel layout parses cell-prefixed IR in correct order', () {
      const text = '112mΩ 412mΩ 212mΩ 513mΩ 312mΩ 611mΩ';
      final result = ToolkitRcParser.parse(text);
      expect(result.irValues, [12, 12, 12, 12, 13, 11]);
    });
  });
}
