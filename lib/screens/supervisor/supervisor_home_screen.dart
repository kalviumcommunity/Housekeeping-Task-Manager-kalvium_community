import 'package:flutter/material.dart';
import '../shared/profile_screen.dart';
import 'dashboard_tab.dart';
import 'issues_tab.dart';
import 'reports_tab.dart';
import 'tasks_tab.dart';

/// PRD §21 — supervisor navigation: Dashboard, Tasks, Issues, Reports, Profile.
class SupervisorHomeScreen extends StatefulWidget {
  const SupervisorHomeScreen({super.key});

  @override
  State<SupervisorHomeScreen> createState() => _SupervisorHomeScreenState();
}

class _SupervisorHomeScreenState extends State<SupervisorHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [
      DashboardTab(),
      TasksTab(),
      IssuesTab(),
      ReportsTab(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.report_problem_outlined), label: 'Issues'),
          NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
