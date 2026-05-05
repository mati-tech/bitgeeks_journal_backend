import 'package:intl/intl.dart';

final _money = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);
final _compactMoney = NumberFormat.compactCurrency(locale: 'en_US', symbol: '\$');
final _date = DateFormat.yMMMd();
final _dateTime = DateFormat('MMM d, y · HH:mm');
final _time = DateFormat.Hm();

String formatMoney(num? value, {bool compact = false}) {
  if (value == null) return '—';
  return compact ? _compactMoney.format(value) : _money.format(value);
}

String formatSignedMoney(num? value, {bool compact = false}) {
  if (value == null) return '—';
  final s = formatMoney(value.abs(), compact: compact);
  if (value > 0) return '+$s';
  if (value < 0) return '-$s';
  return s;
}

/// Input is the percentage as a number (e.g. 3.33 means 3.33%).
String formatPercent(num? value, {int decimals = 2}) {
  if (value == null) return '—';
  return '${value.toStringAsFixed(decimals)}%';
}

String formatSignedPercent(num? value, {int decimals = 2}) {
  if (value == null) return '—';
  final s = '${value.abs().toStringAsFixed(decimals)}%';
  if (value > 0) return '+$s';
  if (value < 0) return '-$s';
  return s;
}

String formatDate(DateTime? dt) => dt == null ? '—' : _date.format(dt.toLocal());
String formatDateTime(DateTime? dt) => dt == null ? '—' : _dateTime.format(dt.toLocal());
String formatTime(DateTime? dt) => dt == null ? '—' : _time.format(dt.toLocal());

String formatDuration(Duration? d) {
  if (d == null) return '—';
  if (d.inMinutes < 1) return '${d.inSeconds}s';
  if (d.inHours < 1) return '${d.inMinutes}m';
  if (d.inDays < 1) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
  final days = d.inDays;
  final h = d.inHours.remainder(24);
  return h > 0 ? '${days}d ${h}h' : '${days}d';
}

double? parseNumOrNull(String? s) {
  if (s == null || s.trim().isEmpty) return null;
  return double.tryParse(s.trim());
}
