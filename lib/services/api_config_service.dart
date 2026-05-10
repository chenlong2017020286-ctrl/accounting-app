import 'package:shared_preferences/shared_preferences.dart';

class ApiConfigService {
  static ApiConfigService? _instance;
  late SharedPreferences _prefs;

  ApiConfigService._();

  static ApiConfigService get instance {
    _instance ??= ApiConfigService._();
    return _instance!;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get endpoint => _prefs.getString('api_endpoint') ?? 'https://api.deepseek.com';
  String get apiKey => _prefs.getString('api_key') ?? '';
  String get model => _prefs.getString('api_model') ?? 'deepseek-chat';

  bool get isConfigured => apiKey.isNotEmpty;

  Future<void> setEndpoint(String v) => _prefs.setString('api_endpoint', v);
  Future<void> setApiKey(String v) => _prefs.setString('api_key', v);
  Future<void> setModel(String v) => _prefs.setString('api_model', v);
}
