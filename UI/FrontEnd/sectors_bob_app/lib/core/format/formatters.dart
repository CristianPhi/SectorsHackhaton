import 'package:intl/intl.dart';

/// Number formatting helpers for the Indonesian locale.
///
/// Rupiah uses dot thousands separators and comma decimals (id_ID). Prices are
/// raw doubles, for example 10150 renders as Rp 10.150.
///
/// Number formatting for a named locale like 'id_ID' does not need any locale
/// data loading. NumberFormat ships its symbol data with the intl package, so
/// no initializeDateFormatting or explicit locale load is required here. That
/// call is only needed for date formatting, which this app does not use.
class Formatters {
  const Formatters._();

  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 1,
  );

  static final NumberFormat _decimal = NumberFormat.decimalPattern('id_ID');

  /// Formats a price such as 10150 into 'Rp 10.150'.
  static String rupiah(double value) => _rupiah.format(value);

  /// Formats a large value such as market cap into a compact 'Rp 1,2 T' style.
  static String rupiahCompact(double value) => _compact.format(value);

  /// Formats a percent such as 1.25 into '+1,25%'. Negatives keep their sign.
  static String percent(double value) {
    final String sign = value > 0 ? '+' : '';
    final String body = _decimal.format(value.abs());
    final String signed = value < 0 ? '-$body' : '$sign$body';
    return '$signed%';
  }

  /// Formats an absolute IDR change such as 125 into '+125' or '-125'.
  static String signedRupiah(double value) {
    final String sign = value > 0 ? '+' : (value < 0 ? '-' : '');
    return '$sign${_decimal.format(value.abs())}';
  }
}
