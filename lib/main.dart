import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/account_service.dart';
import 'services/storage_service.dart';
import 'services/api_config_service.dart';
import 'services/budget_service.dart';
import 'services/category_service.dart';
import 'services/recurring_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AccountService.instance.init();
  await StorageService.instance.init();
  await ApiConfigService.instance.init();
  await BudgetService.instance.init();
  await CategoryService.instance.init();
  await RecurringService.instance.init();
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

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool('dark_mode') ?? false;
    setState(() => _themeMode = dark ? ThemeMode.dark : ThemeMode.light);
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
      home: HomeScreen(onToggleTheme: _toggleTheme),
    );
  }
}
