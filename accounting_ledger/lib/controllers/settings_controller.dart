// lib/controllers/settings_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final bool biometricEnabled;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('en'),
    this.biometricEnabled = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? biometricEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final themeStr = await AuthService.getThemeMode();
    final localeStr = await AuthService.getLocale();
    final biometric = await AuthService.isBiometricEnabled();

    ThemeMode themeMode;
    switch (themeStr) {
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      case 'light':
        themeMode = ThemeMode.light;
        break;
      default:
        themeMode = ThemeMode.system;
    }

    state = state.copyWith(
      themeMode: themeMode,
      locale: Locale(localeStr ?? 'en'),
      biometricEnabled: biometric,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String modeStr;
    switch (mode) {
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
      case ThemeMode.light:
        modeStr = 'light';
        break;
      default:
        modeStr = 'system';
    }
    await AuthService.setThemeMode(modeStr);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setLocale(String languageCode) async {
    await AuthService.setLocale(languageCode);
    state = state.copyWith(locale: Locale(languageCode));
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await AuthService.setBiometricEnabled(enabled);
    state = state.copyWith(biometricEnabled: enabled);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
