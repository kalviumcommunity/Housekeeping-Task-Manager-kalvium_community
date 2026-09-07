import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/firestore_paths.dart';
import '../../core/theme/app_theme.dart';
import '../../models/issue_model.dart';
import '../../models/task_model.dart';
import '../../models/ward_model.dart';
import '../../repositories/issue_repository.dart';
import '../../repositories/task_repository.dart';
import '../../repositories/ward_repository.dart';
import '../../services/compliance_service.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/task_card.dart';
import 'supervisor_task_detail_screen.dart';

/// PRD §30, §31, §32 — daily compliance summary + ward filtering +
/// historical task records, all computed from real Firestore data.
class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  DateTime _selectedDate = DateTime.now();
  String? _wardFilter;

  Future<_ReportData>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ReportData> _load() async {
    final tasks = await TaskRepository().getTasksForDate(_selectedDate);
    final issues = await IssueRepository().getIssuesForDate(_selectedDate);
    final recentIssues =
        await IssueRepository().getRecentIssues(days: AppConstants.recurringIssueWindowDays);
    final recurring = ComplianceService.detectRecurringIssues(recentIssues);
    return _ReportData(tasks: tasks, issues: issues, recurringGroups: recurring);
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: FutureBuilder<_ReportData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Generating report…');
                }
                if (snapshot.hasError) {
                  return ErrorView(
                      message: 'Unable to generate report.', onRetry: _refresh);
                }
                final data = snapshot.data!;
                final filteredTasks = _wardFilter == null
                    ? data.tasks
                    : data.tasks.where((t) => t.wardId == _wardFilter).toList();
                final filteredIssues = _wardFilter == null
                    ? data.issues
                    : data.issues.where((i) => i.wardId == _wardFilter).toList();

                final summary = ComplianceService.buildDailySummary(
                  date: _selectedDate,
                  tasksForDay: filteredTasks,
                  issuesForDay: filteredIssues,
                  recurringGroups: data.recurringGroups,
                );

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Daily Compliance Summary',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(DateFormat('MMMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        SummaryCard(label: 'Total Tasks', value: '${summary.totalTasks}'),
                        SummaryCard(
                            label: 'Completed',
                            value: '${summary.completed}',
                            color: AppColors.completed),
                        SummaryCard(
                            label: 'Pending',
                            value: '${summary.pending}',
                            color: AppColors.pending),
                        SummaryCard(
                            label: 'In Progress',
                            value: '${summary.inProgress}',
                            color: AppColors.inProgress),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SummaryCard(
                      label: 'Completion Rate',
                      value: '${summary.completionRate}%',
                      icon: Icons.trending_up_rounded,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            label: 'Equipment Checks',
                            value:
                                '${summary.equipmentChecksCompleted}/${summary.equipmentChecksRequired}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SummaryCard(
                            label: 'Reported Issues',
                            value: '${summary.issuesReported}',
                            color: AppColors.overdue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SummaryCard(
                      label: 'Recurring Areas',
                      value: '${summary.recurringAreas}',
                      icon: Icons.warning_amber_rounded,
                    ),
                    const SizedBox(height: 24),
                    const Text('Historical Records',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    if (filteredTasks.isEmpty)
                      const EmptyState(message: 'No records found for this date.')
                    else
                      ...filteredTasks.map((task) => TaskCard(
                            task: task,
                            showEmployeeName: true,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => SupervisorTaskDetailScreen(task: task)),
                            ),
                          )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                  _refresh();
                }
              },
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StreamBuilder<List<WardModel>>(
              stream: WardRepository().watchActiveWards(),
              builder: (context, snapshot) {
                final wards = snapshot.data ?? [];
                return DropdownButtonFormField<String?>(
                  initialValue: _wardFilter,
                  decoration: const InputDecoration(
                    labelText: 'Ward',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Wards')),
                    ...wards.map(
                        (w) => DropdownMenuItem(value: w.wardId, child: Text(w.wardName))),
                  ],
                  onChanged: (v) => setState(() => _wardFilter = v),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportData {
  final List<TaskModel> tasks;
  final List<IssueModel> issues;
  final List<RecurringIssueGroup> recurringGroups;
  _ReportData({required this.tasks, required this.issues, required this.recurringGroups});
}
