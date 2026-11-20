import 'package:flutter/material.dart';

import 'ethiopian_date_formatter.dart';

/// Shows an Ethiopian Calendar (ዓ.ም.) date picker dialog.
///
/// Returns the selected date converted to a standard Gregorian [DateTime],
/// making it a seamless drop-in replacement for Flutter's [showDatePicker].
Future<DateTime?> showEthiopianDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final now = DateTime.now();
  final effectiveInitial = initialDate ?? now;
  final effectiveFirst = firstDate ?? DateTime(2010, 1, 1);
  final effectiveLast = lastDate ?? DateTime(2040, 12, 31);

  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) => _EthiopianDatePickerDialog(
      initialDate: effectiveInitial,
      firstDate: effectiveFirst,
      lastDate: effectiveLast,
    ),
  );
}

enum _PickerMode { day, monthYear }

class _EthiopianDatePickerDialog extends StatefulWidget {
  const _EthiopianDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_EthiopianDatePickerDialog> createState() =>
      _EthiopianDatePickerDialogState();
}

class _EthiopianDatePickerDialogState extends State<_EthiopianDatePickerDialog> {
  static const List<String> _weekdayHeaders = <String>[
    'እ', // እሁድ (Sun)
    'ሰ', // ሰኞ (Mon)
    'ማ', // ማክሰኞ (Tue)
    'ረ', // ረቡዕ (Wed)
    'ሐ', // ሐሙስ (Thu)
    'ዓ', // ዓርብ (Fri)
    'ቅ', // ቅዳሜ (Sat)
  ];

  static const List<String> _weekdayFullNames = <String>[
    '',
    'ሰኞ',
    'ማክሰኞ',
    'ረቡዕ',
    'ሐሙስ',
    'ዓርብ',
    'ቅዳሜ',
    'እሁድ',
  ];

  late int _viewYear;
  late int _viewMonth;
  late EthiopianDate _selectedDate;
  late EthiopianDate _todayEth;
  late EthiopianDate _firstEth;
  late EthiopianDate _lastEth;

  _PickerMode _mode = _PickerMode.day;

  @override
  void initState() {
    super.initState();
    final initialEth = EthiopianCalendar.fromGregorianDateTime(
      widget.initialDate,
    );
    _selectedDate = initialEth;
    _viewYear = initialEth.year;
    _viewMonth = initialEth.month;

    _todayEth = EthiopianCalendar.fromGregorianDateTime(DateTime.now());
    _firstEth = EthiopianCalendar.fromGregorianDateTime(widget.firstDate);
    _lastEth = EthiopianCalendar.fromGregorianDateTime(widget.lastDate);
  }

  void _nextMonth() {
    setState(() {
      if (_viewMonth == 13) {
        if (_viewYear < _lastEth.year) {
          _viewYear += 1;
          _viewMonth = 1;
        }
      } else {
        _viewMonth += 1;
      }
    });
  }

  void _previousMonth() {
    setState(() {
      if (_viewMonth == 1) {
        if (_viewYear > _firstEth.year) {
          _viewYear -= 1;
          _viewMonth = 13;
        }
      } else {
        _viewMonth -= 1;
      }
    });
  }

