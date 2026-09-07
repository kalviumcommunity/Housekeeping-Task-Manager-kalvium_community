import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/enums.dart';
import '../../core/errors/app_exception.dart';
import '../../core/validators/validators.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../models/ward_model.dart';
import '../../repositories/task_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/ward_repository.dart';
import '../../services/app_state.dart';
import '../../widgets/state_widgets.dart';

/// PRD §22, §23 — supervisor task creation with employee/ward assignment.
class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _roomController = TextEditingController();
  final _taskRepository = TaskRepository();

  TaskType _taskType = TaskType.cleaning;
  TaskPriority _priority = TaskPriority.medium;
  String? _selectedWardId;
  String? _selectedEmployeeUid;
  DateTime _dueDate = DateTime.now().add(const Duration(hours: 2));

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
    );
    if (time == null) return;
    setState(() {
      _dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit({
    required List<WardModel> wards,
    required List<UserModel> employees,
  }) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWardId == null) {
      setState(() => _errorMessage = 'Please select a ward.');
      return;
    }
    if (_selectedEmployeeUid == null) {
      setState(() => _errorMessage = 'Please assign an employee.');
      return;
    }

    final supervisor = context.read<AppState>().currentUser;
    if (supervisor == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final ward = wards.firstWhere((w) => w.wardId == _selectedWardId);
      final employee = employees.firstWhere((e) => e.uid == _selectedEmployeeUid);

      await _taskRepository.createTask(TaskModel(
        taskId: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        taskType: _taskType,
        wardId: ward.wardId,
        wardName: ward.wardName,
        roomOrArea: _roomController.text.trim(),
        assignedTo: employee.uid,
        assignedEmployeeName: employee.name,
        assignedBy: supervisor.uid,
        priority: _priority,
        status: TaskStatus.pending,
        dueAt: _dueDate,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Task created successfully.')));
        Navigator.of(context).pop();
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Task')),
      body: StreamBuilder<List<UserModel>>(
        stream: UserRepository().watchActiveEmployees(),
        builder: (context, employeeSnap) {
          return FutureBuilder<List<WardModel>>(
            future: WardRepository().getActiveWards(),
            builder: (context, wardSnap) {
              if (!employeeSnap.hasData || !wardSnap.hasData) {
                return const LoadingIndicator();
              }
              final employees = employeeSnap.data!;
              final wards = wardSnap.data!;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (v) => Validators.required(v, field: 'Title'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<TaskType>(
                        initialValue: _taskType,
                        decoration: const InputDecoration(labelText: 'Task Type'),
                        items: TaskType.values
                            .map((t) => DropdownMenuItem(value: t, child: Text(t.value)))
                            .toList(),
                        onChanged: (v) => setState(() => _taskType = v!),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedWardId,
                        decoration: const InputDecoration(labelText: 'Ward'),
                        items: wards
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
                        validator: (v) => Validators.required(v, field: 'Room/Area'),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedEmployeeUid,
                        decoration: const InputDecoration(labelText: 'Assign Employee'),
                        items: employees
                            .map((e) => DropdownMenuItem(value: e.uid, child: Text(e.name)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedEmployeeUid = v),
                        validator: (v) => v == null ? 'Employee is required' : null,
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
                      const SizedBox(height: 14),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Due Date & Time'),
                        subtitle: Text(_dueDate.toString().substring(0, 16)),
                        trailing: const Icon(Icons.edit_calendar_outlined),
                        onTap: _pickDueDate,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submit(wards: wards, employees: employees),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Create Task'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
