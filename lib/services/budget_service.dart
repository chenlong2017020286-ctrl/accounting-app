import 'package:shared_preferences/shared_preferences.dart';

class BudgetService {
  static BudgetService? _instance;
  late SharedPreferences _prefs;

  BudgetService._();

  static BudgetService get instance {
    _instance ??= BudgetService._();
    return _instance!;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  double get monthlyBudget => _prefs.getDouble('monthly_budget') ?? 0;

  bool get hasBudget => monthlyBudget > 0;

  Future<void> setMonthlyBudget(double v) async {
    await _prefs.setDouble('monthly_budget', v);
  }

  /// Returns 0.0–1.0 budget usage ratio for the given expense amount
  double usageRatio(double monthExpense) {
    if (!hasBudget) return 0;
    return (monthExpense / monthlyBudget).clamp(0, 2.0);
  }

  double remaining(double monthExpense) {
    if (!hasBudget) return 0;
    return (monthlyBudget - monthExpense).clamp(0, monthlyBudget);
  }

  bool get isExceeded => false; // evaluated externally with monthExpense
}
