// lib/app.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/battery_list/battery_list_screen.dart';

// Screen imports — these files don't exist yet, so use placeholder widgets
// They will be filled in by later tasks. Use a simple scaffold as placeholder.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen(this.title);
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(title)),
      );
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const BatteryListScreen(),
    ),
    GoRoute(
      path: '/add',
      builder: (_, __) => const _PlaceholderScreen('ADD BATTERY'),
    ),
    GoRoute(
      path: '/battery/:id',
      builder: (_, state) =>
          _PlaceholderScreen('BATTERY ${state.pathParameters['id']}'),
    ),
    GoRoute(
      path: '/battery/:id/log/capture',
      builder: (_, state) =>
          _PlaceholderScreen('CAPTURE ${state.pathParameters['id']}'),
    ),
    GoRoute(
      path: '/battery/:id/log/confirm',
      builder: (_, state) =>
          _PlaceholderScreen('CONFIRM ${state.pathParameters['id']}'),
    ),
    GoRoute(
      path: '/battery/:id/log/save',
      builder: (_, state) =>
          _PlaceholderScreen('SAVE ${state.pathParameters['id']}'),
    ),
    GoRoute(
      path: '/battery/:id/print',
      builder: (_, state) =>
          _PlaceholderScreen('PRINT ${state.pathParameters['id']}'),
    ),
    GoRoute(
      path: '/scan',
      builder: (_, __) => const _PlaceholderScreen('QR SCAN'),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const _PlaceholderScreen('SETTINGS'),
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
