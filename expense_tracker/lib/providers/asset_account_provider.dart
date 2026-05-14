import 'package:flutter/foundation.dart';
import '../models/asset_account.dart';
import '../database/database_helper.dart';

class AssetAccountProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<AssetAccount> _accounts = [];
  bool _loading = false;

  List<AssetAccount> get accounts => _accounts;
  bool get loading => _loading;

  Future<void> loadAccounts() async {
    _loading = true;
    notifyListeners();

    try {
      _accounts = await _db.getAssetAccounts();
    } catch (e) {
      debugPrint('Failed to load asset accounts: $e');
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> updateBalance(int id, double newBalance) async {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index == -1) return;

    final updated = _accounts[index].copyWith(balance: newBalance);
    await _db.updateAssetAccount(updated);
    _accounts[index] = updated;
    notifyListeners();
  }

  Future<AssetAccount> addAccount(
      String name, String icon, String type, double balance) async {
    if (_accounts.any((a) => a.name == name && a.type == type)) {
      throw Exception('该账户已存在，请修改名称或类型');
    }
    final account = AssetAccount(
      name: name,
      icon: icon,
      type: type,
      balance: balance,
    );
    final id = await _db.insertAssetAccount(account);
    final created = account.copyWith(id: id);
    _accounts.add(created);
    notifyListeners();
    return created;
  }

  Future<void> deleteAccount(int id) async {
    await _db.deleteAssetAccount(id);
    _accounts.removeWhere((a) => a.id == id);
    notifyListeners();
  }
}
