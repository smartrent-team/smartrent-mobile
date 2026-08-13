/// Xử lý ngày theo lịch Việt Nam — tránh lệch 1 ngày do múi giờ thiết bị.
class VnDate {
  static const Duration _vnOffset = Duration(hours: 7);

  /// Parse từ `YYYY-MM-DD` hoặc ISO timestamp → ngày lịch VN (00:00 local).
  static DateTime? parse(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    final dateOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final match = dateOnly.firstMatch(raw);
    if (match != null) {
      return DateTime(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;

    final vn = parsed.toUtc().add(_vnOffset);
    return DateTime(vn.year, vn.month, vn.day);
  }

  static String format(DateTime? date) {
    if (date == null) return '—';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  /// Gửi lên API dạng `YYYY-MM-DD` — tránh lệch múi giờ.
  static String toCalendarKey(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
