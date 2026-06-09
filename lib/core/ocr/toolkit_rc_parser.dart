// lib/core/ocr/toolkit_rc_parser.dart
class ParsedCellData {
  final List<double> voltages;
  final List<int> irValues;
  const ParsedCellData({required this.voltages, required this.irValues});
  bool get isEmpty => voltages.isEmpty && irValues.isEmpty;
}

class ToolkitRcParser {
  // Cell-number-prefixed format: "14.200v" = cell 1, 4.200V
  // Requires exactly 3 decimal places to avoid matching "25.20v" (total voltage)
  static final _cellVoltageRe = RegExp(r'([1-8])(\d\.\d{3})\s*[Vv]');

  // Cell-number-prefixed IR: "112mΩ" = cell 1, 12mΩ
  static final _cellIrRe = RegExp(
    r'([1-8])(\d{1,3})\s*[mM][ΩΩQoO0Rr]',
    unicode: true,
  );

  // Fallback: plain voltage without cell prefix (single-channel chargers)
  static final _plainVoltageRe = RegExp(r'(\d\.\d{3})\s*[Vv]');

  static ParsedCellData parse(String ocrText) {
    // ── Voltages ───────────────────────────────────────────────────────────────
    final voltageMap = <int, double>{};
    for (final m in _cellVoltageRe.allMatches(ocrText)) {
      final cell = int.parse(m.group(1)!);
      final v = double.tryParse(m.group(2)!) ?? 0;
      if (v >= 3.0 && v <= 4.45) voltageMap[cell] = v; // sanity: LiPo cell range
    }

    List<double> voltages;
    if (voltageMap.isNotEmpty) {
      final sorted = voltageMap.keys.toList()..sort();
      voltages = sorted.map((k) => voltageMap[k]!).toList();
    } else {
      // Fallback for single-channel chargers without cell-number prefix
      voltages = _plainVoltageRe
          .allMatches(ocrText)
          .map((m) => double.tryParse(m.group(1)!) ?? 0)
          .where((v) => v >= 3.0 && v <= 4.45)
          .toList();
    }

    // ── IR ─────────────────────────────────────────────────────────────────────
    final irMap = <int, int>{};
    for (final m in _cellIrRe.allMatches(ocrText)) {
      final cell = int.parse(m.group(1)!);
      final ir = int.tryParse(m.group(2)!) ?? 0;
      if (ir >= 1 && ir <= 99) irMap[cell] = ir; // sanity: typical LiPo mΩ range
    }

    List<int> irValues;
    if (irMap.isNotEmpty) {
      final sorted = irMap.keys.toList()..sort();
      irValues = sorted.map((k) => irMap[k]!).toList();
    } else {
      irValues = [];
    }

    return ParsedCellData(voltages: voltages, irValues: irValues);
  }
}
