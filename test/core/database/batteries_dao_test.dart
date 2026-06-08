import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpv_battery_manager/core/database/batteries_dao.dart';
import 'package:fpv_battery_manager/core/database/database.dart';

void main() {
  late AppDatabase db;
  late BatteriesDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = BatteriesDao(db);
  });

  tearDown(() => db.close());

  test('insert and fetch battery', () async {
    await dao.insertBattery(
      id: 'test-uuid',
      label: '6S RACE #1',
      cellCount: 6,
      capacityMah: 1300,
      notes: null,
    );
    final all = await dao.getAllBatteries();
    expect(all.length, 1);
    expect(all.first.label, '6S RACE #1');
    expect(all.first.cellCount, 6);
  });

  test('get battery by id', () async {
    await dao.insertBattery(
      id: 'abc',
      label: 'TEST',
      cellCount: 4,
      capacityMah: 650,
      notes: 'slight puff',
    );
    final b = await dao.getBatteryById('abc');
    expect(b, isNotNull);
    expect(b!.notes, 'slight puff');
  });

  test('get battery by qr returns null for unknown id', () async {
    final b = await dao.getBatteryById('unknown');
    expect(b, isNull);
  });

  test('update battery label', () async {
    await dao.insertBattery(
      id: 'x',
      label: 'OLD',
      cellCount: 6,
      capacityMah: 1300,
      notes: null,
    );
    await dao.updateBattery(id: 'x', label: 'NEW', notes: 'updated');
    final b = await dao.getBatteryById('x');
    expect(b!.label, 'NEW');
    expect(b.notes, 'updated');
  });

  test('delete battery', () async {
    await dao.insertBattery(
      id: 'del',
      label: 'GONE',
      cellCount: 4,
      capacityMah: 650,
      notes: null,
    );
    await dao.deleteBattery('del');
    expect(await dao.getAllBatteries(), isEmpty);
  });
}
