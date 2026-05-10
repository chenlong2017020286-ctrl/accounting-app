import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/storage_service.dart';
import 'services/api_config_service.dart';
import 'services/biometric_service.dart';
import 'services/budget_service.dart';
import 'services/recurring_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
  await ApiConfigService.instance.init();
  await BiometricService.instance.init();
  await BudgetService.instance.init();
  await RecurringService.instance.init();

  // Generate recurring transactions for today
  await RecurringService.instance.generateDue();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const AccountingApp());
}

class AccountingApp extends StatefulWidget {
  const AccountingApp({super.key});

  @override
  State<AccountingApp> createState() => _AccountingAppState();
}

class _AccountingAppState extends State<AccountingApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _checkAuth();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool('dark_mode') ?? false;
    setState(() => _themeMode = dark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _checkAuth() async {
    final bio = BiometricService.instance;
    if (bio.enabled) {
      final ok = await bio.authenticate();
      if (mounted) setState(() => _unlocked = ok);
    } else {
      setState(() => _unlocked = true);
    }
  }

  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = _themeMode == ThemeMode.dark;
    setState(() => _themeMode = isDark ? ThemeMode.light : ThemeMode.dark);
    await prefs.setBool('dark_mode', !isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '我的账本',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: _unlocked
          ? HomeScreen(onToggleTheme: _toggleTheme)
          : const _LockScreen(),
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.white70),
            const SizedBox(height: 16),
            const Text('我的账本', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('验证后即可进入', style: TextStyle(fontSize: 14, color: Colors.white60)),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
