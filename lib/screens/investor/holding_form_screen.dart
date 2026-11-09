import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_response.dart';
import '../../core/formatters.dart';
import '../../models/holding.dart';
import '../../services/holding_service.dart';
import '../../widgets/common.dart';
import '../../widgets/state_views.dart';

class HoldingFormScreen extends StatefulWidget {
  const HoldingFormScreen({super.key, this.portfolioId, this.holdingId});

  final int? portfolioId;
  final int? holdingId;

  @override
  State<HoldingFormScreen> createState() => _HoldingFormScreenState();
}

class _HoldingFormScreenState extends State<HoldingFormScreen> {
  final TextEditingController _ticker = TextEditingController();
  final TextEditingController _quantity = TextEditingController();
  final TextEditingController _buyPrice = TextEditingController();
  final TextEditingController _buyDate = TextEditingController();
  bool _loading = false;
  bool _saving = false;
  String? _loadError;
  ApiException? _error;

  bool get _isEdit => widget.holdingId != null;

  @override
  void initState() {
    super.initState();
    _buyDate.text = Formatters.apiDate(DateTime.now());

    if (_isEdit) {
      _loading = true;
      _load();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _quantity.dispose();
    _buyPrice.dispose();
    _buyDate.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final Holding holding = await context.read<HoldingService>().detail(widget.holdingId!);
      _ticker.text = holding.ticker;
      _quantity.text = Formatters.quantity(holding.quantity).replaceAll(',', '');
      _buyPrice.text = holding.buyPrice.toString();
      _buyDate.text = holding.buyDate;
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

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = DateTime.tryParse(_buyDate.text) ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(1990),
      lastDate: now,
    );

    if (picked != null && mounted) {
      setState(() => _buyDate.text = Formatters.apiDate(picked));
    }
  }

  Future<void> _save() async {
    final HoldingService service = context.read<HoldingService>();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final SavedHolding saved;

      if (_isEdit) {
        saved = await service.update(
          widget.holdingId!,
          quantity: _quantity.text.trim(),
          buyPrice: _buyPrice.text.trim(),
          buyDate: _buyDate.text.trim(),
        );
      } else {
        saved = await service.create(
          widget.portfolioId!,
          ticker: _ticker.text.trim().toUpperCase(),
          quantity: _quantity.text.trim(),
          buyPrice: _buyPrice.text.trim(),
          buyDate: _buyDate.text.trim(),
        );
      }

      if (mounted) {
        showMessage(context, saved.message);
        context.pop(true);
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
      appBar: buildAppBar(_isEdit ? 'Edit holding' : 'Add holding'),
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
                      controller: _ticker,
                      enabled: !_isEdit,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Ticker',
                        hintText: 'AAPL',
                        helperText: _isEdit ? 'To change the ticker, delete this holding and add a new one.' : null,
                        errorText: _error?.fieldError('ticker'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _quantity,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        errorText: _error?.fieldError('quantity'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _buyPrice,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Buy price',
                        prefixText: '\$ ',
                        errorText: _error?.fieldError('buy_price'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _buyDate,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: InputDecoration(
                        labelText: 'Buy date',
                        suffixIcon: const Icon(Icons.calendar_today),
                        errorText: _error?.fieldError('buy_date'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving...' : (_isEdit ? 'Save changes' : 'Add holding')),
                    ),
                    if (!_isEdit) ...[
                      const SizedBox(height: 12),
                      Text(
                        'If the server has no recent prices for this ticker, it downloads them in the background.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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
