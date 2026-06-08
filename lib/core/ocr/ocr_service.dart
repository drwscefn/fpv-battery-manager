// lib/core/ocr/ocr_service.dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'toolkit_rc_parser.dart';

class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<ParsedCellData> recognizeFromPath(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(inputImage);
    final text = result.blocks.map((b) => b.text).join('\n');
    return ToolkitRcParser.parse(text);
  }

  void dispose() => _recognizer.close();
}
