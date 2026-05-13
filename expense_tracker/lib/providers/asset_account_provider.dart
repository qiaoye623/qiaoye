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

    _accounts = await _db.getAssetAccounts();

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
