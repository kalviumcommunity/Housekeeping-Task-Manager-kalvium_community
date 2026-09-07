import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Screen displayed when Firebase is not yet configured or fails to initialize.
/// Prevents the app from crashing with an unhandled exception, and provides
/// clear, actionable setup instructions per PRD §65.
class FirebaseSetupScreen extends StatefulWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const FirebaseSetupScreen({
    super.key,
    this.errorMessage,
    required this.onRetry,
  });

  @override
  State<FirebaseSetupScreen> createState() => _FirebaseSetupScreenState();
}

class _FirebaseSetupScreenState extends State<FirebaseSetupScreen> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    setState(() => _isRetrying = true);
    await Future.delayed(const Duration(milliseconds: 500));
    widget.onRetry();
    if (mounted) setState(() => _isRetrying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WardClean Setup'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.cloud_sync_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Firebase Setup Required',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'WardClean uses real Firebase services (Authentication, Firestore, and Storage). Connect your Firebase project to start.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                const _StepCard(
                  number: '1',
                  title: 'Enable Firebase Services',
                  description:
                      'In Firebase Console, enable Email/Password Authentication, Cloud Firestore, and Firebase Storage.',
                ),
                const SizedBox(height: 12),
                const _StepCard(
                  number: '2',
                  title: 'Run FlutterFire Configure',
                  description:
                      'In terminal at project root, run:\nflutterfire configure\nThis generates real configuration in lib/firebase_options.dart.',
                ),
                const SizedBox(height: 12),
                const _StepCard(
                  number: '3',
                  title: 'Deploy Security Rules & Indexes',
                  description:
                      'firebase deploy --only firestore:rules,firestore:indexes,storage',
                ),
                if (widget.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.overdueBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.overdue.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      widget.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.overdue,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isRetrying ? null : _handleRetry,
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: const Text('Retry Connection'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Text(
                number,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
