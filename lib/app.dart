// lib/app.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/battery_list/battery_list_screen.dart';
import 'features/add_battery/add_battery_screen.dart';
import 'features/battery_detail/battery_detail_screen.dart';
import 'features/log_charge/capture_screen.dart';
import 'features/log_charge/confirm_screen.dart';
import 'features/log_charge/save_screen.dart';
import 'features/print_label/print_label_screen.dart';
import 'features/charts/battery_charts_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/battery_list/qr_scan_screen.dart';

// Nested route structure ensures GoRouter builds a proper back-stack:
// context.go('/battery/$id') creates [BatteryList → BatteryDetail],
// so the Android back button from BatteryDetail returns to BatteryList.
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const BatteryListScreen(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (_, __) => const AddBatteryScreen(),
        ),
        GoRoute(
          path: 'scan',
          builder: (_, __) => const QrScanScreen(),
        ),
        GoRoute(
          path: 'settings',
          builder: (_, __) => const SettingsScreen(),
        ),
        GoRoute(
          path: 'battery/:id',
          builder: (_, state) =>
              BatteryDetailScreen(batteryId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'log/capture',
              builder: (_, state) =>
                  CaptureScreen(batteryId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: 'log/confirm',
              builder: (_, state) =>
                  ConfirmScreen(batteryId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: 'log/save',
              builder: (_, state) =>
                  SaveScreen(batteryId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: 'print',
              builder: (_, state) =>
                  PrintLabelScreen(batteryId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: 'charts',
              builder: (_, state) =>
                  BatteryChartsScreen(batteryId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    ),
  ],
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'LIPO MGR',
        theme: AppTheme.dark,
        routerConfig: _router,
      );
}
