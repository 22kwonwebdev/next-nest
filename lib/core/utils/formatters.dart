import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _numberFormat = NumberFormat('#,##0.##');
  static final DateFormat _displayDateFormat = DateFormat('dd MMM yyyy');

  static String currency(double amount) => _numberFormat.format(amount);

  static String date(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    return _displayDateFormat.format(date);
  }

  static const List<String> _ones = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];
  static const List<String> _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  static String amountInWords(double amount) {
    final value = amount.round();
    if (value == 0) return 'Zero';
    return _convert(value);
  }

  static String _convert(int n) {
    if (n == 0) return '';
    final parts = <String>[];
    var rest = n;
    final crore = rest ~/ 10000000;
    rest %= 10000000;
    final lakh = rest ~/ 100000;
    rest %= 100000;
    final thousand = rest ~/ 1000;
    rest %= 1000;
    if (crore > 0) parts.add('${_convert(crore)} Crore');
    if (lakh > 0) parts.add('${_threeDigits(lakh)} Lakh');
    if (thousand > 0) parts.add('${_threeDigits(thousand)} Thousand');
    if (rest > 0) parts.add(_threeDigits(rest));
    return parts.join(' ');
  }

  static String _threeDigits(int n) {
    final hundreds = n ~/ 100;
    final rest = n % 100;
    final parts = <String>[];
    if (hundreds > 0) parts.add('${_ones[hundreds]} Hundred');
    if (rest > 0) parts.add(_twoDigits(rest));
    return parts.join(' ');
  }

  static String _twoDigits(int n) {
    if (n < 20) return _ones[n];
    final ten = _tens[n ~/ 10];
    final one = n % 10;
    return one > 0 ? '$ten ${_ones[one]}' : ten;
  }
}
