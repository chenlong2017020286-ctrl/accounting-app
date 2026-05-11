import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/account_model.dart';

class AccountService {
  static AccountService? _instance;
  late File _file;
  final List<AccountModel> _accounts = [];
  static const String _fileName = 'accounts.json';

  AccountService._();

  static AccountService get instance {
    _instance ??= AccountService._();
    return _instance!;
  }

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/$_fileName');
    await _load();
    if (_accounts.isEmpty) {
      _seedDefaults();
      await _persist();
    }
  }

  Future<void> _load() async {
    if (!await _file.exists()) return;
    try {
      final content = await _file.readAsString();
      final list = json.decode(content) as List;
      _accounts.addAll(
          list.map((e) => AccountModel.fromJson(e as Map<String, dynamic>)));
    } catch (e) {
      debugPrint('AccountService: failed to load accounts.json: $e');
    }
  }

  Future<void> _persist() async {
    final data = _accounts.map((a) => a.toJson()).toList();
    await _file.writeAsString(json.encode(data));
  }

  void _seedDefaults() {
    _accounts.addAll([
      AccountModel(name: '现金', icon: '💰', type: AccountType.cash),
      AccountModel(name: '银行卡', icon: '🏦', type: AccountType.bank),
      AccountModel(name: '支付宝', icon: '📱', type: AccountType.alipay),
      AccountModel(name: '微信', icon: '💬', type: AccountType.wechat),
      AccountModel(name: '信用卡', icon: '💳', type: AccountType.creditCard),
    ]);
  }

  List<AccountModel> get all => List.unmodifiable(_accounts);

  AccountModel? getById(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> add(AccountModel account) async {
    _accounts.add(account);
    await _persist();
  }

  Future<void> update(AccountModel account) async {
    final idx = _accounts.indexWhere((a) => a.id == account.id);
    if (idx >= 0) {
      _accounts[idx] = account;
      await _persist();
    }
  }

  Future<void> delete(String id) async {
    _accounts.removeWhere((a) => a.id == id);
    await _persist();
  }

  Future<void> adjustBalance(String accountId, double delta) async {
    final idx = _accounts.indexWhere((a) => a.id == accountId);
    if (idx >= 0) {
      _accounts[idx].balance += delta;
      await _persist();
    }
  }
}
