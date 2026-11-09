import 'package:flutter/material.dart';

import '../core/api_response.dart';
import '../models/page_result.dart';
import 'state_views.dart';

class PagedListView<T> extends StatefulWidget {
  const PagedListView({
    super.key,
    required this.fetchPage,
    required this.itemBuilder,
    required this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyAction,
    this.header,
  });

  final Future<PageResult<T>> Function(String? nextUrl) fetchPage;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyMessage;
  final IconData emptyIcon;
  final Widget? emptyAction;
  final Widget? header;

  @override
  State<PagedListView<T>> createState() => PagedListViewState<T>();
}

class PagedListViewState<T> extends State<PagedListView<T>> {
  final List<T> _items = [];
  final ScrollController _scroll = ScrollController();
  String? _next;
  String? _error;
  bool _loading = true;
  bool _loadedOnce = false;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    refresh();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    refresh();
  }

  Future<void> refresh() async {
    _loading = true;

    try {
      final PageResult<T> page = await widget.fetchPage(null);

      if (!mounted) {
        return;
      }

      setState(() {
        _items
          ..clear()
          ..addAll(page.results);
        _next = page.next;
        _count = page.count;
        _error = null;
        _loadedOnce = true;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _error = error.message);

      if (_loadedOnce) {
        showMessage(context, error.message);
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    final String? next = _next;

    if (_loading || next == null) {
      return;
    }

    setState(() => _loading = true);

    try {
      final PageResult<T> page = await widget.fetchPage(next);

      if (mounted) {
        setState(() {
          _items.addAll(page.results);
          _next = page.next;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        showMessage(context, error.message);
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadedOnce) {
      if (_error != null && !_loading) {
        return ErrorView(message: _error!, onRetry: _retry);
      }

      return const LoadingView();
    }

    final Widget? header = widget.header;
    final int headerCount = header == null ? 0 : 1;
    final bool showFooter = _next != null;

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (header != null) header,
            EmptyView(message: widget.emptyMessage, icon: widget.emptyIcon, action: widget.emptyAction),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: headerCount + _items.length + (showFooter ? 1 : 0) + 1,
        itemBuilder: (context, index) {
          if (header != null && index == 0) {
            return header;
          }

          final int itemIndex = index - headerCount;

          if (itemIndex < _items.length) {
            return widget.itemBuilder(context, _items[itemIndex]);
          }

          if (showFooter && itemIndex == _items.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator()
                    : TextButton(onPressed: _loadMore, child: const Text('Load more')),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Showing ${_items.length} of $_count',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        },
      ),
    );
  }
}
