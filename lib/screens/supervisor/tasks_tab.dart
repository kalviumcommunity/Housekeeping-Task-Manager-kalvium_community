import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/enums.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../models/ward_model.dart';
import '../../repositories/task_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/ward_repository.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/task_card.dart';
import 'create_task_screen.dart';
import 'supervisor_task_detail_screen.dart';

/// PRD §24, §25, §33 — real-time task monitoring with ward/status/type/date
/// filters (server-side Firestore query) plus a client-side text search
/// over ward/room-or-area (Firestore has no native text search).
class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  String? _wardId;
  TaskStatus? _status;
  TaskType? _taskType;
  String? _employeeUid;
  DateTime? _date;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filter = TaskFilter(
      wardId: _wardId,
      status: _status,
      taskType: _taskType,
      employeeUid: _employeeUid,
      date: _date,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const CreateTaskScreen())),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<List<TaskModel>>(
              stream: TaskRepository().watchTasks(filter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator();
                }
                if (snapshot.hasError) {
                  return const ErrorView(message: 'Unable to load tasks.');
                }
                var tasks = snapshot.data ?? [];

                if (_searchQuery.trim().isNotEmpty) {
                  final q = _searchQuery.trim().toLowerCase();
                  tasks = tasks
                      .where((t) =>
                          t.wardName.toLowerCase().contains(q) ||
                          t.roomOrArea.toLowerCase().contains(q))
                      .toList();
                }

                if (tasks.isEmpty) {
                  return const EmptyState(message: 'No records found for this date.');
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                  itemCount: tasks.length,
                  itemBuilder: (context, i) {
                    final task = tasks[i];
                    return TaskCard(
                      task: task,
                      showEmployeeName: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => SupervisorTaskDetailScreen(task: task)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search by ward or room/area',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FutureWardFilterChip(
                  selectedWardId: _wardId,
                  onSelected: (id) => setState(() => _wardId = id),
                ),
                const SizedBox(width: 8),
                _StatusFilterChip(
                  selected: _status,
                  onSelected: (s) => setState(() => _status = s),
                ),
                const SizedBox(width: 8),
                _EmployeeFilterChip(
                  selectedEmployeeUid: _employeeUid,
                  onSelected: (uid) => setState(() => _employeeUid = uid),
                ),
                const SizedBox(width: 8),
                _TaskTypeFilterChip(
                  selected: _taskType,
                  onSelected: (t) => setState(() => _taskType = t),
                ),
                const SizedBox(width: 8),
                _DateFilterChip(
                  selected: _date,
                  onSelected: (d) => setState(() => _date = d),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FutureWardFilterChip extends StatelessWidget {
  final String? selectedWardId;
  final ValueChanged<String?> onSelected;

  const _FutureWardFilterChip({required this.selectedWardId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WardModel>>(
      stream: WardRepository().watchActiveWards(),
      builder: (context, snapshot) {
        final wards = snapshot.data ?? [];
        final label = selectedWardId == null
            ? 'Ward'
            : wards
                .firstWhere((w) => w.wardId == selectedWardId,
                    orElse: () => WardModel(
                        wardId: '', wardName: 'Ward', floor: '', description: '', active: true))
                .wardName;
        return ActionChip(
          avatar: const Icon(Icons.local_hospital_outlined, size: 16),
          label: Text(label),
          onPressed: () async {
            final chosen = await showModalBottomSheet<String?>(
              context: context,
              builder: (ctx) => ListView(
                shrinkWrap: true,
                children: [
                  ListTile(title: const Text('All Wards'), onTap: () => Navigator.pop(ctx, null)),
                  ...wards.map((w) => ListTile(
                        title: Text(w.wardName),
                        onTap: () => Navigator.pop(ctx, w.wardId),
                      )),
                ],
              ),
            );
            onSelected(chosen);
          },
        );
      },
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final TaskStatus? selected;
  final ValueChanged<TaskStatus?> onSelected;
  const _StatusFilterChip({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.flag_outlined, size: 16),
      label: Text(selected?.label ?? 'Status'),
      onPressed: () async {
        final chosen = await showModalBottomSheet<TaskStatus?>(
          context: context,
          builder: (ctx) => ListView(
            shrinkWrap: true,
            children: [
              ListTile(title: const Text('All Statuses'), onTap: () => Navigator.pop(ctx, null)),
              ...TaskStatus.values.map((s) => ListTile(
                    title: Text(s.label),
                    onTap: () => Navigator.pop(ctx, s),
                  )),
            ],
          ),
        );
        onSelected(chosen);
      },
    );
  }
}

class _TaskTypeFilterChip extends StatelessWidget {
  final TaskType? selected;
  final ValueChanged<TaskType?> onSelected;
  const _TaskTypeFilterChip({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.category_outlined, size: 16),
      label: Text(selected?.value ?? 'Type'),
      onPressed: () async {
        final chosen = await showModalBottomSheet<TaskType?>(
          context: context,
          builder: (ctx) => ListView(
            shrinkWrap: true,
            children: [
              ListTile(title: const Text('All Types'), onTap: () => Navigator.pop(ctx, null)),
              ...TaskType.values.map((t) => ListTile(
                    title: Text(t.value),
                    onTap: () => Navigator.pop(ctx, t),
                  )),
            ],
          ),
        );
        onSelected(chosen);
      },
    );
  }
}

class _DateFilterChip extends StatelessWidget {
  final DateTime? selected;
  final ValueChanged<DateTime?> onSelected;
  const _DateFilterChip({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final label = selected == null ? 'Date' : DateFormat('MMM d').format(selected!);
    return ActionChip(
      avatar: const Icon(Icons.calendar_today_outlined, size: 16),
      label: Text(label),
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selected ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        onSelected(picked);
      },
    );
  }
}

class _EmployeeFilterChip extends StatelessWidget {
  final String? selectedEmployeeUid;
  final ValueChanged<String?> onSelected;

  const _EmployeeFilterChip({
    required this.selectedEmployeeUid,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: UserRepository().watchActiveEmployees(),
      builder: (context, snapshot) {
        final employees = snapshot.data ?? [];
        final label = selectedEmployeeUid == null
            ? 'Employee'
            : employees
                .firstWhere(
                  (e) => e.uid == selectedEmployeeUid,
                  orElse: () => UserModel(
                    uid: '',
                    name: 'Employee',
                    email: '',
                    employeeId: '',
                    role: UserRole.employee,
                    assignedWard: '',
                    active: true,
                  ),
                )
                .name;

        return ActionChip(
          avatar: const Icon(Icons.person_outline_rounded, size: 16),
          label: Text(label),
          onPressed: () async {
            final chosen = await showModalBottomSheet<String?>(
              context: context,
              builder: (ctx) => ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('All Employees'),
                    onTap: () => Navigator.pop(ctx, null),
                  ),
                  ...employees.map(
                    (e) => ListTile(
                      title: Text(e.name),
                      subtitle: Text(e.employeeId),
                      onTap: () => Navigator.pop(ctx, e.uid),
                    ),
                  ),
                ],
              ),
            );
            onSelected(chosen);
          },
        );
      },
    );
  }
}
