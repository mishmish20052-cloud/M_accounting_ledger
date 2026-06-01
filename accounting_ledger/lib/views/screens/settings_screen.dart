// lib/views/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _sectionHeader(theme, 'Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(settings.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context, ref, settings.themeMode),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(settings.locale.languageCode == 'ar'
                ? 'العربية'
                : 'English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context, ref, settings.locale.languageCode),
          ),
          const Divider(),
          _sectionHeader(theme, 'Security'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePinDialog(context, ref),
          ),
          FutureBuilder<bool>(
            future: AuthService.isBiometricAvailable(),
            builder: (context, snap) {
              if (snap.data != true) return const SizedBox.shrink();
              return SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: const Text('Biometric Authentication'),
                subtitle: const Text('Use fingerprint or face to unlock'),
                value: settings.biometricEnabled,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setBiometricEnabled(v),
              );
            },
          ),
          const Divider(),
          _sectionHeader(theme, 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            trailing: Text('1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.account_balance_wallet_rounded),
            title: Text('Accounting Ledger'),
            subtitle: Text('دفتر الأستاذ المحاسبي'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.light:
        return 'Light Mode';
      default:
        return 'System Default';
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode current) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: current,
              onChanged: (v) {
                ref.read(settingsProvider.notifier).setThemeMode(v!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light Mode'),
              value: ThemeMode.light,
              groupValue: current,
              onChanged: (v) {
                ref.read(settingsProvider.notifier).setThemeMode(v!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark Mode'),
              value: ThemeMode.dark,
              groupValue: current,
              onChanged: (v) {
                ref.read(settingsProvider.notifier).setThemeMode(v!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(
      BuildContext context, WidgetRef ref, String current) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: current,
              onChanged: (v) {
                ref.read(settingsProvider.notifier).setLocale(v!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('العربية'),
              value: 'ar',
              groupValue: current,
              onChanged: (v) {
                ref.read(settingsProvider.notifier).setLocale(v!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePinDialog(
      BuildContext context, WidgetRef ref) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Change PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null) ...[
                Text(error!,
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: currentCtrl,
                decoration:
                    const InputDecoration(labelText: 'Current PIN'),
                keyboardType: TextInputType.number,
                maxLength: AppConstants.pinLength,
                obscureText: true,
              ),
              TextField(
                controller: newCtrl,
                decoration:
                    const InputDecoration(labelText: 'New PIN'),
                keyboardType: TextInputType.number,
                maxLength: AppConstants.pinLength,
                obscureText: true,
              ),
              TextField(
                controller: confirmCtrl,
                decoration:
                    const InputDecoration(labelText: 'Confirm New PIN'),
                keyboardType: TextInputType.number,
                maxLength: AppConstants.pinLength,
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (newCtrl.text != confirmCtrl.text) {
                  setState(() => error = 'PINs do not match');
                  return;
                }
                if (newCtrl.text.length < AppConstants.pinLength) {
                  setState(() => error =
                      'PIN must be ${AppConstants.pinLength} digits');
                  return;
                }
                try {
                  await ref
                      .read(authProvider.notifier)
                      .changePin(currentCtrl.text, newCtrl.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('PIN changed successfully')));
                  }
                } catch (e) {
                  setState(() => error = e.toString());
                }
              },
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }
}
