// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'controllers/auth_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/account_controller.dart';
import 'controllers/transaction_controller.dart';
import 'utils/theme.dart';
import 'views/screens/pin_screen.dart';
import 'views/screens/dashboard_screen.dart';
import 'views/screens/account_list_screen.dart';
import 'views/screens/transaction_form_screen.dart';
import 'views/screens/reports_screen.dart';
import 'views/screens/settings_screen.dart';
import 'views/screens/backup_restore_screen.dart';

class AccountingLedgerApp extends ConsumerWidget {
  const AccountingLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // إزالة DynamicColorBuilder بالكامل
    return MaterialApp(
      title: 'Accounting Ledger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: settings.locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child!,
        );
      },
      home: const _AppRouter(),
    );
  }
}

// ... باقي الكود (_AppRouter, MainShell, ...) يبقى كما هو دون أي تغيير ...
