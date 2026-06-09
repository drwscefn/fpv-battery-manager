// lib/core/printing/niimbot_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:qr/qr.dart';

class NiimbotService {
  static const _serviceUuid = '0000ff00-0000-1000-8000-00805f9b34fb';

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;

  // ── Packet helpers ──────────────────────────────────────────────────────────

  static Uint8List _buildPacket(int cmd, List<int> data) {
    int checksum = cmd ^ data.length;
    for (final b in data) {
      checksum ^= b;
    }
    return Uint8List.fromList([
      0x55, 0x55,
      cmd, data.length,
      ...data,
      checksum,
      0xAA, 0xAA,
    ]);
  }

  // ── Commands ─────────────────────────────────────────────────────────────────

  static const _cmdGetInfo       = 0x40;
  static const _cmdSetDensity    = 0x21;
  static const _cmdSetLabelType  = 0x23;
  static const _cmdStartPrint    = 0x01;
  static const _cmdEndPrint      = 0xF3;
  static const _cmdStartPage     = 0x03;
  static const _cmdEndPage       = 0xE3;
  static const _cmdSetDimension  = 0x13;
  static const _cmdSetQuantity   = 0x15;
  static const _cmdPrintRow      = 0x85;

  // ── Connection ───────────────────────────────────────────────────────────────

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

    if (result == null) throw Exception('No Niimbot device found nearby');

    _device = result.device;
    await _device!.connect(timeout: const Duration(seconds: 10));

    final services = await _device!.discoverServices();
    for (final svc in services) {
      if (svc.uuid.toString().toLowerCase().contains('ff00')) {
        for (final char in svc.characteristics) {
          final u = char.uuid.toString().toLowerCase();
          if (u.contains('ff02')) _writeChar = char;
          if (u.contains('ff01')) _notifyChar = char;
        }
      }
    }
    if (_writeChar == null) throw Exception('Niimbot write characteristic not found');

    if (_notifyChar != null) {
      await _notifyChar!.setNotifyValue(true);
    }
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
    _device = null;
    _writeChar = null;
    _notifyChar = null;
  }

  // ── Low-level write ──────────────────────────────────────────────────────────

  Future<void> _send(int cmd, List<int> data) async {
    final packet = _buildPacket(cmd, data);
    // BLE MTU is typically 20 bytes; chunk if needed
    const mtu = 20;
    for (int i = 0; i < packet.length; i += mtu) {
      final end = (i + mtu < packet.length) ? i + mtu : packet.length;
      await _writeChar!.write(
        packet.sublist(i, end),
        withoutResponse: false,
      );
    }
    await Future.delayed(const Duration(milliseconds: 20));
  }

  // ── Print flow ───────────────────────────────────────────────────────────────

  /// Prints a QR code label for [text] on a 25×25mm label.
  /// Label pixel dimensions for Niimbot D11/B21 at 203 DPI:
  ///   25mm × 203 DPI / 25.4 ≈ 200 px wide, 200 px tall
  Future<void> printLabel(String text) async {
    if (_writeChar == null) throw Exception('Not connected — call connect() first');

    const labelWidthPx = 200;
    const labelHeightPx = 200;

    final bitmap = _renderQrBitmap(text, labelWidthPx, labelHeightPx);

    // Wake / get info
    await _send(_cmdGetInfo, [0x00]);
    await Future.delayed(const Duration(milliseconds: 100));

    // Configure label
    await _send(_cmdSetDensity, [0x03]);           // density 3/5
    await _send(_cmdSetLabelType, [0x01]);         // gap label
    await _send(_cmdStartPrint, [0x01]);
    await _send(_cmdStartPage, [0x00]);
    await _send(_cmdSetDimension, [
      (labelHeightPx >> 8) & 0xFF,
      labelHeightPx & 0xFF,
      (labelWidthPx >> 8) & 0xFF,
      labelWidthPx & 0xFF,
    ]);
    await _send(_cmdSetQuantity, [0x00, 0x01]);    // 1 copy

    // Send bitmap rows
    final bytesPerRow = (labelWidthPx / 8).ceil();
    for (int row = 0; row < labelHeightPx; row++) {
      final rowData = bitmap.sublist(row * bytesPerRow, (row + 1) * bytesPerRow);
      await _send(_cmdPrintRow, [
        (row >> 8) & 0xFF,
        row & 0xFF,
        0x00,
        ...rowData,
      ]);
    }

    await _send(_cmdEndPage, [0x00]);
    await _send(_cmdEndPrint, [0x00]);
  }

  // ── Bitmap rendering ─────────────────────────────────────────────────────────

  /// Renders [text] as a QR code into a 1-bit packed bitmap (MSB first).
  /// Returns bytes of length [height] * ceil([width] / 8).
  static Uint8List _renderQrBitmap(String text, int width, int height) {
    final qr = QrCode.fromData(
      data: text,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final img = QrImage(qr);
    final moduleCount = qr.moduleCount;

    // Add quiet zone: use 90% of the label for the QR, centred
    const margin = 0.05; // 5% margin each side
    final qrSize = (width * (1 - 2 * margin)).floor();
    final offsetX = ((width - qrSize) / 2).floor();
    final offsetY = ((height - qrSize) / 2).floor();

    final bytesPerRow = (width / 8).ceil();
    final bytes = Uint8List(height * bytesPerRow);

    for (int py = 0; py < height; py++) {
      for (int px = 0; px < width; px++) {
        // Map pixel to QR module
        final qx = px - offsetX;
        final qy = py - offsetY;
        bool dark = false;
        if (qx >= 0 && qy >= 0 && qx < qrSize && qy < qrSize) {
          final col = (qx * moduleCount / qrSize).floor();
          final row = (qy * moduleCount / qrSize).floor();
          if (col < moduleCount && row < moduleCount) {
            dark = img.isDark(row, col);
          }
        }
        if (dark) {
          final byteIndex = py * bytesPerRow + (px ~/ 8);
          final bitIndex = 7 - (px % 8);
          bytes[byteIndex] |= (1 << bitIndex);
        }
      }
    }
    return bytes;
  }
}
