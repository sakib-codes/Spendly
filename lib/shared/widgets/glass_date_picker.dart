import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendly/shared/widgets/glass_card.dart';
import 'package:spendly/shared/widgets/primary_button.dart';

class GlassDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const GlassDatePicker({
    super.key,
    required this.initialDate,
    this.firstDate,
    this.lastDate,
  });

  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return showGeneralDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return GlassDatePicker(
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<GlassDatePicker> createState() => _GlassDatePickerState();
}

class _GlassDatePickerState extends State<GlassDatePicker> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  int get _daysInMonth {
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  int get _firstWeekdayOffset {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    return firstDay.weekday == 7 ? 0 : firstDay.weekday;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final days = <Widget>[];
    final offset = _firstWeekdayOffset;
    
    for (int i = 0; i < offset; i++) {
      days.add(const SizedBox.shrink());
    }
    
    final totalDays = _daysInMonth;
    final now = DateTime.now();
    
    for (int i = 1; i <= totalDays; i++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, i);
      final isSelected = date.year == _selectedDate.year && 
                         date.month == _selectedDate.month && 
                         date.day == _selectedDate.day;
      final isToday = date.year == now.year && 
                      date.month == now.month && 
                      date.day == now.day;
      
      bool isDisabled = false;
      if (widget.firstDate != null && date.isBefore(widget.firstDate!)) isDisabled = true;
      if (widget.lastDate != null && date.isAfter(widget.lastDate!)) isDisabled = true;

      days.add(
        GestureDetector(
          onTap: isDisabled ? null : () {
            setState(() => _selectedDate = date);
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? theme.colorScheme.primary : (isToday ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              i.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDisabled 
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                    : isSelected
                        ? theme.colorScheme.onPrimary
                        : (isToday ? theme.colorScheme.primary : theme.colorScheme.onSurface),
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    final weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select date',
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    DateFormat('EEE, MMM d').format(_selectedDate),
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(_currentMonth),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _previousMonth,
                          icon: const Icon(Icons.chevron_left_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _nextMonth,
                          icon: const Icon(Icons.chevron_right_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekDays.map((day) => SizedBox(
                    width: 32,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 8),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  children: days,
                ),
                
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: PrimaryButton(
                        text: 'OK',
                        onPressed: () => Navigator.pop(context, _selectedDate),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
