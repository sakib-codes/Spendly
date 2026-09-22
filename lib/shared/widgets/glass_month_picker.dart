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

  @override
  void initState() {
    super.initState();
    _currentYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedYear = widget.initialDate.year;
  }

  void _previousYear() {
    if (widget.firstDate != null && _currentYear <= widget.firstDate!.year) {
      return;
    }
    setState(() {
      _currentYear--;
    });
  }

  void _nextYear() {
    if (widget.lastDate != null && _currentYear >= widget.lastDate!.year) {
      return;
    }
    setState(() {
      _currentYear++;
    });
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
                        color: theme.colorScheme.onSurface,
                      ),
                      onPressed: _previousYear,
                    ),
                    Text(
                      _currentYear.toString(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: 2,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurface,
                      ),
                      onPressed: _nextYear,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Months Grid
                GridView.builder(
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
                    final isSelected =
                        _selectedYear == _currentYear &&
                        _selectedMonth == month;
                    final isCurrentMonth =
                        now.year == _currentYear && now.month == month;

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
                          DateFormat('MMM')
                              .format(DateTime(_currentYear, month)),
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
}
