import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/app/router/route_names.dart';
import 'package:spendly/app/theme/app_colors.dart';
import 'package:spendly/shared/widgets/glass_card.dart';
import 'package:spendly/shared/providers/theme_provider.dart';
import 'package:spendly/shared/providers/transaction_provider.dart';
import 'package:spendly/shared/providers/preferences_provider.dart';
import 'package:spendly/shared/utils/export_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final preferences = ref.watch(preferencesProvider);
    final String themeText = switch (themeMode) {
      ThemeMode.system => 'System Default',
      ThemeMode.light => 'Light Mode',
      ThemeMode.dark => 'Dark Mode',
    };
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildSection(context, 'PREFERENCES', [
              _buildSettingItem(
                context, 
                'Manage Categories', 
                '', 
                onTap: () {
                  context.goNamed(RouteNames.categories);
                }
              ),
              _buildDivider(context),
              _buildSettingItem(
                context, 
                'Currency', 
                preferences.currency, 
                onTap: () {
                  _showCurrencyPicker(context, ref, preferences.currency);
                }
              ),
              _buildDivider(context),
              _buildSettingItem(
                context, 
                'Theme', 
                themeText,
                onTap: () {
                  _showThemePicker(context, ref, themeMode);
                }
              ),
              _buildDivider(context),
              _buildSettingItem(
                context, 
                'First day of month', 
                preferences.firstDayOfMonth, 
                onTap: () {
                  _showFirstDayPicker(context, ref, preferences.firstDayOfMonth);
                }
              ),
            ]),
            const SizedBox(height: 32),
            _buildSection(context, 'DATA & SECURITY', [
              _buildSettingItem(
                context, 
                'Export Data', 
                'CSV / PDF',
                onTap: () async {
                  final transactions = ref.read(transactionProvider).value;
                  if (transactions != null && transactions.isNotEmpty) {
                    await ExportService.exportTransactionsToCSV(transactions);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No transactions to export')),
                    );
                  }
                }
              ),
              _buildDivider(context),
              _buildSettingItem(
                context, 
                'Clear All Data', 
                '', 
                isDestructive: true,
                onTap: () {
                  showDialog(
                    context: context, 
                    builder: (context) => AlertDialog(
                      title: const Text('Clear All Data'),
                      content: const Text('Are you sure you want to delete all transactions? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context), 
                          child: const Text('Cancel')
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(transactionProvider.notifier).clearAll();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('All data cleared successfully')),
                            );
                          }, 
                          child: const Text('Clear', style: TextStyle(color: AppColors.expenseAccent))
                        ),
                      ],
                    )
                  );
                }
              ),
            ]),
            const SizedBox(height: 32),
            _buildSection(context, 'ABOUT', [
              _buildSettingItem(
                context, 
                'About Spendly', 
                '', 
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Spendly',
                    applicationVersion: '1.4.2',
                    applicationIcon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.account_balance_wallet_rounded, color: Theme.of(context).colorScheme.primary, size: 32),
                    ),
                    children: [
                      const Text('Spendly is a modern, privacy-first personal finance tracker built with Flutter.'),
                    ],
                  );
                }
              ),
              _buildDivider(context),
              _buildSettingItem(
                context, 
                'App Version', 
                'v1.4.2', 
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are on the latest version!')));
                }
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Text('Settings', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(BuildContext context, String label, String value, {bool isDestructive = false, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final textColor = isDestructive ? AppColors.expenseAccent : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: theme.textTheme.titleMedium?.copyWith(color: textColor)),
            ),
            if (value.isNotEmpty)
              Text(value, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (value.isNotEmpty)
              const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final theme = Theme.of(context);
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
      indent: 20,
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref, String currentCurrency) {
    final currencies = ['BDT (৳)', 'USD (\$)', 'EUR (€)', 'GBP (£)', 'INR (₹)'];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.map((currency) {
              return RadioListTile<String>(
                title: Text(currency),
                value: currency,
                groupValue: currentCurrency,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(preferencesProvider.notifier).setCurrency(value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showFirstDayPicker(BuildContext context, WidgetRef ref, String currentDay) {
    final days = ['1st of Month', 'Monday', 'Sunday'];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('First Day of Month'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: days.map((day) {
              return RadioListTile<String>(
                title: Text(day),
                value: day,
                groupValue: currentDay,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(preferencesProvider.notifier).setFirstDayOfMonth(value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode currentThemeMode) {
    final themes = {
      ThemeMode.system: 'System Default',
      ThemeMode.light: 'Light Mode',
      ThemeMode.dark: 'Dark Mode',
    };
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: themes.entries.map((entry) {
              return RadioListTile<ThemeMode>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: currentThemeMode,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(themeModeProvider.notifier).setTheme(value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
