// lib/core/ocr/toolkit_rc_parser.dart
//
// Multi-charger OCR parser. Three strategies tried in priority order:
//
//  1. ToolkitRC M6D/M8/M6 (dual/single channel)
//     Cell digit fused to voltage: "14.192V" = C1 @ 4.192V
//     IR fused same way:           "112mΩ"   = C1 @ 12mΩ
//
//  2. Labeled format  (ISDT Q6+/Q8, HOTA D6 Pro, SkyRC S-series, Junsi iCharger)
//     Explicit cell prefix with separator:
//       "S1 4.190V"  "C1:4.188V"  "1: 4.192V"  "01  4.190V"
//     IR same: "S1 14mΩ"  "C1: 11mΩ"  "01 12mΩ"
//
//  3. Bare sequential (universal fallback)
//     Plain "4.192V" values in reading order, filtered to LiPo cell range.
//     IR: plain "14mΩ" values in reading order.

class ParsedCellData {
  final List<double> voltages;
  final List<int> irValues;
  const ParsedCellData({required this.voltages, required this.irValues});
  bool get isEmpty => voltages.isEmpty && irValues.isEmpty;
}

class ToolkitRcParser {
  // ── Strategy 1: ToolkitRC M6D — digit fused (no separator) ──────────────────
  static final _m6dVoltRe = RegExp(r'([1-8])(\d\.\d{3})\s*[Vv]');
  static final _m6dIrRe =
      RegExp(r'([1-8])(\d{1,3})\s*[mM][ΩΩQoO0Rr]', unicode: true);

  // ── Strategy 2: labeled cells — S/C optional prefix + separator ─────────────
  // Matches: "S1 4.190V"  "C2:4.188V"  "1: 4.192V"  "01  4.190V"
  static final _labeledVoltRe =
      RegExp(r'(?:[SCsc])?0?([1-8])[:\s]+(\d\.\d{3})\s*[Vv]');
  static final _labeledIrRe = RegExp(
    r'(?:[SCsc])?0?([1-8])[:\s]+(\d{1,3})\s*[mM][ΩΩQoO0Rr]',
    unicode: true,
  );

  // ── Strategy 3: bare sequential ──────────────────────────────────────────────
  static final _bareVoltRe = RegExp(r'(\d\.\d{3})\s*[Vv]');
  static final _bareIrRe =
      RegExp(r'(\d{1,3})\s*[mM][ΩΩQoO0Rr]', unicode: true);

  static ParsedCellData parse(String ocrText) {
    // ── Voltages ───────────────────────────────────────────────────────────────
    var vMap = _mappedDoubles(ocrText, _m6dVoltRe, 3.0, 4.45);
    if (vMap.isEmpty) vMap = _mappedDoubles(ocrText, _labeledVoltRe, 3.0, 4.45);

    final List<double> voltages;
    if (vMap.isNotEmpty) {
      final keys = vMap.keys.toList()..sort();
      voltages = keys.map((k) => vMap[k]!).toList();
    } else {
      voltages = _bareVoltRe
          .allMatches(ocrText)
          .map((m) => double.tryParse(m.group(1)!) ?? 0)
          .where((v) => v >= 3.0 && v <= 4.45)
          .toList();
    }

    // ── IR ─────────────────────────────────────────────────────────────────────
    var irMap = _mappedInts(ocrText, _m6dIrRe, 1, 999);
    if (irMap.isEmpty) irMap = _mappedInts(ocrText, _labeledIrRe, 1, 999);

    final List<int> irValues;
    if (irMap.isNotEmpty) {
      final keys = irMap.keys.toList()..sort();
      irValues = keys.map((k) => irMap[k]!).toList();
    } else {
      irValues = _bareIrRe
          .allMatches(ocrText)
          .map((m) => int.tryParse(m.group(1)!) ?? 0)
          .where((v) => v >= 1 && v <= 999)
          .toList();
    }

    return ParsedCellData(voltages: voltages, irValues: irValues);
  }

  static Map<int, double> _mappedDoubles(
      String text, RegExp re, double lo, double hi) {
    final map = <int, double>{};
    for (final m in re.allMatches(text)) {
      final cell = int.tryParse(m.group(1)!) ?? 0;
      final v = double.tryParse(m.group(2)!) ?? 0;
      if (cell >= 1 && cell <= 8 && v >= lo && v <= hi) map[cell] = v;
    }
    return map;
  }

  static Map<int, int> _mappedInts(
      String text, RegExp re, int lo, int hi) {
    final map = <int, int>{};
    for (final m in re.allMatches(text)) {
      final cell = int.tryParse(m.group(1)!) ?? 0;
      final v = int.tryParse(m.group(2)!) ?? 0;
      if (cell >= 1 && cell <= 8 && v >= lo && v <= hi) map[cell] = v;
    }
    return map;
  }
}
