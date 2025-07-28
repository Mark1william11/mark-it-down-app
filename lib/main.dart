// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mark_it_down_v2/firebase_options.dart';
import 'package:mark_it_down_v2/logic/notification_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'presentation/notifiers/theme_notifier.dart' hide AppTheme;
import 'presentation/theme/app_theme.dart';
import 'routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Use the CORRECT class name: FirebaseAppCheck
  await FirebaseAppCheck.instance.activate(
    // For this portfolio app, we'll only configure for Android debug.
    androidProvider: AndroidProvider.debug,
  );
  
  final container = ProviderContainer();
  final notificationService = container.read(notificationServiceProvider);
  await notificationService.init();
  await notificationService.requestPermissions();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeProvider).valueOrNull ?? ThemeMode.system;
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Mark It Down',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}