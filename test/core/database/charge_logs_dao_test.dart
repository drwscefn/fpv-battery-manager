// test/core/database/charge_logs_dao_test.dart
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpv_battery_manager/core/database/batteries_dao.dart';
import 'package:fpv_battery_manager/core/database/charge_logs_dao.dart';
import 'package:fpv_battery_manager/core/database/database.dart';

void main() {
  late AppDatabase db;
  late BatteriesDao batteriesDao;
  late ChargeLogsDao logsDao;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    batteriesDao = BatteriesDao(db);
    logsDao = ChargeLogsDao(db);
    await batteriesDao.insertBattery(
      id: 'bat1',
      label: '6S #1',
      cellCount: 6,
      capacityMah: 1300,
      notes: null,
    );
  });

  tearDown(() => db.close());

  test('insert and fetch log', () async {
    await logsDao.insertLog(
      id: 'log1',
      batteryId: 'bat1',
      cellVoltages: [3.87, 3.86, 3.88, 3.87, 3.86, 3.87],
      cellIr: [3, 3, 4, 3, 3, 3],
      notes: null,
    );
    final logs = await logsDao.getLogsForBattery('bat1');
    expect(logs.length, 1);
    final voltages = (jsonDecode(logs.first.cellVoltages) as List).cast<double>();
    expect(voltages[0], 3.87);
  });

  test('get last N logs', () async {
    for (var i = 0; i < 8; i++) {
      await logsDao.insertLog(
        id: 'log$i',
        batteryId: 'bat1',
        cellVoltages: [3.87],
        cellIr: [3],
        notes: null,
      );
    }
    final last5 = await logsDao.getRecentLogs('bat1', limit: 5);
    expect(last5.length, 5);
  });

  test('delete log', () async {
    await logsDao.insertLog(
      id: 'log1',
      batteryId: 'bat1',
      cellVoltages: [3.87],
      cellIr: [3],
      notes: null,
    );
    await logsDao.deleteLog('log1');
    expect(await logsDao.getLogsForBattery('bat1'), isEmpty);
  });
}
