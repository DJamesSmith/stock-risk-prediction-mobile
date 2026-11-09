import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/page_result.dart';
import '../../models/portfolio.dart';
import '../../models/user.dart';
import '../../services/portfolio_service.dart';
import '../../state/session.dart';
import '../../widgets/common.dart';
import '../../widgets/paged_list_view.dart';

class PortfolioListScreen extends StatefulWidget {
  const PortfolioListScreen({super.key, required this.title, this.canCreate = false});

  final String title;
  final bool canCreate;

  @override
  State<PortfolioListScreen> createState() => _PortfolioListScreenState();
}

class _PortfolioListScreenState extends State<PortfolioListScreen> {
  final GlobalKey<PagedListViewState<Portfolio>> _listKey = GlobalKey<PagedListViewState<Portfolio>>();

  Future<PageResult<Portfolio>> _fetch(String? nextUrl) {
    return context.read<PortfolioService>().list(nextUrl: nextUrl);
  }

  Future<void> _open(String path) async {
    final Object? result = await context.push<Object?>(path);
    _listKey.currentState?.refresh();

    if (result is int && mounted) {
      await _open('/portfolios/$result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.select<Session, AppUser?>((session) => session.user);
    final bool showOwner = user != null && !user.isInvestor;

    return Scaffold(
      appBar: buildAppBar(widget.title),
      floatingActionButton: widget.canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _open('/portfolios/new'),
              icon: const Icon(Icons.add),
              label: const Text('New portfolio'),
            )
          : null,
      body: CenteredContent(
        child: PagedListView<Portfolio>(
          key: _listKey,
          fetchPage: _fetch,
          emptyMessage: widget.canCreate
              ? 'You have no portfolios yet. Create one to start tracking holdings.'
              : 'No portfolios to show.',
          emptyIcon: Icons.folder_open,
          itemBuilder: (context, portfolio) {
            return _PortfolioTile(
              portfolio: portfolio,
              showOwner: showOwner,
              onTap: () => _open('/portfolios/${portfolio.id}'),
            );
          },
        ),
      ),
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  const _PortfolioTile({required this.portfolio, required this.showOwner, required this.onTap});

  final Portfolio portfolio;
  final bool showOwner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final List<String> details = [];

    if (showOwner && portfolio.owner != null) {
      details.add(portfolio.owner!.username);
    }

    details.add('${portfolio.holdingsCount} holdings');

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(child: Text(portfolio.name.isEmpty ? '?' : portfolio.name[0].toUpperCase())),
      title: Text(portfolio.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(details.join(' · ')),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Formatters.money(portfolio.totalValue),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text('Daily close', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
