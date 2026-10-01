import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/data/auth_repository.dart';
import '../providers/intern_providers.dart';

/// Admin form that creates an intern's login and profile in one go.
class AddInternScreen extends ConsumerStatefulWidget {
  const AddInternScreen({super.key});

  @override
  ConsumerState<AddInternScreen> createState() => _AddInternScreenState();
}

class _AddInternScreenState extends ConsumerState<AddInternScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _department = TextEditingController();
  final _mentor = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _obscurePassword = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _phone, _department, _mentor]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final intern = await ref
          .read(internRepositoryProvider)
          .createIntern(
            name: _name.text,
            email: _email.text,
            password: _password.text,
            phone: _phone.text,
            department: _department.text,
            mentor: _mentor.text,
            startDate: _startDate!,
            endDate: _endDate!,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${intern.name} added. Share the email and temporary password with them.',
          ),
        ),
      );
      Navigator.of(context).maybePop();
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Add intern')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => Validators.required(v, 'Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Temporary password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: Validators.password,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: Validators.optionalPhone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _department,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                validator: (v) => Validators.required(v, 'Department'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mentor,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Mentor (optional)',
                  prefixIcon: Icon(Icons.supervisor_account_outlined),
                ),
              ),
              const SizedBox(height: 16),
              DateField(
                label: 'Start date',
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialValue: _startDate,
                onChanged: (d) => _startDate = d,
                validator: (v) => v == null ? 'Select a start date' : null,
              ),
              const SizedBox(height: 16),
              DateField(
                label: 'End date',
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialValue: _endDate,
                onChanged: (d) => _endDate = d,
                validator: (v) {
                  if (v == null) return 'Select an end date';
                  if (_startDate != null && v.isBefore(_startDate!)) {
                    return 'End date must be after the start date';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.error),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Create intern',
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
