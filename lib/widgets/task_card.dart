import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/task_model.dart';
import 'status_badge.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final bool showEmployeeName;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.showEmployeeName = false,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = task.isOverdue;
    final dueLabel = task.dueAt != null
        ? DateFormat('MMM d, h:mm a').format(task.dueAt!)
        : 'No due time';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${task.taskType.value} — ${task.wardName}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusBadge(status: task.status, overdue: overdue),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                task.roomOrArea.isNotEmpty ? task.roomOrArea : task.title,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
              if (showEmployeeName && task.assignedEmployeeName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Assigned: ${task.assignedEmployeeName}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 14,
                      color: overdue ? AppColors.overdue : AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Due: $dueLabel',
                    style: TextStyle(
                      fontSize: 12,
                      color: overdue ? AppColors.overdue : AppColors.textSecondary,
                      fontWeight: overdue ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  PriorityBadge(priority: task.priority),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
