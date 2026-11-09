import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_response.dart';
import '../../core/formatters.dart';
import '../../models/user.dart';
import '../../services/users_service.dart';

class UserEditSheet extends StatefulWidget {
  const UserEditSheet({super.key, required this.user});

  final AppUser user;

  @override
  State<UserEditSheet> createState() => _UserEditSheetState();
}

class _UserEditSheetState extends State<UserEditSheet> {
  late String _role = widget.user.role;
  late int? _analystId = widget.user.assignedAnalyst?.id;
  List<AppUser> _analysts = [];
  bool _loadingAnalysts = true;
  bool _saving = false;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalysts();
  }

  Future<void> _loadAnalysts() async {
    try {
      final List<AppUser> analysts = await context.read<UsersService>().activeAnalysts();

      if (mounted) {
        setState(() => _analysts = analysts.where((analyst) => analyst.id != widget.user.id).toList());
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }

    if (mounted) {
      setState(() => _loadingAnalysts = false);
    }
  }

  Future<void> _save() async {
    final UsersService service = context.read<UsersService>();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final AppUser updated = await service.update(
        widget.user.id,
        role: _role,
        assignedAnalystId: _role == AppUser.investor ? _analystId : null,
      );

      if (mounted) {
        Navigator.of(context).pop(updated);
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
    final TextTheme text = Theme.of(context).textTheme;
    final bool analystKnown = _analystId == null || _analysts.any((analyst) => analyst.id == _analystId);
    final bool demotingAnalyst = widget.user.isAnalyst && _role != AppUser.analyst;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit ${widget.user.username}', style: text.titleLarge),
          Text(widget.user.email, style: text.bodySmall),
          const SizedBox(height: 16),
          if (_error != null && _error!.fieldErrors.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: InputDecoration(labelText: 'Role', errorText: _error?.fieldError('role')),
            items: [
              for (final String role in AppUser.roles)
                DropdownMenuItem(value: role, child: Text(Formatters.title(role))),
            ],
            onChanged: _saving ? null : (value) => setState(() => _role = value ?? _role),
          ),
          if (demotingAnalyst)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'All investors assigned to this analyst will be unassigned.',
                style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          if (_role == AppUser.investor)
            _loadingAnalysts
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<int?>(
                    initialValue: analystKnown ? _analystId : null,
                    decoration: InputDecoration(
                      labelText: 'Assigned analyst',
                      errorText: _error?.fieldError('assigned_analyst'),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('No analyst')),
                      for (final AppUser analyst in _analysts)
                        DropdownMenuItem<int?>(value: analyst.id, child: Text(analyst.username)),
                    ],
                    onChanged: _saving ? null : (value) => setState(() => _analystId = value),
                  )
          else
            Text('Only investors can have an assigned analyst.', style: text.bodySmall),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
    );
  }
}
