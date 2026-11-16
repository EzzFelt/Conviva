String familyHomeMessageTimestampLabel(DateTime? timestamp, {DateTime? now}) {
  if (timestamp == null) return '';

  final current = now ?? DateTime.now();
  if (_sameCalendarDay(timestamp, current)) {
    return _formatTime(timestamp);
  }

  return _formatDate(timestamp);
}

String chatMessageTimestampLabel(DateTime timestamp, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final timestampDate = _calendarDate(timestamp);
  final currentDate = _calendarDate(current);
  final dateLabel = timestampDate == currentDate
      ? 'Hoje'
      : timestampDate == currentDate.subtract(const Duration(days: 1))
      ? 'Ontem'
      : _formatDate(timestamp);

  return '$dateLabel, ${_formatTime(timestamp)}';
}

bool _sameCalendarDay(DateTime first, DateTime second) {
  return _calendarDate(first) == _calendarDate(second);
}

DateTime _calendarDate(DateTime value) {
  return DateTime.utc(value.year, value.month, value.day);
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
