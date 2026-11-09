import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_response.dart';
import '../../models/portfolio.dart';
import '../../services/portfolio_service.dart';
import '../../widgets/common.dart';
import '../../widgets/state_views.dart';

class PortfolioFormScreen extends StatefulWidget {
  const PortfolioFormScreen({super.key, this.portfolioId});

  final int? portfolioId;

  @override
  State<PortfolioFormScreen> createState() => _PortfolioFormScreenState();
}

class _PortfolioFormScreenState extends State<PortfolioFormScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  bool _loading = false;
  bool _saving = false;
  String? _loadError;
  ApiException? _error;

  bool get _isEdit => widget.portfolioId != null;

  @override
  void initState() {
    super.initState();

    if (_isEdit) {
      _loading = true;
      _load();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final Portfolio portfolio = await context.read<PortfolioService>().detail(widget.portfolioId!);
      _name.text = portfolio.name;
      _description.text = portfolio.description;
      _loadError = null;
    } on ApiException catch (error) {
      _loadError = error.message;
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _load();
  }

  Future<void> _save() async {
    final PortfolioService service = context.read<PortfolioService>();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (_isEdit) {
        await service.update(widget.portfolioId!, name: _name.text.trim(), description: _description.text.trim());

        if (mounted) {
          showMessage(context, 'Portfolio updated.');
          context.pop(true);
        }
      } else {
        final Portfolio portfolio = await service.create(
          name: _name.text.trim(),
          description: _description.text.trim(),
        );

        if (mounted) {
          showMessage(context, 'Portfolio created.');
          context.pop(portfolio.id);
        }
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
      appBar: buildAppBar(_isEdit ? 'Edit portfolio' : 'New portfolio'),
      body: StateSwitcher(
        loading: _loading,
        error: _loadError,
        hasData: !_loading && _loadError == null,
        onRetry: _retry,
        builder: (context) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CenteredContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null && _error!.fieldErrors.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_error!.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),
                    TextField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        hintText: 'Long term growth',
                        errorText: _error?.fieldError('name'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _description,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        alignLabelWithHint: true,
                        errorText: _error?.fieldError('description'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving...' : (_isEdit ? 'Save changes' : 'Create portfolio')),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
