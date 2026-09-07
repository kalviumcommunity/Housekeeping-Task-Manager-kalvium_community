import 'package:flutter/material.dart';
import '../../core/constants/enums.dart';
import '../../core/errors/app_exception.dart';
import '../../core/validators/validators.dart';
import '../../models/user_model.dart';
import '../../models/ward_model.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/ward_repository.dart';
import '../../services/auth_service.dart';
import '../../widgets/state_widgets.dart';

/// PRD §7 — employee self-registration only. Role is always forced to
/// `employee`; there is no UI path to register as supervisor.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _userRepository = UserRepository();
  final _wardRepository = WardRepository();

  String? _selectedWardId;
  List<WardModel> _wards = [];
  bool _loadingWards = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  static final List<WardModel> _defaultWards = [
    WardModel(wardId: 'ward_01', wardName: 'Ward 1 (General)', floor: '1st Floor', description: 'General Ward', active: true),
    WardModel(wardId: 'ward_02', wardName: 'Ward 2 (Surgical)', floor: '2nd Floor', description: 'Surgical Ward', active: true),
    WardModel(wardId: 'ward_03', wardName: 'Ward 3 (ICU)', floor: '3rd Floor', description: 'ICU', active: true),
  ];

  @override
  void initState() {
    super.initState();
    _loadWards();
  }

  Future<void> _loadWards() async {
    try {
      final wards = await _wardRepository.getActiveWards();
      if (mounted) {
        setState(() {
          _wards = wards.isNotEmpty ? wards : _defaultWards;
          _loadingWards = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _wards = _defaultWards;
          _loadingWards = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employeeIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWardId == null) {
      setState(() => _errorMessage = 'Please select your assigned ward.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final authUser = await _authService.registerEmployee(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final ward = _wards.firstWhere((w) => w.wardId == _selectedWardId);

      await _userRepository.createEmployeeProfile(UserModel(
        uid: authUser.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        employeeId: _employeeIdController.text.trim(),
        role: UserRole.employee,
        assignedWard: ward.wardId,
        active: true,
      ));

      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Employee Account')),
      body: _loadingWards
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) => Validators.required(v, field: 'Name'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _employeeIdController,
                      decoration: const InputDecoration(labelText: 'Employee ID'),
                      validator: (v) =>
                          Validators.required(v, field: 'Employee ID'),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedWardId,
                      decoration: const InputDecoration(labelText: 'Assigned Ward'),
                      items: _wards
                          .map((w) => DropdownMenuItem(
                                value: w.wardId,
                                child: Text(w.wardName),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedWardId = v),
                      validator: (v) => v == null ? 'Please select a ward' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Confirm Password'),
                      validator: (v) => Validators.matchPassword(
                          v, _passwordController.text),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red)),
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
                          : const Text('Create Account'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
