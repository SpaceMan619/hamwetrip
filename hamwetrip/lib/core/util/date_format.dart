import 'package:intl/intl.dart';

/// A trip's date range for display, e.g. "Oct 12 - Oct 18".
///
/// Either end may be unset — a trip can be created before its dates are
/// decided — so this degrades to a single date or a placeholder rather than
/// assuming both are present.
String formatDateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return 'Dates to be decided';
  final format = DateFormat('MMM d');
  if (start != null && end != null) {
    return '${format.format(start)} - ${format.format(end)}';
  }
  return format.format((start ?? end)!);
}
