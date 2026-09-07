import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/enums.dart';
import '../../models/task_model.dart';
import '../../repositories/issue_repository.dart';
import '../../repositories/task_repository.dart';
import '../../services/app_state.dart';
import '../../widgets/issue_card.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/task_card.dart';
import '../shared/issue_detail_screen.dart';
import '../shared/profile_screen.dart';
import '../shared/report_issue_screen.dart';
import 'task_detail_screen.dart';

/// PRD §14 — employee navigation: Home/My Tasks, Issues, History, Profile.
class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [
      _MyTasksTab(),
      _MyIssuesTab(),
      _HistoryTab(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist_rounded), label: 'My Tasks'),
          NavigationDestination(icon: Icon(Icons.report_problem_outlined), label: 'Issues'),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _MyTasksTab extends StatelessWidget {
  const _MyTasksTab();

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AppState>().currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: StreamBuilder<List<TaskModel>>(
        stream: TaskRepository().watchMyTasks(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading your tasks…');
          }
          if (snapshot.hasError) {
            return const ErrorView(message: 'Unable to load tasks. Please try again.');
          }
          final allTasks = snapshot.data ?? [];
          final activeTasks = allTasks
              .where((t) => t.status != TaskStatus.completed && t.status != TaskStatus.cancelled)
              .toList();

          if (activeTasks.isEmpty) {
            return const EmptyState(
              message: 'No tasks assigned yet.',
              icon: Icons.checklist_rounded,
            );
          }

          // Overdue and high-priority first.
          activeTasks.sort((a, b) {
            if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
            final ad = a.dueAt ?? DateTime(2100);
            final bd = b.dueAt ?? DateTime(2100);
            return ad.compareTo(bd);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: activeTasks.length,
            itemBuilder: (context, i) {
              final task = activeTasks[i];
              return TaskCard(
                task: task,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MyIssuesTab extends StatelessWidget {
  const _MyIssuesTab();

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AppState>().currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Issues')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ReportIssueScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Report Issue'),
      ),
      body: StreamBuilder(
        stream: IssueRepository().watchByReporter(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return const ErrorView(message: 'Unable to load issues.');
          }
          final issues = snapshot.data ?? [];
          if (issues.isEmpty) {
            return const EmptyState(message: 'No issues reported.', icon: Icons.report_outlined);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: issues.length,
            itemBuilder: (context, i) {
              final issue = issues[i];
              return IssueCard(
                issue: issue,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => IssueDetailScreen(issue: issue)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AppState>().currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: StreamBuilder<List<TaskModel>>(
        stream: TaskRepository().watchMyHistory(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return const ErrorView(message: 'Unable to load history.');
          }
          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return const EmptyState(message: 'No completed tasks yet.', icon: Icons.history_rounded);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: tasks.length,
            itemBuilder: (context, i) {
              final task = tasks[i];
              return TaskCard(
                task: task,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
