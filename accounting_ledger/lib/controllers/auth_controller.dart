// lib/controllers/auth_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

enum AuthState { loading, unauthenticated, authenticated }

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.loading) {
    _checkAuth();
  }

  bool _biometricEnabled = false;
  bool _hasPinSet = false;

  bool get biometricEnabled => _biometricEnabled;
  bool get hasPinSet => _hasPinSet;

  Future<void> _checkAuth() async {
    _hasPinSet = await AuthService.hasPin();
    _biometricEnabled = await AuthService.isBiometricEnabled();
    if (!_hasPinSet) {
      state = AuthState.unauthenticated;
    } else {
      state = AuthState.unauthenticated;
    }
  }

  Future<bool> verifyPin(String pin) async {
    final ok = await AuthService.verifyPin(pin);
    if (ok) state = AuthState.authenticated;
    return ok;
  }

  Future<void> setPin(String pin) async {
    await AuthService.setPin(pin);
    _hasPinSet = true;
    state = AuthState.authenticated;
  }

  Future<bool> authenticateWithBiometrics(String reason) async {
    final ok = await AuthService.authenticateWithBiometrics(reason);
    if (ok) state = AuthState.authenticated;
    return ok;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await AuthService.setBiometricEnabled(enabled);
    _biometricEnabled = enabled;
  }

  Future<bool> isBiometricAvailable() async {
    return AuthService.isBiometricAvailable();
  }

  void logout() {
    state = AuthState.unauthenticated;
  }

  Future<void> changePin(String currentPin, String newPin) async {
    final ok = await AuthService.verifyPin(currentPin);
    if (!ok) throw Exception('Invalid current PIN');
    await AuthService.setPin(newPin);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
