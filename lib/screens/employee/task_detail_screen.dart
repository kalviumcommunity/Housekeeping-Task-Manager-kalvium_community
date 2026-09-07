import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/enums.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/task_model.dart';
import '../../repositories/task_repository.dart';
import '../../services/app_state.dart';
import '../../services/storage_service.dart';
import '../../widgets/status_badge.dart';
import '../shared/report_issue_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _taskRepository = TaskRepository();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  late TaskModel _task;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Future<void> _startTask() async {
    final uid = context.read<AppState>().currentUser?.uid;
    if (uid == null) return;

    setState(() => _isProcessing = true);
    try {
      await _taskRepository.startTask(taskId: _task.taskId, currentUid: uid);
      setState(() {
        _task = TaskModel(
          taskId: _task.taskId,
          title: _task.title,
          description: _task.description,
          taskType: _task.taskType,
          wardId: _task.wardId,
          wardName: _task.wardName,
          roomOrArea: _task.roomOrArea,
          assignedTo: _task.assignedTo,
          assignedEmployeeName: _task.assignedEmployeeName,
          assignedBy: _task.assignedBy,
          priority: _task.priority,
          status: TaskStatus.inProgress,
          createdAt: _task.createdAt,
          dueAt: _task.dueAt,
          startedAt: DateTime.now(),
          completedAt: _task.completedAt,
          completionNote: _task.completionNote,
          imageUrl: _task.imageUrl,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Task started.')));
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showCompleteDialog() async {
    final noteController = TextEditingController();
    XFile? pickedImage;
    Uint8List? pickedImageBytes;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Complete Task',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Are you sure you want to mark this task as completed?',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Completion note (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (pickedImageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(pickedImageBytes!, height: 140, fit: BoxFit.cover),
                    ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.pendingBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.privacy_tip_outlined, color: AppColors.pending, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Do not upload images containing patients or patient-identifying information.',
                            style: TextStyle(fontSize: 11, color: AppColors.pending),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final image = await _picker.pickImage(
                          source: ImageSource.camera, imageQuality: 80, maxWidth: 1600);
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setSheetState(() {
                          pickedImage = image;
                          pickedImageBytes = bytes;
                        });
                      }
                    },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Add evidence photo (optional)'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            await _completeTask(
                              note: noteController.text,
                              image: pickedImage,
                            );
                          },
                    child: const Text('Confirm & Complete'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completeTask({required String note, XFile? image}) async {
    final uid = context.read<AppState>().currentUser?.uid;
    if (uid == null) return;

    setState(() => _isProcessing = true);
    try {
      String? imageUrl;
      if (image != null) {
        try {
          imageUrl = await _storageService.uploadTaskImage(
            taskId: _task.taskId,
            file: image,
          );
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Photo failed to upload — completing task without it.')),
            );
          }
        }
      }

      await _taskRepository.completeTask(
        taskId: _task.taskId,
        currentUid: uid,
        completionNote: note,
        imageUrl: imageUrl,
      );

      setState(() {
        _task = TaskModel(
          taskId: _task.taskId,
          title: _task.title,
          description: _task.description,
          taskType: _task.taskType,
          wardId: _task.wardId,
          wardName: _task.wardName,
          roomOrArea: _task.roomOrArea,
          assignedTo: _task.assignedTo,
          assignedEmployeeName: _task.assignedEmployeeName,
          assignedBy: _task.assignedBy,
          priority: _task.priority,
          status: TaskStatus.completed,
          createdAt: _task.createdAt,
          dueAt: _task.dueAt,
          startedAt: _task.startedAt,
          completedAt: DateTime.now(),
          completionNote: note.trim().isEmpty ? _task.completionNote : note.trim(),
          imageUrl: imageUrl ?? _task.imageUrl,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Task marked as completed.')));
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
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
          _DetailRow(label: 'Due', value: task.dueAt != null ? dateFormat.format(task.dueAt!) : '—'),
          if (task.startedAt != null)
            _DetailRow(label: 'Started', value: dateFormat.format(task.startedAt!)),
          if (task.completedAt != null)
            _DetailRow(label: 'Completed', value: dateFormat.format(task.completedAt!)),
          if (task.completionNote != null && task.completionNote!.isNotEmpty)
            _DetailRow(label: 'Note', value: task.completionNote!),
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
          const SizedBox(height: 28),
          if (task.status == TaskStatus.pending)
            ElevatedButton(
              onPressed: _isProcessing ? null : _startTask,
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('START TASK'),
            ),
          if (task.status == TaskStatus.inProgress)
            ElevatedButton(
              onPressed: _isProcessing ? null : _showCompleteDialog,
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('COMPLETE TASK'),
            ),
          const SizedBox(height: 12),
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
            width: 100,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
