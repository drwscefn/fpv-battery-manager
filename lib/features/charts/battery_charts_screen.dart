// lib/features/charts/battery_charts_screen.dart
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import '../../core/theme/app_theme.dart';
import '../battery_detail/battery_detail_provider.dart';

class BatteryChartsScreen extends ConsumerStatefulWidget {
  final String batteryId;
  const BatteryChartsScreen({super.key, required this.batteryId});

  @override
  ConsumerState<BatteryChartsScreen> createState() =>
      _BatteryChartsScreenState();
}

class _BatteryChartsScreenState extends ConsumerState<BatteryChartsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(batteryLogsProvider(widget.batteryId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('// CHARTS //'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'IR TREND'),
            Tab(text: 'VOLTAGE'),
            Tab(text: 'BALANCE'),
          ],
        ),
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('ERROR: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Text(
                'NO LOGS YET\nLOG A CHARGE TO SEE GRAPHS',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary, letterSpacing: 2),
              ),
            );
          }
          final sorted = [...logs]
            ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
          return TabBarView(
            controller: _tabs,
            children: [
              _IrChart(logs: sorted),
              _VoltageChart(logs: sorted),
              _BalanceChart(logs: sorted),
            ],
          );
        },
      ),
    );
  }
}

// ── Cell colours ──────────────────────────────────────────────────────────────

const _cellColors = <Color>[
  AppColors.accent,
  Color(0xFF00D4FF),
  Color(0xFFFF6B35),
  Color(0xFF4ADE80),
  Color(0xFFE879F9),
  Color(0xFFFF4500),
];

// ── Shared chart decoration ───────────────────────────────────────────────────

FlGridData _grid({double hInterval = 5}) => FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: hInterval,
      getDrawingHorizontalLine: (_) =>
          const FlLine(color: AppColors.border, strokeWidth: 0.8),
    );

FlBorderData _border() => FlBorderData(
      show: true,
      border: Border.all(color: AppColors.border),
    );

AxisTitles _hiddenAxis() =>
    const AxisTitles(sideTitles: SideTitles(showTitles: false));

Widget _dateLabel(int index, List<ChargeLog> logs) {
  if (index < 0 || index >= logs.length) return const Text('');
  final step = (logs.length / 4).ceil().clamp(1, logs.length);
  if (index % step != 0 && index != logs.length - 1) return const Text('');
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      DateFormat('d/M').format(logs[index].loggedAt),
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
    ),
  );
}

// ── IR chart ──────────────────────────────────────────────────────────────────

class _IrChart extends StatelessWidget {
  final List<ChargeLog> logs;
  const _IrChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    final firstIr = (jsonDecode(logs.first.cellIr) as List);
    final cellCount = firstIr.length;
    if (cellCount == 0) {
      return const Center(
          child: Text('NO IR DATA',
              style: TextStyle(color: AppColors.textSecondary)));
    }

