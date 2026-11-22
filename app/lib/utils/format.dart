/// Format tanggal/angka sederhana tanpa paket intl.
class Fmt {
  Fmt._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String date(DateTime d) =>
      '${_two(d.day)} ${_months[d.month - 1]} ${d.year}';

  static String time(DateTime d) => '${_two(d.hour)}.${_two(d.minute)}';

  static String dateTime(DateTime d) => '${date(d)}, ${time(d)}';

  /// "HARI INI", "KEMARIN", atau "06 NOV 2026".
  static String dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'HARI INI';
    if (diff == 1) return 'KEMARIN';
    return date(d).toUpperCase();
  }

  static String percent(double v) => '${(v * 100).round()}%';

  static String coords(double lat, double lng) =>
      '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
}
