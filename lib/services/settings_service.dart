import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AIProvider { openai, anthropic }

class SettingsService extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String _openAIKey = '';
  String _anthropicKey = '';
  AIProvider _defaultProvider = AIProvider.openai;

  String get openAIKey => _openAIKey;
  String get anthropicKey => _anthropicKey;
  AIProvider get defaultProvider => _defaultProvider;

  bool get hasValidAPIKey {
    switch (_defaultProvider) {
      case AIProvider.openai:
        return _openAIKey.isNotEmpty;
      case AIProvider.anthropic:
        return _anthropicKey.isNotEmpty;
    }
  }

  String get currentAPIKey {
    switch (_defaultProvider) {
      case AIProvider.openai:
        return _openAIKey;
      case AIProvider.anthropic:
        return _anthropicKey;
    }
  }

  Future<void> load() async {
    _openAIKey = await _secureStorage.read(key: 'openai_api_key') ?? '';
    _anthropicKey = await _secureStorage.read(key: 'anthropic_api_key') ?? '';

    final providerString = await _secureStorage.read(key: 'default_provider');
    if (providerString == 'anthropic') {
      _defaultProvider = AIProvider.anthropic;
    } else {
      _defaultProvider = AIProvider.openai;
    }

    notifyListeners();
  }

  Future<void> setOpenAIKey(String key) async {
    _openAIKey = key;
    await _secureStorage.write(key: 'openai_api_key', value: key);
    notifyListeners();
  }

  Future<void> setAnthropicKey(String key) async {
    _anthropicKey = key;
    await _secureStorage.write(key: 'anthropic_api_key', value: key);
    notifyListeners();
  }

  Future<void> setDefaultProvider(AIProvider provider) async {
    _defaultProvider = provider;
    await _secureStorage.write(
      key: 'default_provider',
      value: provider == AIProvider.anthropic ? 'anthropic' : 'openai',
    );
    notifyListeners();
  }
}
