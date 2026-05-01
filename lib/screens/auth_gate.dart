import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:midnight_pulse/auth/login_page.dart';
import 'package:midnight_pulse/providers/auth_providers.dart';
import 'package:midnight_pulse/screens/main_screen.dart';
import 'package:midnight_pulse/screens/splash_screen.dart';
import 'package:midnight_pulse/theme/app_theme.dart';

/// Central auth gate that listens to auth state and routes accordingly.
/// - Loading → SplashScreen
/// - Authenticated → MainScreen
/// - Unauthenticated → LoginPage
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const SplashScreen(),
      error: (_, __) => const _AuthErrorScreen(),
      data: (user) {
        if (user != null) {
          return const MainScreen();
        }
        return const LoginPage();
      },
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Color(0xFFFF8A80),
            ),
            const SizedBox(height: 16),
            Text(
              'Connection Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to connect to Firebase.\nPlease check your internet connection.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
