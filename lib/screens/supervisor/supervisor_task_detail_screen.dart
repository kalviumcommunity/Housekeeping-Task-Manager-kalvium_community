import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/task_model.dart';
import '../../widgets/status_badge.dart';
import '../shared/report_issue_screen.dart';

/// PRD §21, §24 — supervisor's read-only view of a task. Supervisors
/// monitor status via real-time listeners; they never start/complete a
/// task on an employee's behalf (enforced in security rules too).
class SupervisorTaskDetailScreen extends StatelessWidget {
  final TaskModel task;
  const SupervisorTaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy · h:mm a');

    return Scaffold(
      appBar: AppBar(title: Text(task.taskType.value)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${task.wardName} — ${task.roomOrArea}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              StatusBadge(status: task.status, overdue: task.isOverdue),
            ],
          ),
          const SizedBox(height: 4),
          PriorityBadge(priority: task.priority),
          const SizedBox(height: 20),
          if (task.description.isNotEmpty) ...[
            const Text('Description',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(task.description, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 20),
          ],
          _Row(label: 'Assigned To', value: task.assignedEmployeeName),
          _Row(label: 'Due', value: task.dueAt != null ? dateFormat.format(task.dueAt!) : '—'),
          _Row(
              label: 'Created',
              value: task.createdAt != null ? dateFormat.format(task.createdAt!) : '—'),
          if (task.startedAt != null)
            _Row(label: 'Started', value: dateFormat.format(task.startedAt!)),
          if (task.completedAt != null)
            _Row(label: 'Completed', value: dateFormat.format(task.completedAt!)),
          if (task.completionNote != null && task.completionNote!.isNotEmpty)
            _Row(label: 'Note', value: task.completionNote!),
          if (task.imageUrl != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: task.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ReportIssueScreen(
                relatedTaskId: task.taskId,
                initialWardId: task.wardId,
                initialWardName: task.wardName,
                initialRoomOrArea: task.roomOrArea,
              ),
            )),
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Report an Issue for this Task'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
