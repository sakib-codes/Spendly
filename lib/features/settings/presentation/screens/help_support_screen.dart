import 'package:flutter/material.dart';
import 'package:spendly/shared/widgets/glass_card.dart';
import 'package:spendly/shared/widgets/primary_button.dart';
import 'package:spendly/shared/widgets/glass_toast.dart';
import 'package:spendly/shared/widgets/custom_header.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail(BuildContext context, {String subject = 'Spendly Support Request'}) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@spendly.app',
      query: 'subject=$subject',
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (context.mounted) {
        GlassToast.show(context: context, message: 'Could not open email client.');
      }
    }
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        GlassToast.show(context: context, message: 'Could not open link.');
      }
    }
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CustomHeader(title: 'Help & Support'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Us',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildActionTile(
                      context,
                      'Email Support',
                      'General inquiries and help',
                      Icons.email_outlined,
                      () => _launchEmail(context),
                    ),
                    _buildActionTile(
                      context,
                      'Report a Bug',
                      'Found something weird? Let us know.',
                      Icons.bug_report_outlined,
                      () => _launchEmail(context, subject: 'Spendly Bug Report'),
                    ),
                    _buildActionTile(
                      context,
                      'Request a Feature',
                      'Have a great idea? Tell us!',
                      Icons.lightbulb_outline_rounded,
                      () => _launchEmail(context, subject: 'Spendly Feature Request'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildActionTile(
                      context,
                      'Discord',
                      'Join the Spendly community',
                      Icons.discord,
                      () => _launchUrl(context, 'https://discord.com'),
                    ),
                    _buildActionTile(
                      context,
                      'Twitter / X',
                      'Follow us for updates',
                      Icons.chat_bubble_outline_rounded,
                      () => _launchUrl(context, 'https://twitter.com'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frequently Asked Questions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFaqItem(
                      context,
                      'How do I add a transaction?',
                      'Tap the large + button on the bottom navigation bar from any main screen.',
                    ),
                    _buildFaqItem(
                      context,
                      'Can I export my data?',
                      'Yes! Go to Settings > Export Data to generate a CSV or PDF of your transactions.',
                    ),
                    _buildFaqItem(
                      context,
                      'Is my data secure?',
                      'Spendly stores all data locally on your device unless you enable cloud sync. We never sell your data.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
),
);
}
}
