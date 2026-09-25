import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendly/shared/widgets/glass_card.dart';
import 'package:spendly/shared/widgets/primary_button.dart';

class GlassMonthPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const GlassMonthPicker({
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
        return GlassMonthPicker(
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<GlassMonthPicker> createState() => _GlassMonthPickerState();
}

class _GlassMonthPickerState extends State<GlassMonthPicker> {
  late int _currentYear;
  late int _selectedMonth;
  late int _selectedYear;
  bool _isSelectingYear = false;
  late ScrollController _yearScrollController;

  @override
  void initState() {
    super.initState();
    _currentYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedYear = widget.initialDate.year;
    
    final startYear = widget.firstDate?.year ?? 1900;
    final initialIndex = _currentYear - startYear;
    _yearScrollController = ScrollController(initialScrollOffset: initialIndex * 36.0);
  }

  @override
  void dispose() {
    _yearScrollController.dispose();
    super.dispose();
  }

  void _setYear(int year) {
    setState(() {
      _currentYear = year;
      _selectedYear = year;
      
      // Constrain selected month if the new year hits first/last date limits
      if (widget.lastDate != null && 
          _selectedYear == widget.lastDate!.year && 
          _selectedMonth > widget.lastDate!.month) {
        _selectedMonth = widget.lastDate!.month;
      }
      if (widget.firstDate != null && 
          _selectedYear == widget.firstDate!.year && 
          _selectedMonth < widget.firstDate!.month) {
        _selectedMonth = widget.firstDate!.month;
      }
    });
  }

  void _previousYear() {
    if (widget.firstDate != null && _currentYear <= widget.firstDate!.year) {
      return;
    }
    _setYear(_currentYear - 1);
  }

  void _nextYear() {
    if (widget.lastDate != null && _currentYear >= widget.lastDate!.year) {
      return;
    }
    _setYear(_currentYear + 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Year Switcher
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: _isSelectingYear ? Colors.transparent : theme.colorScheme.onSurface,
                      ),
                      onPressed: _isSelectingYear ? null : _previousYear,
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSelectingYear = !_isSelectingYear;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isSelectingYear ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentYear.toString(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isSelectingYear ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right_rounded,
                        color: _isSelectingYear ? Colors.transparent : theme.colorScheme.onSurface,
                      ),
                      onPressed: _isSelectingYear ? null : _nextYear,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Grid
                SizedBox(
                  height: 220,
                  child: _isSelectingYear
                      ? _buildYearSelector(theme)
                      : _buildMonthSelector(theme, now),
                ),

                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryButton(
                        text: 'Done',
                        onPressed: () {
                          Navigator.pop(
                            context,
                            DateTime(_selectedYear, _selectedMonth),
                          );
                        },
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

  Widget _buildYearSelector(ThemeData theme) {
    final startYear = widget.firstDate?.year ?? 1900;
    final endYear = widget.lastDate?.year ?? 2100;
    final totalYears = endYear - startYear + 1;

    return GridView.builder(
      controller: _yearScrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: totalYears,
      itemBuilder: (context, index) {
        final year = startYear + index;
        final isSelected = _currentYear == year;

        return GestureDetector(
          onTap: () {
            _setYear(year);
            setState(() {
              _isSelectingYear = false;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              year.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthSelector(ThemeData theme, DateTime now) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final isSelected = _selectedYear == _currentYear && _selectedMonth == month;
        final isCurrentMonth = now.year == _currentYear && now.month == month;

        bool isDisabled = false;
        final monthDate = DateTime(_currentYear, month);
        if (widget.firstDate != null &&
            monthDate.isBefore(
              DateTime(
                widget.firstDate!.year,
                widget.firstDate!.month,
              ),
            )) {
          isDisabled = true;
        }
        if (widget.lastDate != null &&
            monthDate.isAfter(
              DateTime(
                widget.lastDate!.year,
                widget.lastDate!.month,
              ),
            )) {
          isDisabled = true;
        }

        return GestureDetector(
          onTap: isDisabled
              ? null
              : () {
                  setState(() {
                    _selectedMonth = month;
                    _selectedYear = _currentYear;
                  });
                },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDisabled
                        ? Colors.transparent
                        : theme.colorScheme.surfaceContainer
                              .withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(12),
              border: isCurrentMonth && !isSelected
                  ? Border.all(
                      color: theme.colorScheme.primary.withValues(
                        alpha: 0.5,
                      ),
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              DateFormat('MMM').format(DateTime(_currentYear, month)),
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : (isDisabled
                          ? theme.colorScheme.onSurface.withValues(
                              alpha: 0.2,
                            )
                          : theme.colorScheme.onSurface),
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }
}
