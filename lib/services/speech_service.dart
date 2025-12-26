import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();

  bool _isListening = false;
  bool _isAvailable = false;
  String _transcript = '';
  String? _error;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get transcript => _transcript;
  String? get error => _error;

  Future<bool> initialize() async {
    // Request speech recognition permission
    final status = await Permission.speech.request();
    if (!status.isGranted) {
      _error = 'Speech recognition permission denied';
      notifyListeners();
      return false;
    }

    try {
      _isAvailable = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
      notifyListeners();
      return _isAvailable;
    } catch (e) {
      _error = 'Failed to initialize speech recognition: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> startListening() async {
    if (!_isAvailable) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    _transcript = '';
    _error = null;

    try {
      await _speech.listen(
        onResult: (result) {
          _transcript = result.recognizedWords;
          notifyListeners();
        },
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      );
      _isListening = true;
      notifyListeners();
    } catch (e) {
      _error = 'Error starting speech recognition: $e';
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error stopping speech recognition: $e';
      notifyListeners();
    }
  }

  void clearTranscript() {
    _transcript = '';
    notifyListeners();
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      notifyListeners();
    }
  }

  void _onError(dynamic error) {
    _error = error.toString();
    _isListening = false;
    notifyListeners();
  }
}
