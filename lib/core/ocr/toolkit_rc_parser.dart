// lib/core/ocr/toolkit_rc_parser.dart
class ParsedCellData {
  final List<double> voltages;
  final List<int> irValues;

  const ParsedCellData({required this.voltages, required this.irValues});

  bool get isEmpty => voltages.isEmpty && irValues.isEmpty;
}

class ToolkitRcParser {
  // Matches: 3.87V, 4.200V, 3.850v
  static final _voltageRe = RegExp(r'(\d\.\d{2,3})\s*[Vv]');

  // Matches: 3mΩ, 12mO, 4m0, 5mR, 6MΩ (OCR often mangles Ω)
  static final _irRe = RegExp(r'(\d{1,3})\s*[mM][ΩΩQoO0Rr]', unicode: true);

  static ParsedCellData parse(String ocrText) {
    final voltages = _voltageRe
        .allMatches(ocrText)
        .map((m) => double.parse(m.group(1)!))
        .toList();

    final irValues = _irRe
        .allMatches(ocrText)
        .map((m) => int.parse(m.group(1)!))
        .toList();

    return ParsedCellData(voltages: voltages, irValues: irValues);
  }
}
