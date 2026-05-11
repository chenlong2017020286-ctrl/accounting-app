import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiConfigService {
  static ApiConfigService? _instance;
  late FlutterSecureStorage _storage;

  ApiConfigService._();

  static ApiConfigService get instance {
    _instance ??= ApiConfigService._();
    return _instance!;
  }

  Future<void> init() async {
    _storage = const FlutterSecureStorage();
  }

  String? _endpoint;
  String? _apiKey;
  String? _model;

  Future<String> get endpoint async {
    _endpoint ??= await _storage.read(key: 'api_endpoint');
    return _endpoint ?? 'https://api.deepseek.com';
  }

  Future<String> get apiKey async {
    _apiKey ??= await _storage.read(key: 'api_key');
    return _apiKey ?? '';
  }

  Future<String> get model async {
    _model ??= await _storage.read(key: 'api_model');
    return _model ?? 'deepseek-chat';
  }

  Future<bool> get isConfigured async => (await apiKey).isNotEmpty;

  Future<void> setEndpoint(String v) async {
    _endpoint = v;
    await _storage.write(key: 'api_endpoint', value: v);
  }

  Future<void> setApiKey(String v) async {
    _apiKey = v;
    await _storage.write(key: 'api_key', value: v);
  }

  Future<void> setModel(String v) async {
    _model = v;
    await _storage.write(key: 'api_model', value: v);
  }
}
