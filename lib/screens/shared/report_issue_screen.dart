import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/enums.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/validators/validators.dart';
import '../../models/issue_model.dart';
import '../../models/ward_model.dart';
import '../../repositories/issue_repository.dart';
import '../../repositories/ward_repository.dart';
import '../../services/app_state.dart';
import '../../services/storage_service.dart';
import '../../widgets/state_widgets.dart';

/// PRD §19 (employee) and §28 (supervisor) — same form, same workflow.
/// [relatedTaskId] pre-fills the "related task" link when opened from a
/// task detail screen.
class ReportIssueScreen extends StatefulWidget {
  final String? relatedTaskId;
  final String? initialWardId;
  final String? initialWardName;
  final String? initialRoomOrArea;

  const ReportIssueScreen({
    super.key,
    this.relatedTaskId,
    this.initialWardId,
    this.initialWardName,
    this.initialRoomOrArea,
  });

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _issueRepository = IssueRepository();
  final _wardRepository = WardRepository();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  IssueType _issueType = IssueType.cleaningQuality;
  TaskPriority _priority = TaskPriority.medium;
  String? _selectedWardId;
  List<WardModel> _wards = [];
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _loadingWards = true;
  bool _isSubmitting = false;
  double? _uploadProgress;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedWardId = widget.initialWardId;
    _roomController.text = widget.initialRoomOrArea ?? '';
    _loadWards();
  }

  Future<void> _loadWards() async {
    try {
      final wards = await _wardRepository.getActiveWards();
      if (mounted) {
        setState(() {
          _wards = wards;
          _loadingWards = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingWards = false);
      }
    }
  }

  @override
  void dispose() {
    _roomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pickedImage = image;
          _pickedImageBytes = bytes;
        });
      }
      // If the user cancels, `image` is null — that's a normal, silent no-op.
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open camera.')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pickedImage = image;
          _pickedImageBytes = bytes;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open gallery.')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWardId == null) {
      setState(() => _errorMessage = 'Please select a ward.');
      return;
    }

    final currentUser = context.read<AppState>().currentUser;
    if (currentUser == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final ward = _wards.firstWhere((w) => w.wardId == _selectedWardId);

      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await _storageService.uploadIssueImage(
          issueId: const Uuid().v4(),
          file: _pickedImage!,
          onProgress: (p) => setState(() => _uploadProgress = p),
        );
      }

      await _issueRepository.createIssue(IssueModel(
        issueId: '',
        wardId: ward.wardId,
        wardName: ward.wardName,
        roomOrArea: _roomController.text.trim(),
        issueType: _issueType,
        description: _descriptionController.text.trim(),
        reportedBy: currentUser.uid,
        reportedByName: currentUser.name,
        relatedTaskId: widget.relatedTaskId,
        priority: _priority,
        status: IssueStatus.open,
        imageUrl: imageUrl,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue reported successfully.')),
        );
        Navigator.of(context).pop();
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to report issue: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue')),
      body: _loadingWards
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<IssueType>(
                      initialValue: _issueType,
                      decoration: const InputDecoration(labelText: 'Issue Type'),
                      items: IssueType.values
                          .map((t) => DropdownMenuItem(value: t, child: Text(t.value)))
                          .toList(),
                      onChanged: (v) => setState(() => _issueType = v!),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedWardId,
                      decoration: const InputDecoration(labelText: 'Ward'),
                      items: _wards
                          .map((w) =>
                              DropdownMenuItem(value: w.wardId, child: Text(w.wardName)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedWardId = v),
                      validator: (v) => v == null ? 'Ward is required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _roomController,
                      decoration: const InputDecoration(labelText: 'Room / Area'),
                      validator: (v) =>
                          Validators.required(v, field: 'Room/Area'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Description'),
                      validator: (v) =>
                          Validators.required(v, field: 'Description'),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<TaskPriority>(
                      initialValue: _priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: TaskPriority.values
                          .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                          .toList(),
                      onChanged: (v) => setState(() => _priority = v!),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.pendingBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.privacy_tip_outlined, color: AppColors.pending),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Do not upload images containing patients or patient-identifying information.',
                              style: TextStyle(fontSize: 12, color: AppColors.pending),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_pickedImageBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(_pickedImageBytes!, height: 160, fit: BoxFit.cover),
                      ),
                    if (_uploadProgress != null) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: _uploadProgress),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _pickImage,
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Camera'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _pickFromGallery,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Gallery'),
                          ),
                        ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(_errorMessage!,
                          style: const TextStyle(color: AppColors.overdue)),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit Issue'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
