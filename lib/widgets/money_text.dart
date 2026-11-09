import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../core/formatters.dart';

class MoneyText extends StatelessWidget {
  const MoneyText(this.value, {super.key, this.signed = false, this.percent, this.style});

  final double? value;
  final bool signed;
  final double? percent;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = style ?? DefaultTextStyle.of(context).style;

    if (!signed) {
      return Text(Formatters.money(value), style: base);
    }

    String text = Formatters.signedMoney(value);

    if (percent != null) {
      text = '$text (${Formatters.signedPercent(percent)})';
    }

    return Text(text, style: base.copyWith(color: AppColors.gainColor(value)));
  }
}
