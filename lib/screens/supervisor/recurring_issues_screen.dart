import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/firestore_paths.dart';
import '../../core/theme/app_theme.dart';
import '../../models/issue_model.dart';
import '../../repositories/issue_repository.dart';
import '../../services/compliance_service.dart';
import '../../widgets/issue_card.dart';
import '../../widgets/state_widgets.dart';
import '../shared/issue_detail_screen.dart';

/// PRD §29 — recurring problem area detection & drill-down.
class RecurringIssuesScreen extends StatelessWidget {
  const RecurringIssuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Problem Areas')),
      body: StreamBuilder<List<IssueModel>>(
        stream: IssueRepository().watchRecent(days: AppConstants.recurringIssueWindowDays),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return const ErrorView(message: 'Unable to load recurring issues.');
          }
          final groups = ComplianceService.detectRecurringIssues(snapshot.data ?? []);
          if (groups.isEmpty) {
            return const EmptyState(
              message: 'No recurring problem areas found.',
              icon: Icons.check_circle_outline,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: groups.length,
            itemBuilder: (context, i) {
              final group = groups[i];
              final dates = group.issues
                  .map((issue) => issue.createdAt)
                  .whereType<DateTime>()
                  .toList()
                ..sort();
              final dateRangeStr = dates.isNotEmpty
                  ? (dates.first.isAtSameMomentAs(dates.last)
                      ? dateFormat.format(dates.first)
                      : '${dateFormat.format(dates.first)} – ${dateFormat.format(dates.last)}')
                  : 'Last ${AppConstants.recurringIssueWindowDays} days';

              return Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.warning_amber_rounded, color: AppColors.overdue),
                  title: Text('${group.wardName} — ${group.roomOrArea}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        '${group.count} ${group.issueType.value} issues reported',
                        style: const TextStyle(color: AppColors.overdue, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Date Range: $dateRangeStr',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  children: group.issues
                      .map((issue) => IssueCard(
                            issue: issue,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    IssueDetailScreen(issue: issue, canResolve: true),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
