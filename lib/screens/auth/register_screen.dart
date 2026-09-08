import 'package:flutter/material.dart';
import '../../core/constants/enums.dart';
import '../../core/errors/app_exception.dart';
import '../../core/validators/validators.dart';
import '../../models/user_model.dart';
import '../../models/ward_model.dart';
import '../../repositories/system_config_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/ward_repository.dart';
import '../../services/auth_service.dart';
import '../../widgets/state_widgets.dart';

/// User account creation with role-specific Organization Access Code
/// to prevent unauthorized / fake employee and supervisor registrations.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _accessCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _userRepository = UserRepository();
  final _wardRepository = WardRepository();
  final _configRepository = SystemConfigRepository();

  UserRole _selectedRole = UserRole.employee;
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
    _accessCodeController.dispose();
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

    final enteredCode = _accessCodeController.text.trim();
    if (enteredCode.isEmpty) {
      setState(() => _errorMessage = 'Please enter your ${_selectedRole.label} Access Code.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Validate access code against Firestore system_config
      final isValidCode = await _configRepository.validateAccessCode(
        role: _selectedRole,
        enteredCode: enteredCode,
      );

      if (!isValidCode) {
        setState(() {
          _errorMessage =
              'Invalid ${_selectedRole.label} Access Code. Please contact your hospital administration.';
          _isSubmitting = false;
        });
        return;
      }

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
        role: _selectedRole,
        assignedWard: ward.wardId,
        active: true,
        accessCode: enteredCode.toUpperCase(),
      ));

      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Account creation failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSupervisor = _selectedRole == UserRole.supervisor;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
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
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => Validators.required(v, field: 'Name'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _employeeIdController,
                      decoration: const InputDecoration(
                        labelText: 'Employee ID / Staff Number',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) =>
                          Validators.required(v, field: 'Employee ID'),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<UserRole>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        prefixIcon: Icon(Icons.security_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: UserRole.employee,
                          child: Text('Employee'),
                        ),
                        DropdownMenuItem(
                          value: UserRole.supervisor,
                          child: Text('Supervisor'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedRole = v ?? UserRole.employee),
                    ),
                    const SizedBox(height: 14),
                    // Organization Access Code Input
                    TextFormField(
                      controller: _accessCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: isSupervisor
                            ? 'Supervisor Access Code'
                            : 'Employee Access Code',
                        hintText: isSupervisor
                            ? 'Enter official Supervisor Code (e.g. SUP-2026)'
                            : 'Enter official Employee Code (e.g. EMP-2026)',
                        helperText:
                            'Required common organization code to verify authentic staff',
                        prefixIcon: Icon(
                          isSupervisor
                              ? Icons.admin_panel_settings_outlined
                              : Icons.verified_user_outlined,
                          color: isSupervisor ? Colors.orange : Colors.blue,
                        ),
                      ),
                      validator: (v) => Validators.required(
                        v,
                        field: isSupervisor
                            ? 'Supervisor Access Code'
                            : 'Employee Access Code',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedWardId,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Ward',
                        prefixIcon: Icon(Icons.local_hospital_outlined),
                      ),
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
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) => Validators.matchPassword(
                          v, _passwordController.text),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade400),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
