import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'seed_data_tool.dart';

/// Debug-only screen that runs [SeedDataTool] and displays the resulting
/// credentials once. Never reachable in a release build — [isAvailable]
/// gates this both here and at the call site (LoginScreen's dev menu).
///
/// PRD §35 note: WardClean itself never displays passwords in normal
/// operation. This is the single, deliberate, debug-only exception,
/// purely so you have something to log in with the first time.
class SeedDataScreen extends StatefulWidget {
  const SeedDataScreen({super.key});

  static bool get isAvailable => kDebugMode;

  @override
  State<SeedDataScreen> createState() => _SeedDataScreenState();
}

class _SeedDataScreenState extends State<SeedDataScreen> {
  final _tool = SeedDataTool();
  bool _isRunning = false;
  List<String>? _log;
  String? _error;

  Future<void> _runSeed() async {
    setState(() {
      _isRunning = true;
      _error = null;
    });
    try {
      final log = await _tool.run();
      setState(() => _log = log);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed Demo Data (Debug Only)')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This creates 2 demo EMPLOYEE accounts only. Run '
              'scripts/seed_admin.js first to create the wards, the '
              'supervisor account, and demo task/issue records — see '
              'README "Seed Data" for the exact command.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Client apps are not allowed to create supervisor accounts or '
              'wards directly (see firestore.rules) — that restriction is '
              'intentional, not a bug, so this tool only does what an '
              'employee registering themselves could also do.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRunning ? null : _runSeed,
              child: _isRunning
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Run Seed'),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_log != null)
              Expanded(
                child: ListView(
                  children: _log!
                      .map((line) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: SelectableText(line),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
