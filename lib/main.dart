import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'services/notification_service.dart';
import 'services/region_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RegionService.instance.load();
  await NotificationService.instance.init();
  runApp(const CarPlannerApp());
}

class CarPlannerApp extends StatelessWidget {
  const CarPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: RegionService.instance.countryCode,
      builder: (context, countryCode, _) {
        return MaterialApp(
          key: ValueKey(countryCode),
          title: 'Auto Calendar',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.system,
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          home: const MainShell(),
        );
      },
    );
  }
}
