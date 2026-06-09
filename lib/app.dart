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
import 'features/settings/settings_screen.dart';
import 'features/battery_list/qr_scan_screen.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const BatteryListScreen(),
    ),
    GoRoute(
      path: '/add',
      builder: (_, __) => const AddBatteryScreen(),
    ),
    GoRoute(
      path: '/battery/:id',
      builder: (_, state) =>
          BatteryDetailScreen(batteryId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/battery/:id/log/capture',
      builder: (_, state) =>
          CaptureScreen(batteryId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/battery/:id/log/confirm',
      builder: (_, state) =>
          ConfirmScreen(batteryId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/battery/:id/log/save',
      builder: (_, state) =>
          SaveScreen(batteryId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/battery/:id/print',
      builder: (_, state) =>
          PrintLabelScreen(batteryId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/scan',
      builder: (_, __) => const QrScanScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
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
