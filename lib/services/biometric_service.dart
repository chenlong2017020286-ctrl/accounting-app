import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static BiometricService? _instance;
  final _auth = LocalAuthentication();
  bool _enabled = false;

  BiometricService._();

  static BiometricService get instance {
    _instance ??= BiometricService._();
    return _instance!;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('biometric_enabled') ?? false;
  }

  bool get enabled => _enabled;
  bool get canCheck => _enabled;

  Future<bool> get isAvailable async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool v) async {
    _enabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', v);
  }

  Future<bool> authenticate() async {
    if (!_enabled) return true;
    try {
      return await _auth.authenticate(
        localizedReason: '验证身份以打开账本',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
