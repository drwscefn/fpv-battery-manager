// lib/core/printing/niimbot_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class NiimbotService {
  static const _serviceUuid = '0000ff00-0000-1000-8000-00805f9b34fb';

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;

  Future<void> connect() async {
    final completer = Completer<ScanResult?>();
    StreamSubscription? sub;
    sub = FlutterBluePlus.scanResults.listen((results) {
      final match = results.firstOrNull;
      if (match != null && !completer.isCompleted) {
        completer.complete(match);
      }
    });

    await FlutterBluePlus.startScan(
      withServices: [Guid(_serviceUuid)],
      timeout: const Duration(seconds: 10),
    );
    final result = await completer.future.timeout(
      const Duration(seconds: 11),
      onTimeout: () => null,
    );
    sub.cancel();
    await FlutterBluePlus.stopScan();

    if (result == null) throw Exception('No Niimbot device found');

    _device = result.device;
    await _device!.connect(timeout: const Duration(seconds: 10));

    final services = await _device!.discoverServices();
    for (final service in services) {
      if (service.uuid.toString().startsWith('0000ff00')) {
        for (final char in service.characteristics) {
          if (char.uuid.toString().startsWith('0000ff02')) {
            _writeChar = char;
          }
        }
      }
    }
    if (_writeChar == null) {
      throw Exception('Niimbot write characteristic not found');
    }
  }

  Future<void> printLabel(String text) async {
    if (_writeChar == null) throw Exception('Not connected');
    final payload = _encodeLabel(text);
    await _writeChar!.write(payload, withoutResponse: false);
  }

  /// Encodes a simple text label as a Niimbot print packet.
  /// This is a stub — replace with full Niimbot protocol encoding.
  Uint8List _encodeLabel(String text) {
    // Minimum viable Niimbot packet: header + ASCII text bytes + footer
    final bytes = text.codeUnits;
    return Uint8List.fromList([
      0x55, 0x55,           // Niimbot packet header
      0x00, bytes.length,   // length
      ...bytes,
      0xAA, 0xAA,           // Niimbot packet footer
    ]);
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
    _device = null;
    _writeChar = null;
  }
}
