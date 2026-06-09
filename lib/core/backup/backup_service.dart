// lib/core/backup/backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/batteries_dao.dart';
import '../database/charge_logs_dao.dart';

class BackupResult {
  final bool cancelled;
  final String? error;
  final int? batteriesAdded;
  final int? logsAdded;

  const BackupResult._({
    this.cancelled = false,
    this.error,
    this.batteriesAdded,
    this.logsAdded,
  });

  factory BackupResult.cancelled() => const BackupResult._(cancelled: true);
  factory BackupResult.error(String msg) => BackupResult._(error: msg);
  factory BackupResult.success({
    required int batteriesAdded,
    required int logsAdded,
  }) =>
      BackupResult._(batteriesAdded: batteriesAdded, logsAdded: logsAdded);

  bool get isSuccess => batteriesAdded != null;
}

class BackupService {
  static Future<void> exportBackup(
    BatteriesDao batteriesDao,
    ChargeLogsDao logsDao,
  ) async {
    final batteries = await batteriesDao.getAllBatteries();
    final logs = await logsDao.getAllLogs();

    final payload = jsonEncode({
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'batteries': batteries.map((b) => b.toJson()).toList(),
      'charge_logs': logs.map((l) => l.toJson()).toList(),
    });

    final cacheDir = await getTemporaryDirectory();
    final fileName =
        'lipo_mgr_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';
    final file = File(p.join(cacheDir.path, fileName));
    await file.writeAsString(payload);

    await Share.shareXFiles([XFile(file.path)], text: 'LIPO MGR backup');
  }

  static Future<BackupResult> importBackup(
    BatteriesDao batteriesDao,
    ChargeLogsDao logsDao,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) {
      return BackupResult.cancelled();
    }

    final filePath = result.files.first.path;
    if (filePath == null) return BackupResult.error('Could not read file path');

    final String content;
    try {
      content = await File(filePath).readAsString();
    } catch (_) {
      return BackupResult.error('Could not read file');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return BackupResult.error('Invalid JSON — not a LIPO MGR backup');
    }

    if ((json['version'] as int?) != 1) {
      return BackupResult.error('Unsupported backup version');
    }

    final batteryList =
        (json['batteries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final logList =
        (json['charge_logs'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    var batteriesAdded = 0;
    var logsAdded = 0;

    for (final b in batteryList) {
      final existing =
          await batteriesDao.getBatteryById(b['id'] as String? ?? '');
      if (existing != null) continue;
      try {
        await batteriesDao.insertBattery(
          id: b['id'] as String,
          label: b['label'] as String,
          cellCount: (b['cellCount'] as num).toInt(),
          capacityMah: (b['capacityMah'] as num).toInt(),
          notes: b['notes'] as String?,
          isPuffed: b['isPuffed'] as bool? ?? false,
        );
        batteriesAdded++;
      } catch (_) {}
    }

    for (final l in logList) {
      try {
        final rawLoggedAt = l['loggedAt'];
        final loggedAt = rawLoggedAt is int
            ? DateTime.fromMicrosecondsSinceEpoch(rawLoggedAt)
            : DateTime.parse(rawLoggedAt.toString());
        final voltages =
            (jsonDecode(l['cellVoltages'] as String) as List).cast<double>();
        final irValues =
            (jsonDecode(l['cellIr'] as String) as List).cast<int>();
        await logsDao.insertLogIfNew(
          id: l['id'] as String,
          batteryId: l['batteryId'] as String,
          loggedAt: loggedAt,
          cellVoltages: voltages,
          cellIr: irValues,
          logType: l['logType'] as String? ?? 'post_charge',
          notes: l['notes'] as String?,
        );
        logsAdded++;
      } catch (_) {}
    }

    return BackupResult.success(
        batteriesAdded: batteriesAdded, logsAdded: logsAdded);
  }
}
