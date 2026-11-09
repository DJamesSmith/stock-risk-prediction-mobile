import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../core/api_response.dart';
import '../../core/formatters.dart';
import '../../models/user.dart';
import '../../state/session.dart';
import '../../widgets/common.dart';
import '../../widgets/state_views.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _email = TextEditingController();
  bool _saving = false;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    final AppUser? user = context.read<Session>().user;
    _username.text = user?.username ?? '';
    _email.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final Session session = context.read<Session>();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final AppUser updated = await session.auth.updateProfile(
        username: _username.text.trim(),
        email: _email.text.trim(),
      );
      session.updateUser(updated);

      if (mounted) {
        showMessage(context, 'Profile updated.');
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }

    if (mounted) {
      setState(() => _saving = false);
    }
  }

  Future<void> _reload() async {
    try {
      final Session session = context.read<Session>();
      await session.reloadUser();
      final AppUser? user = session.user;
      _username.text = user?.username ?? '';
      _email.text = user?.email ?? '';
    } on ApiException catch (error) {
      if (mounted) {
        showMessage(context, error.message);
      }
    }
  }

  Future<void> _logout() async {
    final bool confirmed = await confirmAction(
      context,
      title: 'Log out?',
      message: 'You will stop receiving live updates on this device.',
      confirmLabel: 'Log out',
    );

    if (confirmed && mounted) {
      await context.read<Session>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.select<Session, AppUser?>((session) => session.user);

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: buildAppBar('Profile'),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            CenteredContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          InfoRow(label: 'Role', value: Chip(label: Text(Formatters.title(user.role)))),
                          if (user.isInvestor)
                            InfoRow(
                              label: 'Assigned analyst',
                              value: Text(user.assignedAnalyst?.username ?? 'None'),
                            ),
                          InfoRow(label: 'Member since', value: Text(Formatters.date(user.dateJoined))),
                          InfoRow(label: 'Server', value: Text(ApiConfig.baseUrl)),
                        ],
                      ),
                    ),
                  ),
                  const SectionTitle('Edit profile'),
                  if (_error != null && _error!.fieldErrors.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  TextField(
                    controller: _username,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      errorText: _error?.fieldError('username'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: _error?.fieldError('email'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving...' : 'Save changes'),
                  ),
                  const SectionTitle('Security'),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/change-password'),
                    icon: const Icon(Icons.password),
                    label: const Text('Change password'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Log out'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
