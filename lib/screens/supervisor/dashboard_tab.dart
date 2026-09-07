import 'package:flutter/material.dart';
import '../../core/constants/enums.dart';
import '../../core/constants/firestore_paths.dart';
import '../../core/theme/app_theme.dart';
import '../../models/issue_model.dart';
import '../../models/task_model.dart';
import '../../repositories/issue_repository.dart';
import '../../repositories/task_repository.dart';
import '../../services/compliance_service.dart';
import '../../widgets/state_widgets.dart';
import 'recurring_issues_screen.dart';

/// PRD §21, §24 — real-time supervisor dashboard. Scoped to *today's*
/// tasks (rather than the entire tasks collection) to keep the query
/// small and fast per PRD §51.
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: StreamBuilder<List<TaskModel>>(
        stream: TaskRepository().watchTasks(TaskFilter(date: DateTime.now())),
        builder: (context, taskSnap) {
          if (taskSnap.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading dashboard…');
          }
          if (taskSnap.hasError) {
            return const ErrorView(message: 'Unable to load dashboard data.');
          }
          final tasks = taskSnap.data ?? [];

          return StreamBuilder<List<IssueModel>>(
            stream: IssueRepository()
                .watchRecent(days: AppConstants.recurringIssueWindowDays),
            builder: (context, issueSnap) {
              final recentIssues = issueSnap.data ?? [];
              final recurring = ComplianceService.detectRecurringIssues(recentIssues);
              final openIssuesToday =
                  recentIssues.where((i) => i.status == IssueStatus.open).length;

              final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
              final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
              final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
              final overdue = ComplianceService.countOverdue(tasks);
              final completionRate = tasks.isEmpty
                  ? 0
                  : ((completed / tasks.length) * 100).round();

              final byWard = <String, int>{};
              for (final t in tasks) {
                byWard[t.wardName] = (byWard[t.wardName] ?? 0) + 1;
              }

              return RefreshIndicator(
                onRefresh: () async {},
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text("Today's Overview",
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        SummaryCard(
                            label: 'Pending', value: '$pending', color: AppColors.pending),
                        SummaryCard(
                            label: 'In Progress',
                            value: '$inProgress',
                            color: AppColors.inProgress),
                        SummaryCard(
                            label: 'Completed',
                            value: '$completed',
                            color: AppColors.completed),
                        SummaryCard(
                            label: 'Overdue', value: '$overdue', color: AppColors.overdue),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SummaryCard(
                      label: 'Completion Rate',
                      value: '$completionRate%',
                      icon: Icons.trending_up_rounded,
                    ),
                    const SizedBox(height: 20),
                    if (byWard.isNotEmpty) ...[
                      const Text('Tasks by Ward',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      ...byWard.entries.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(child: Text(e.key)),
                                Text('${e.value}',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )),
                      const SizedBox(height: 20),
                    ],
                    const Text('Issues',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    SummaryCard(
                      label: 'Open Issues (last 7 days)',
                      value: '$openIssuesToday',
                      color: AppColors.overdue,
                      icon: Icons.report_problem_outlined,
                    ),
                    const SizedBox(height: 12),
                    if (recurring.isNotEmpty)
                      Card(
                        color: AppColors.overdueBg,
                        child: ListTile(
                          leading: const Icon(Icons.warning_amber_rounded,
                              color: AppColors.overdue),
                          title: Text('${recurring.length} Recurring Problem Area(s)',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Tap to view details'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RecurringIssuesScreen()),
                          ),
                        ),
                      )
                    else
                      const EmptyState(
                        message: 'No recurring problem areas found.',
                        icon: Icons.check_circle_outline,
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
