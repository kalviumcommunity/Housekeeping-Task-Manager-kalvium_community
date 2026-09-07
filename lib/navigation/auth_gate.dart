import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/enums.dart';
import '../core/theme/app_theme.dart';
import '../screens/auth/login_screen.dart';
import '../screens/employee/employee_home_screen.dart';
import '../screens/supervisor/supervisor_home_screen.dart';
import '../services/app_state.dart';

/// Root navigation guard (PRD §36). Listens to [AppState] and renders
/// exactly one of: splash / login / employee shell / supervisor shell.
/// This is the only place role-based routing happens, which avoids
/// navigation loops and keeps auth guards centralized.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    switch (appState.status) {
      case AuthStatus.loading:
        return const _Splash();
      case AuthStatus.signedOut:
      case AuthStatus.profileMissing:
        return const LoginScreen();
      case AuthStatus.signedIn:
        final user = appState.currentUser!;
        if (user.role == UserRole.supervisor) {
          return const SupervisorHomeScreen();
        }
        return const EmployeeHomeScreen();
    }
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cleaning_services_rounded, color: Colors.white, size: 56),
            SizedBox(height: 16),
            Text(
              'WardClean',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
