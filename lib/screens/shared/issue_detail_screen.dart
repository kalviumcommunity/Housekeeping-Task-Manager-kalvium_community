import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/enums.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/issue_model.dart';
import '../../repositories/issue_repository.dart';
import '../../widgets/status_badge.dart';

class IssueDetailScreen extends StatefulWidget {
  final IssueModel issue;
  final bool canResolve;

  const IssueDetailScreen({super.key, required this.issue, this.canResolve = false});

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  final _issueRepository = IssueRepository();
  bool _isResolving = false;

  Future<void> _resolve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Issue'),
        content: const Text('Mark this issue as resolved?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Resolve')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isResolving = true);
    try {
      await _issueRepository.resolveIssue(widget.issue.issueId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Issue marked as resolved.')));
        Navigator.of(context).pop();
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    final dateFormat = DateFormat('MMM d, yyyy · h:mm a');

    return Scaffold(
      appBar: AppBar(title: Text(issue.issueType.value)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${issue.wardName} — ${issue.roomOrArea}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IssueStatusBadge(status: issue.status),
            ],
          ),
          const SizedBox(height: 4),
          PriorityBadge(priority: issue.priority),
          const SizedBox(height: 20),
          if (issue.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: issue.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => const SizedBox(
                    height: 200, child: Center(child: CircularProgressIndicator())),
                errorWidget: (_, __, ___) => const SizedBox(
                    height: 200, child: Center(child: Icon(Icons.broken_image_outlined))),
              ),
            ),
            const SizedBox(height: 20),
          ],
          const Text('Description',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(issue.description, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 20),
          _DetailRow(label: 'Reported By', value: issue.reportedByName),
          _DetailRow(
              label: 'Reported On',
              value: issue.createdAt != null ? dateFormat.format(issue.createdAt!) : '—'),
          if (issue.relatedTaskId != null)
            _DetailRow(label: 'Related Task', value: issue.relatedTaskId!),
          if (issue.status == IssueStatus.resolved && issue.resolvedAt != null)
            _DetailRow(label: 'Resolved On', value: dateFormat.format(issue.resolvedAt!)),
          const SizedBox(height: 24),
          if (widget.canResolve && issue.status == IssueStatus.open)
            ElevatedButton.icon(
              onPressed: _isResolving ? null : _resolve,
              icon: _isResolving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Mark Resolved'),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