    double maxIr = 0;
    final bars = List.generate(cellCount, (ci) {
      final spots = <FlSpot>[];
      for (int i = 0; i < logs.length; i++) {
        final ir = (jsonDecode(logs[i].cellIr) as List);
        if (ci < ir.length) {
          final v = (ir[ci] as num).toDouble();
          if (v > maxIr) maxIr = v;
          spots.add(FlSpot(i.toDouble(), v));
        }
      }
      return LineChartBarData(
        spots: spots,
        color: _cellColors[ci % _cellColors.length],
        barWidth: 2,
        isCurved: true,
        dotData: FlDotData(show: logs.length <= 10),
        belowBarData: BarAreaData(show: false),
      );
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: Column(
        children: [
          _Legend(cellCount: cellCount),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: _grid(hInterval: _irInterval(maxIr)),
                borderData: _border(),
                titlesData: FlTitlesData(
                  topTitles: _hiddenAxis(),
                  rightTitles: _hiddenAxis(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}mΩ',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (v, _) =>
                          _dateLabel(v.toInt(), logs),
                    ),
                  ),
                ),
                lineBarsData: bars,
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _irInterval(double max) {
    if (max < 20) return 5;
    if (max < 50) return 10;
    return 20;
  }
}

// ── Voltage chart ─────────────────────────────────────────────────────────────

class _VoltageChart extends StatelessWidget {
  final List<ChargeLog> logs;
  const _VoltageChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    double minV = double.infinity;
    double maxV = 0;
    final spots = <FlSpot>[];
    for (int i = 0; i < logs.length; i++) {
      final voltages = (jsonDecode(logs[i].cellVoltages) as List).cast<num>();
      if (voltages.isEmpty) continue;
      final pack = voltages.fold(0.0, (s, v) => s + v.toDouble());
      if (pack < minV) minV = pack;
      if (pack > maxV) maxV = pack;
      spots.add(FlSpot(i.toDouble(), pack));
    }

    if (spots.isEmpty) {
      return const Center(
          child: Text('NO VOLTAGE DATA',
              style: TextStyle(color: AppColors.textSecondary)));
    }

    final padding = (maxV - minV) * 0.15 + 0.5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: LineChart(
        LineChartData(
          gridData: _grid(hInterval: 1),
          borderData: _border(),
          titlesData: FlTitlesData(
            topTitles: _hiddenAxis(),
            rightTitles: _hiddenAxis(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (v, _) => Text(
                  '${v.toStringAsFixed(1)}V',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (v, _) => _dateLabel(v.toInt(), logs),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: AppColors.accent,
              barWidth: 2,
              isCurved: true,
              dotData: FlDotData(show: logs.length <= 10),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.accent.withValues(alpha: 0.08),
              ),
            ),
          ],
          minY: minV - padding,
          maxY: maxV + padding,
        ),
      ),
    );
  }
}

// ── Balance chart ─────────────────────────────────────────────────────────────

class _BalanceChart extends StatelessWidget {
  final List<ChargeLog> logs;
  const _BalanceChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    double maxImbalance = 0;
    final spots = <FlSpot>[];
    for (int i = 0; i < logs.length; i++) {
      final vs = (jsonDecode(logs[i].cellVoltages) as List).cast<num>();
      if (vs.isEmpty) continue;
      final mn = vs.reduce((a, b) => a < b ? a : b).toDouble();
      final mx = vs.reduce((a, b) => a > b ? a : b).toDouble();
      final imbalance = (mx - mn) * 1000; // convert to mV
      if (imbalance > maxImbalance) maxImbalance = imbalance;
      spots.add(FlSpot(i.toDouble(), imbalance));
    }

    if (spots.isEmpty) {
      return const Center(
          child: Text('NO VOLTAGE DATA',
              style: TextStyle(color: AppColors.textSecondary)));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: Column(
        children: [
          const Text(
            'CELL IMBALANCE (max − min) · lower is healthier',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 10, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: _grid(hInterval: _balanceInterval(maxImbalance)),
                borderData: _border(),
                titlesData: FlTitlesData(
                  topTitles: _hiddenAxis(),
                  rightTitles: _hiddenAxis(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}mV',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (v, _) =>
                          _dateLabel(v.toInt(), logs),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    color: _imbalanceColor(maxImbalance),
                    barWidth: 2,
                    isCurved: true,
                    dotData: FlDotData(show: logs.length <= 10),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _imbalanceColor(maxImbalance)
                          .withValues(alpha: 0.08),
                    ),
                  ),
                ],
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _balanceInterval(double max) {
    if (max < 10) return 2;
    if (max < 50) return 10;
    return 25;
  }

  Color _imbalanceColor(double maxMv) {
    if (maxMv > 30) return AppColors.warning;
    if (maxMv > 15) return AppColors.accent;
    return AppColors.healthy;
  }
}

// ── Cell legend ───────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  final int cellCount;
  const _Legend({required this.cellCount});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: List.generate(cellCount, (i) {
        final color = _cellColors[i % _cellColors.length];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 14, height: 2, color: color),
            const SizedBox(width: 4),
            Text(
              'C${i + 1}',
              style: TextStyle(
                  color: color, fontSize: 11, letterSpacing: 1),
            ),
          ],
        );
      }),
    );
  }
}
