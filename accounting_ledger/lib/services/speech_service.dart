// lib/services/speech_service.dart
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  static final _speech = SpeechToText();
  static bool _available = false;

  static Future<bool> initialize() async {
    _available = await _speech.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
    return _available;
  }

  static bool get isAvailable => _available;
  static bool get isListening => _speech.isListening;

  static Future<void> startListening({
    required void Function(String) onResult,
    String localeId = 'en_US',
  }) async {
    if (!_available) await initialize();
    if (!_available) return;
    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
    );
  }

  static Future<void> stopListening() async {
    await _speech.stop();
  }

  static Future<void> cancelListening() async {
    await _speech.cancel();
  }
}
