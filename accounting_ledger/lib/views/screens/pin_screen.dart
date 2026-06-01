// lib/views/screens/pin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/constants.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _confirmPin = '';
  bool _isCreating = false;
  bool _isConfirming = false;
  bool _isError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 8)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = ref.read(authProvider.notifier);
      final hasPinSet = auth.hasPinSet;
      if (!hasPinSet) {
        setState(() => _isCreating = true);
      } else if (auth.biometricEnabled) {
        final ok = await auth.authenticateWithBiometrics(
            'Authenticate to access Accounting Ledger');
        if (!ok && mounted) {
          // fall back to PIN
        }
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyTap(String digit) {
    if (_pin.length >= AppConstants.pinLength) return;
    setState(() {
      _pin += digit;
      _isError = false;
    });
    if (_pin.length == AppConstants.pinLength) {
      _handlePinComplete();
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _isError = false;
    });
  }

  Future<void> _handlePinComplete() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final auth = ref.read(authProvider.notifier);

    if (_isCreating) {
      if (!_isConfirming) {
        setState(() {
          _confirmPin = _pin;
          _pin = '';
          _isConfirming = true;
        });
      } else {
        if (_pin == _confirmPin) {
          await auth.setPin(_pin);
        } else {
          _shake();
          setState(() {
            _pin = '';
            _confirmPin = '';
            _isConfirming = false;
            _isError = true;
          });
        }
      }
    } else {
      final ok = await auth.verifyPin(_pin);
      if (!ok) {
        _shake();
        setState(() {
          _pin = '';
          _isError = true;
        });
      }
    }
  }

  void _shake() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String title;
    if (_isCreating) {
      title = _isConfirming ? 'Confirm PIN' : 'Create PIN';
    } else {
      title = 'Enter PIN';
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Logo / Title
            Icon(
              Icons.account_balance_wallet_rounded,
              size: 72,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Accounting Ledger',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            // PIN dots
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value % 2 == 0
                      ? _shakeAnimation.value
                      : -_shakeAnimation.value, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(AppConstants.pinLength, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.all(8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isError
                          ? colorScheme.error
                          : filled
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.2),
                    ),
                  );
                }),
              ),
            ),
            if (_isError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _isCreating ? 'PINs do not match' : 'Invalid PIN',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            const Spacer(),
            // Keypad
            _buildKeypad(colorScheme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          _buildKeyRow(['1', '2', '3'], colors),
          _buildKeyRow(['4', '5', '6'], colors),
          _buildKeyRow(['7', '8', '9'], colors),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _biometricButton(colors),
              _numKey('0', colors),
              _deleteKey(colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys, ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) => _numKey(k, colors)).toList(),
    );
  }

  Widget _numKey(String digit, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: colors.surfaceVariant,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => _onKeyTap(digit),
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 72,
            height: 72,
            child: Center(
              child: Text(
                digit,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _deleteKey(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 72,
        height: 72,
        child: IconButton(
          icon: const Icon(Icons.backspace_outlined),
          iconSize: 28,
          onPressed: _onDelete,
          color: colors.onBackground.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _biometricButton(ColorScheme colors) {
    final auth = ref.read(authProvider.notifier);
    if (!auth.biometricEnabled || _isCreating) {
      return const SizedBox(width: 72, height: 72);
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 72,
        height: 72,
        child: IconButton(
          icon: const Icon(Icons.fingerprint),
          iconSize: 32,
          color: colors.primary,
          onPressed: () async {
            await auth.authenticateWithBiometrics(
                'Authenticate to access Accounting Ledger');
          },
        ),
      ),
    );
  }
}