  bool _isDayEnabled(int day) {
    final eth = EthiopianDate(year: _viewYear, month: _viewMonth, day: day);
    final dt = EthiopianCalendar.toGregorianDate(eth);
    if (dt.isBefore(DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day))) {
      return false;
    }
    if (dt.isAfter(DateTime(widget.lastDate.year, widget.lastDate.month, widget.lastDate.day, 23, 59, 59))) {
      return false;
    }
    return true;
  }

  void _onConfirm() {
    final gregorian = EthiopianCalendar.toGregorianDate(_selectedDate);
    Navigator.of(context).pop(gregorian);
  }

  void _onCancel() {
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final selectedGregorian = EthiopianCalendar.toGregorianDate(_selectedDate);
    final selectedWeekdayName = _weekdayFullNames[selectedGregorian.weekday];
    final selectedMonthName =
        EthiopianCalendar.monthNames[_selectedDate.month - 1];

    final viewMonthName = EthiopianCalendar.monthNames[_viewMonth - 1];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header: Selected Date in Ethiopian Calendar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              color: const Color(0xFFF8FAFC),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ቀን ይምረጡ (ዓ.ም.)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$selectedWeekdayName፣ $selectedMonthName ${_selectedDate.day}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Text(
                        '${_selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _mode = _mode == _PickerMode.day
                                ? _PickerMode.monthYear
                                : _PickerMode.day;
                          });
                        },
                        icon: Icon(
                          _mode == _PickerMode.day
                              ? Icons.edit_calendar_rounded
                              : Icons.calendar_view_month_rounded,
                          size: 20,
                          color: primaryColor,
                        ),
                        tooltip: _mode == _PickerMode.day
                            ? 'ወር እና ዓመት ምረጥ'
                            : 'የቀን ሰሌዳ',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Body: Day Grid or Month/Year Selector
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _mode == _PickerMode.day
                    ? _buildDayGrid(
                        primaryColor: primaryColor,
                        viewMonthName: viewMonthName,
                      )
                    : _buildMonthYearSelector(primaryColor: primaryColor),
              ),
            ),

            // Footer action buttons
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('ይቅር'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('እሺ'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayGrid({
    required Color primaryColor,
    required String viewMonthName,
  }) {
    // 1st day of Ethiopian month converted to Gregorian to calculate weekday
    final firstDayGreg = EthiopianCalendar.toGregorianDateTime(
      year: _viewYear,
      month: _viewMonth,
      day: 1,
    );
    // Sunday is index 0 in our grid
    final startOffset = firstDayGreg.weekday % 7;
    final daysInCurrentMonth = EthiopianCalendar.daysInMonth(
      _viewYear,
      _viewMonth,
    );

    final totalCells = startOffset + daysInCurrentMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      key: ValueKey('day-grid-$_viewYear-$_viewMonth'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Month / Year Navigator Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _mode = _PickerMode.monthYear;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Text(
                      '$viewMonthName $_viewYear ዓ.ም.',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'ያለፈው ወር',
                  iconSize: 22,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'ቀጣዩ ወር',
                  iconSize: 22,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Weekday header row (እ, ሰ, ማ, ረ, ሐ, ዓ, ቅ)
        Row(
          children: _weekdayHeaders.map((header) {
            return Expanded(
              child: Center(
                child: Text(
                  header,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),

        // Calendar Days Grid
        for (var row = 0; row < rowCount; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNumber = cellIndex - startOffset + 1;

                if (dayNumber < 1 || dayNumber > daysInCurrentMonth) {
                  return const Expanded(child: SizedBox(height: 38));
                }

                final isSelected =
                    _selectedDate.year == _viewYear &&
                    _selectedDate.month == _viewMonth &&
                    _selectedDate.day == dayNumber;

                final isToday =
                    _todayEth.year == _viewYear &&
                    _todayEth.month == _viewMonth &&
                    _todayEth.day == dayNumber;

                final enabled = _isDayEnabled(dayNumber);

                return Expanded(
                  child: InkWell(
                    onTap: enabled
                        ? () {
                            setState(() {
                              _selectedDate = EthiopianDate(
                                year: _viewYear,
                                month: _viewMonth,
                                day: dayNumber,
                              );
                            });
                          }
                        : null,
                    borderRadius: BorderRadius.circular(19),
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(color: primaryColor, width: 1.5)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : enabled
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildMonthYearSelector({required Color primaryColor}) {
    return Column(
      key: const ValueKey('month-year-selector'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Year picker header with arrows
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ዓመት ይምረጡ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _viewYear > _firstEth.year
                      ? () => setState(() => _viewYear -= 1)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  iconSize: 22,
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  '$_viewYear ዓ.ም.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  onPressed: _viewYear < _lastEth.year
                      ? () => setState(() => _viewYear += 1)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  iconSize: 22,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Grid of 13 Ethiopian Months
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.3,
          ),
          itemCount: 13,
          itemBuilder: (context, index) {
            final monthIndex = index + 1;
            final monthName = EthiopianCalendar.monthNames[index];
            final isCurrent = _viewMonth == monthIndex;

            return InkWell(
              onTap: () {
                setState(() {
                  _viewMonth = monthIndex;
                  _mode = _PickerMode.day;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: isCurrent
                      ? primaryColor.withValues(alpha: 0.15)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: isCurrent
                      ? Border.all(color: primaryColor, width: 1.5)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  monthName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent ? primaryColor : const Color(0xFF334155),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
