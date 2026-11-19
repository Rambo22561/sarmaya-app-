import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _pkrFormat = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _pkrIntFormat = NumberFormat('#,##0', 'en_US');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static String pkr(double amount, {bool showDecimals = false}) {
    if (showDecimals || amount % 1 != 0) {
      return 'Rs. ${_pkrFormat.format(amount)}';
    }
    return 'Rs. ${_pkrIntFormat.format(amount)}';
  }

  static String date(DateTime? dt) {
    if (dt == null) return '-';
    return _dateFormat.format(dt);
  }

  static String dateTime(DateTime? dt) {
    if (dt == null) return '-';
    return _dateTimeFormat.format(dt);
  }

  static String percent(double ratio) {
    return '${(ratio * 100).toStringAsFixed(2)}%';
  }
}
