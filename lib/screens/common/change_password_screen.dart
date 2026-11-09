import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_response.dart';
import '../../state/session.dart';
import '../../widgets/common.dart';
import '../../widgets/state_views.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _oldPassword = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirmation = TextEditingController();
  bool _saving = false;
  ApiException? _error;

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final String message = await context.read<Session>().changePassword(
            oldPassword: _oldPassword.text,
            newPassword: _newPassword.text,
            newPasswordConfirmation: _confirmation.text,
          );

      if (mounted) {
        showMessage(context, message);
        context.pop();
      }
      return;
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }

    if (mounted) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Change password'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CenteredContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('After the change, tokens on your other devices stop working. This device gets a new token pair.'),
                const SizedBox(height: 16),
                if (_error != null && _error!.fieldErrors.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                TextField(
                  controller: _oldPassword,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    errorText: _error?.fieldError('old_password'),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPassword,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    errorText: _error?.fieldError('new_password'),
                    errorMaxLines: 4,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmation,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm new password',
                    errorText: _error?.fieldError('new_password_confirmation'),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: Text(_saving ? 'Saving...' : 'Change password'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
