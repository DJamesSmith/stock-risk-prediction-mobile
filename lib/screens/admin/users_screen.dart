import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/page_result.dart';
import '../../models/user.dart';
import '../../services/users_service.dart';
import '../../state/session.dart';
import '../../widgets/common.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/state_views.dart';
import 'user_edit_sheet.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final GlobalKey<PagedListViewState<AppUser>> _listKey = GlobalKey<PagedListViewState<AppUser>>();

  Future<PageResult<AppUser>> _fetch(String? nextUrl) {
    return context.read<UsersService>().list(nextUrl: nextUrl);
  }

  Future<void> _edit(AppUser user) async {
    final int? currentUserId = context.read<Session>().user?.id;

    if (user.id == currentUserId) {
      showMessage(context, 'You cannot change your own role.');
      return;
    }

    final AppUser? updated = await showModalBottomSheet<AppUser>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => UserEditSheet(user: user),
    );

    if (updated != null && mounted) {
      showMessage(context, '${updated.username} updated.');
      _listKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Users'),
      body: CenteredContent(
        child: PagedListView<AppUser>(
          key: _listKey,
          fetchPage: _fetch,
          emptyMessage: 'No users found.',
          emptyIcon: Icons.group_off_outlined,
          itemBuilder: (context, user) {
            final List<String> details = [user.email];

            if (user.isInvestor) {
              details.add('Analyst: ${user.assignedAnalyst?.username ?? 'none'}');
            }

            if (!user.isActive) {
              details.add('Inactive');
            }

            return ListTile(
              onTap: () => _edit(user),
              leading: CircleAvatar(child: Icon(_roleIcon(user.role))),
              title: Text(user.username),
              subtitle: Text(details.join(' · ')),
              trailing: Chip(
                label: Text(Formatters.title(user.role)),
                visualDensity: VisualDensity.compact,
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _roleIcon(String role) {
    if (role == AppUser.admin) {
      return Icons.admin_panel_settings_outlined;
    }

    if (role == AppUser.analyst) {
      return Icons.insights_outlined;
    }

    return Icons.person_outline;
  }
}
