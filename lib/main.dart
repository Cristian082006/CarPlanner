import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/region_service.dart';
import 'utils/constants.dart';

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
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
            appBarTheme: const AppBarTheme(centerTitle: false),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
