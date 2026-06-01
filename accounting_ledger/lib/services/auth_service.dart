// lib/services/auth_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/constants.dart';

class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static final _localAuth = LocalAuthentication();

  // ─── PIN ──────────────────────────────────────────────────────────────────

  static Future<bool> hasPin() async {
    final pin = await _storage.read(key: AppConstants.pinKey);
    return pin != null && pin.isNotEmpty;
  }

  static Future<void> setPin(String pin) async {
    await _storage.write(key: AppConstants.pinKey, value: pin);
  }

  static Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: AppConstants.pinKey);
    return stored == pin;
  }

  static Future<void> deletePin() async {
    await _storage.delete(key: AppConstants.pinKey);
  }

  // ─── Biometrics ───────────────────────────────────────────────────────────

  static Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: AppConstants.biometricKey);
    return val == 'true';
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
        key: AppConstants.biometricKey, value: enabled.toString());
  }

  static Future<bool> authenticateWithBiometrics(String localizedReason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ─── Theme / Locale ───────────────────────────────────────────────────────

  static Future<String?> getThemeMode() async {
    return _storage.read(key: AppConstants.themeKey);
  }

  static Future<void> setThemeMode(String mode) async {
    await _storage.write(key: AppConstants.themeKey, value: mode);
  }

  static Future<String?> getLocale() async {
    return _storage.read(key: AppConstants.localeKey);
  }

  static Future<void> setLocale(String locale) async {
    await _storage.write(key: AppConstants.localeKey, value: locale);
  }
}
