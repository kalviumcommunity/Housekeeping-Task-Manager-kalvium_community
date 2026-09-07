import 'package:flutter/material.dart';
import '../core/constants/enums.dart';
import '../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final TaskStatus status;
  final bool overdue;

  const StatusBadge({super.key, required this.status, this.overdue = false});

  @override
  Widget build(BuildContext context) {
    final label = overdue && status != TaskStatus.completed
        ? 'OVERDUE'
        : status.label.toUpperCase();
    final fg = AppColors.statusColor(status, overdueFlag: overdue);
    final bg = AppColors.statusBgColor(status, overdueFlag: overdue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.priorityColor(priority);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag_rounded, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          priority.label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class IssueStatusBadge extends StatelessWidget {
  final IssueStatus status;

  const IssueStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isOpen = status == IssueStatus.open;
    final fg = isOpen ? AppColors.overdue : AppColors.completed;
    final bg = isOpen ? AppColors.overdueBg : AppColors.completedBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
