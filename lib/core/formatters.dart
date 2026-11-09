import 'package:intl/intl.dart';

class Formatters {
  static const String minus = '−';

  static final NumberFormat _money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final NumberFormat _number = NumberFormat('#,##0.####');
  static final DateFormat _date = DateFormat('d MMM yyyy');
  static final DateFormat _dateTime = DateFormat('d MMM yyyy, HH:mm');
  static final DateFormat _time = DateFormat('HH:mm:ss');
  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  static String money(double? value) {
    if (value == null) {
      return '-';
    }

    if (value < 0) {
      return '$minus${_money.format(value.abs())}';
    }

    return _money.format(value);
  }

  static String signedMoney(double? value) {
    if (value == null) {
      return '-';
    }

    if (value > 0) {
      return '+${_money.format(value)}';
    }

    if (value < 0) {
      return '$minus${_money.format(value.abs())}';
    }

    return _money.format(0);
  }

  static String signedPercent(double? value) {
    if (value == null) {
      return '-';
    }

    final String text = '${value.abs().toStringAsFixed(2)}%';

    if (value > 0) {
      return '+$text';
    }

    if (value < 0) {
      return '$minus$text';
    }

    return text;
  }

  static String ratioPercent(double? value) {
    if (value == null) {
      return '-';
    }

    return '${(value * 100).toStringAsFixed(1)}%';
  }

  static String quantity(double? value) {
    if (value == null) {
      return '-';
    }

    return _number.format(value);
  }

  static String date(String? value) {
    final DateTime? parsed = DateTime.tryParse(value ?? '');

    if (parsed == null) {
      return '-';
    }

    return _date.format(parsed);
  }

  static String dateTime(String? value) {
    final DateTime? parsed = DateTime.tryParse(value ?? '');

    if (parsed == null) {
      return '-';
    }

    return _dateTime.format(parsed.toLocal());
  }

  static String time(DateTime value) {
    return _time.format(value.toLocal());
  }

  static String apiDate(DateTime value) {
    return _apiDate.format(value);
  }

  static String title(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    return value[0].toUpperCase() + value.substring(1);
  }
}
