import 'package:flutter/material.dart';
import '../../core/constants/enums.dart';
import '../../models/issue_model.dart';
import '../../repositories/issue_repository.dart';
import '../../widgets/issue_card.dart';
import '../../widgets/state_widgets.dart';
import '../shared/issue_detail_screen.dart';
import '../shared/report_issue_screen.dart';
import 'recurring_issues_screen.dart';

/// PRD §27, §28 — supervisor issue management (open/resolved) + reporting.
class IssuesTab extends StatelessWidget {
  const IssuesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Issues'),
          bottom: const TabBar(
            tabs: [Tab(text: 'OPEN'), Tab(text: 'RESOLVED')],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.warning_amber_rounded),
              tooltip: 'Recurring Problem Areas',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RecurringIssuesScreen()),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ReportIssueScreen())),
          icon: const Icon(Icons.add),
          label: const Text('Report Issue'),
        ),
        body: const TabBarView(
          children: [
            _IssueList(status: IssueStatus.open),
            _IssueList(status: IssueStatus.resolved),
          ],
        ),
      ),
    );
  }
}

class _IssueList extends StatelessWidget {
  final IssueStatus status;
  const _IssueList({required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<IssueModel>>(
      stream: IssueRepository().watchByStatus(status),
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
                MaterialPageRoute(
                  builder: (_) => IssueDetailScreen(
                    issue: issue,
                    canResolve: status == IssueStatus.open,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
