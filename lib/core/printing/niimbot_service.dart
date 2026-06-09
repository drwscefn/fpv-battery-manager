// lib/core/printing/niimbot_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class NiimbotService {
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

  static const _cmdGetInfo          = 0x40;
  static const _cmdSetDensity       = 0x21;
  static const _cmdAllowPrintClear  = 0x20;
  static const _cmdSetLabelType     = 0x23;
  static const _cmdStartPrint       = 0x01;
  static const _cmdEndPrint         = 0xF3;
  static const _cmdStartPage        = 0x03;
  static const _cmdEndPage          = 0xE3;
  static const _cmdSetDimension     = 0x13;
  static const _cmdSetQuantity      = 0x15;
  static const _cmdPrintRow         = 0x85;

  // ── Connection ───────────────────────────────────────────────────────────────

  Future<void> connect() async {
    // Ensure BLE is on
    final adapterState = await FlutterBluePlus.adapterState
        .where((s) => s == BluetoothAdapterState.on)
        .first
        .timeout(const Duration(seconds: 5), onTimeout: () => BluetoothAdapterState.off);
    if (adapterState != BluetoothAdapterState.on) {
      throw Exception('Bluetooth is off — please enable it');
    }

    final completer = Completer<ScanResult?>();
    StreamSubscription? sub;

    sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final name = r.device.platformName.toLowerCase();
        if ((name.contains('niimbot') ||
                name.contains('d11') ||
                name.contains('b21') ||
                name.contains('b1_')) &&
            !completer.isCompleted) {
          completer.complete(r);
          break;
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    final result = await completer.future.timeout(
      const Duration(seconds: 11),
      onTimeout: () => null,
    );
    sub.cancel();
    await FlutterBluePlus.stopScan();

    if (result == null) {
      throw Exception(
          'No Niimbot device found — ensure printer is on and nearby');
    }

    _device = result.device;
    await _device!.connect(timeout: const Duration(seconds: 10));

    // Request larger MTU to avoid packet fragmentation
    await _device!.requestMtu(512);

    final services = await _device!.discoverServices();

    // Pass 1: prefer known Niimbot UUIDs (ff02 = write, ff01 = notify)
    for (final svc in services) {
      for (final char in svc.characteristics) {
        final id = char.uuid.toString().toLowerCase();
        if (id.contains('ff02')) _writeChar = char;
        if (id.contains('ff01')) _notifyChar = char;
      }
    }

    // Pass 2: fallback — match by GATT property (works for any model/clone)
    if (_writeChar == null) {
      for (final svc in services) {
        for (final char in svc.characteristics) {
          if (_writeChar == null &&
              (char.properties.write || char.properties.writeWithoutResponse)) {
            _writeChar = char;
          }
          if (_notifyChar == null &&
              (char.properties.notify || char.properties.indicate)) {
            _notifyChar = char;
          }
        }
      }
    }

    if (_writeChar == null) {
      // Build a diagnostic message listing what was actually found
      final found = services
          .expand((s) => s.characteristics)
          .map((c) => c.uuid.toString())
          .join(', ');
      throw Exception(
          'No writable BLE characteristic found. Characteristics: $found');
    }

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

  Future<void> _send(int cmd, List<int> data, {bool withoutResponse = false}) async {
    final packet = _buildPacket(cmd, data);
    const mtu = 512;
    for (int i = 0; i < packet.length; i += mtu) {
      final end = (i + mtu < packet.length) ? i + mtu : packet.length;
      await _writeChar!.write(
        packet.sublist(i, end),
        withoutResponse: withoutResponse,
      );
    }
    if (!withoutResponse) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  // ── Print flow ───────────────────────────────────────────────────────────────

  /// Prints a QR code label for [text].
  /// 96×96px — compatible with D11 (12mm) and larger models.
  Future<void> printLabel(String text) async {
    if (_writeChar == null) throw Exception('Not connected — call connect() first');

    // 96px wide × 96px tall — compatible with D11 (12mm) and larger models
    const labelWidthPx = 96;
    const labelHeightPx = 96;

    final bitmap = await _renderQrBitmap(text, labelWidthPx, labelHeightPx);
    final bytesPerRow = (labelWidthPx / 8).ceil(); // = 12

    // Wake printer and read device type
    await _send(_cmdGetInfo, [0x01]);
    await Future.delayed(const Duration(milliseconds: 200));

    // Configure label
    await _send(_cmdSetLabelType, [0x01]);  // gap-sensing labels
    await Future.delayed(const Duration(milliseconds: 100));
    await _send(_cmdSetDensity, [0x03]);    // density 3 of 5
    await Future.delayed(const Duration(milliseconds: 100));

    // Start print job
    await _send(_cmdStartPrint, [0x01]);
    await Future.delayed(const Duration(milliseconds: 100));

    // *** CRITICAL: must send ALLOW_PRINT_CLEAR before START_PAGE ***
    await _send(_cmdAllowPrintClear, [0x01]);
    await Future.delayed(const Duration(milliseconds: 100));

    // Start page — empty payload
    await _send(_cmdStartPage, []);
    await Future.delayed(const Duration(milliseconds: 100));

    // Dimensions: height (2 bytes big-endian), width (2 bytes big-endian)
    await _send(_cmdSetDimension, [
      (labelHeightPx >> 8) & 0xFF, labelHeightPx & 0xFF,
      (labelWidthPx >> 8) & 0xFF,  labelWidthPx & 0xFF,
    ]);
    await Future.delayed(const Duration(milliseconds: 100));

    // 1 copy
    await _send(_cmdSetQuantity, [0x00, 0x01]);
    await Future.delayed(const Duration(milliseconds: 100));

    // Send bitmap rows
    for (int row = 0; row < labelHeightPx; row++) {
      final rowData = bitmap.sublist(row * bytesPerRow, (row + 1) * bytesPerRow);
      await _send(
        _cmdPrintRow,
        [(row >> 8) & 0xFF, row & 0xFF, 0x00, ...rowData],
        withoutResponse: true,
      );
      // Yield every 16 rows to avoid flooding the BLE buffer
      if (row % 16 == 15) await Future.delayed(const Duration(milliseconds: 20));
    }
    await Future.delayed(const Duration(milliseconds: 200));

    // End page — empty payload
    await _send(_cmdEndPage, []);
    await Future.delayed(const Duration(milliseconds: 200));

    // End print — empty payload
    await _send(_cmdEndPrint, []);
  }

  // ── Bitmap rendering ─────────────────────────────────────────────────────────

  /// Renders [data] as a QR code into a 1-bit packed bitmap (MSB first).
  /// Uses QrPainter (same renderer as on-screen QrImageView) for reliability.
  /// Returns bytes of length [height] * ceil([width] / 8).
  static Future<Uint8List> _renderQrBitmap(
      String data, int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Solid white background
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );

    // Black QR modules, 5% margin each side
    final padding = width * 0.05;
    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: ui.Color(0xFF000000),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: ui.Color(0xFF000000),
      ),
    );
    canvas.save();
    canvas.translate(padding, padding);
    qrPainter.paint(
        canvas, ui.Size(width - 2 * padding, height - 2 * padding));
    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception('QR bitmap capture failed');

    final rgba = byteData.buffer.asUint8List();
    final bytesPerRow = (width / 8).ceil();
    final bitmap = Uint8List(height * bytesPerRow);

    for (int py = 0; py < height; py++) {
      for (int px = 0; px < width; px++) {
        final i = (py * width + px) * 4; // RGBA stride
        // Dark pixel (sum < 384 covers pure black; threshold generous for anti-alias)
        if (rgba[i] + rgba[i + 1] + rgba[i + 2] < 384) {
          final byteIndex = py * bytesPerRow + (px ~/ 8);
          bitmap[byteIndex] |= (1 << (7 - (px % 8))); // MSB first
        }
      }
    }
    return bitmap;
  }
}
