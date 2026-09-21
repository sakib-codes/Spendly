import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/app/router/route_names.dart';
import 'package:spendly/app/theme/app_colors.dart';
import 'package:spendly/shared/widgets/glass_card.dart';
import 'package:spendly/shared/providers/theme_provider.dart';
import 'package:spendly/shared/providers/transaction_provider.dart';
import 'package:spendly/shared/providers/preferences_provider.dart';
import 'package:spendly/shared/utils/export_service.dart';
import 'package:spendly/features/auth/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendly/shared/widgets/glass_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
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
            _buildSection(context, 'ACCOUNT', [
              _buildSettingItem(
                context, 
                'Edit Profile Name', 
                '',
                onTap: () {
                  _showEditNameDialog(context, ref);
                },
              ),
              _buildDivider(context),
              _buildSettingItem(
                context, 
                'Change Password', 
                '',
                onTap: () {
                  _showChangePasswordDialog(context, ref);
                },
              ),
              _buildDivider(context),
              _buildSettingItem(
                context, 
                'Log Out', 
                '', 
                isDestructive: true,
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                  context.go(RoutePaths.login);
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
                  String confirmationText = '';
                  GlassDialog.show(
                    context: context,
                    title: 'Clear All Data',
                    icon: Icon(Icons.warning_amber_rounded, color: AppColors.expenseAccent, size: 48),
                    content: StatefulBuilder(
                      builder: (context, setState) {
                        final theme = Theme.of(context);
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Are you sure you want to delete all transactions? This action cannot be undone.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Type "DELETE" to confirm:',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            GlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: TextField(
                                onChanged: (val) {
                                  setState(() {
                                    confirmationText = val;
                                  });
                                },
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'DELETE',
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      StatefulBuilder(
                        builder: (context, setState) {
                          return TextButton(
                            onPressed: confirmationText == 'DELETE' ? () {
                              ref.read(transactionProvider.notifier).clearAll();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('All data cleared successfully')),
                              );
                            } : null,
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                color: confirmationText == 'DELETE' ? AppColors.expenseAccent : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                      ),
                    ],
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

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    
    setState(() => _isUploading = true);
    try {
      final file = File(xfile.path);
      await ref.read(authProvider.notifier).updateProfilePicture(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;
    final displayName = user?.displayName ?? 'User';

    return Column(
      children: [
        GestureDetector(
          onTap: _pickAndUploadImage,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null 
                    ? Icon(Icons.person_rounded, size: 50, color: theme.colorScheme.primary)
                    : null,
              ),
              if (_isUploading)
                const Positioned.fill(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt_rounded, size: 20, color: theme.colorScheme.onPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(displayName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showEditNameDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: FirebaseAuth.instance.currentUser?.displayName);
    GlassDialog.show(
      context: context,
      title: 'Edit Profile Name',
      content: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Enter new name',
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            if (nameController.text.trim().isEmpty) return;
            Navigator.pop(context);
            try {
              await ref.read(authProvider.notifier).updateProfileName(nameController.text.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated successfully')));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            }
          },
          child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();
    GlassDialog.show(
      context: context,
      title: 'Change Password',
      content: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Enter new password',
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            if (passwordController.text.trim().length < 6) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
              return;
            }
            Navigator.pop(context);
            try {
              await ref.read(authProvider.notifier).updatePassword(passwordController.text.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            }
          },
          child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
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
            Text(label, style: theme.textTheme.titleMedium?.copyWith(color: textColor)),
            const SizedBox(width: 16),
            if (value.isNotEmpty)
              Expanded(
                child: Text(
                  value, 
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const Spacer(),
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

  void _showSelectionSheet<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required T currentItem,
    required String Function(T) itemLabel,
    required void Function(T) onSelected,
  }) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...items.map((item) {
                  final isSelected = currentItem == item;
                  return ListTile(
                    title: Text(itemLabel(item), style: theme.textTheme.bodyLarge?.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    trailing: isSelected ? Icon(Icons.check_rounded, color: theme.colorScheme.primary) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      onSelected(item);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref, String currentCurrency) {
    final currencies = ['BDT (৳)', 'USD (\$)', 'EUR (€)', 'GBP (£)', 'INR (₹)'];
    _showSelectionSheet<String>(
      context: context,
      title: 'Select Currency',
      items: currencies,
      currentItem: currentCurrency,
      itemLabel: (item) => item,
      onSelected: (value) => ref.read(preferencesProvider.notifier).setCurrency(value),
    );
  }

  void _showFirstDayPicker(BuildContext context, WidgetRef ref, String currentDay) {
    final days = ['1st of Month', 'Monday', 'Sunday'];
    _showSelectionSheet<String>(
      context: context,
      title: 'First Day of Month',
      items: days,
      currentItem: currentDay,
      itemLabel: (item) => item,
      onSelected: (value) => ref.read(preferencesProvider.notifier).setFirstDayOfMonth(value),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode currentThemeMode) {
    final themes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
    final themeNames = {
      ThemeMode.system: 'System Default',
      ThemeMode.light: 'Light Mode',
      ThemeMode.dark: 'Dark Mode',
    };
    _showSelectionSheet<ThemeMode>(
      context: context,
      title: 'Select Theme',
      items: themes,
      currentItem: currentThemeMode,
      itemLabel: (item) => themeNames[item] ?? '',
      onSelected: (value) => ref.read(themeModeProvider.notifier).setTheme(value),
    );
  }
}
