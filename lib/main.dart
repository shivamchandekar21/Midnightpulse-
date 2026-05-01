import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:midnight_pulse/firebase_options.dart';
import 'package:midnight_pulse/providers/auth_providers.dart';
import 'package:midnight_pulse/screens/auth_gate.dart';
import 'package:midnight_pulse/services/fcm_service.dart';
import 'package:midnight_pulse/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key, this.home});

  final Widget? home;

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _fcmInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fcmInitialized) return;
    _fcmInitialized = true;

    final uid = ref.read(currentUserIdProvider);
    final userService = ref.read(userFirestoreServiceProvider);
    FcmService(userService, uid).initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Midnight Pulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: widget.home ?? const AuthGate(),
    );
  }
}
