import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/save_plan.dart';
import '../models/save_record.dart';

class SaveProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<SavePlan> _plans = [];
  List<SaveRecord> _records = [];
  bool _loading = false;

  List<SavePlan> get plans => _plans;
  List<SaveRecord> get records => _records;
  bool get loading => _loading;

  double get totalTarget =>
      _plans.fold<double>(0, (sum, p) => sum + p.totalTarget);
  double get totalSaved =>
      _plans.fold<double>(0, (sum, p) => sum + p.currentAmount);
  double get totalRemaining => totalTarget - totalSaved;

  Future<void> loadPlans() async {
    _loading = true;
    notifyListeners();
    _plans = await _db.getSavePlans();
    _loading = false;
    notifyListeners();
  }

  Future<SavePlan?> getPlanById(int id) async {
    return await _db.getSavePlanById(id);
  }

  Future<SavePlan> createPlan(
      SavePlan plan, List<SaveRecord> records) async {
    final id = await _db.insertSavePlan(plan);
    final created = plan.copyWith(
        id: id, createdAt: DateTime.now().toIso8601String());
    final recordsWithPlanId = records
        .map((r) => r.copyWith(
            planId: id,
            createdAt: DateTime.now().toIso8601String()))
        .toList();
    await _db.batchInsertSaveRecords(recordsWithPlanId);
    await loadPlans();
    return created;
  }

  Future<void> updatePlan(SavePlan plan) async {
    await _db.updateSavePlan(plan);
    await loadPlans();
  }

  Future<void> deletePlan(int id) async {
    await _db.deleteSavePlan(id);
    await loadPlans();
  }

  Future<void> loadRecords(int planId) async {
    _records = await _db.getSaveRecords(planId);
    notifyListeners();
  }

  Future<void> markRecordDone(int recordId, double amount, int planId,
      String date) async {
    final existing = await _db.getSaveRecordById(recordId);
    if (existing == null) return;
    await _db.updateSaveRecord(existing.copyWith(
      savedAmount: amount,
      status: 'done',
      savedDate: date,
    ));
    await _recalcPlanAmount(planId);
    await loadRecords(planId);
  }

  Future<void> cancelRecordDone(int recordId, int planId) async {
    final existing = await _db.getSaveRecordById(recordId);
    if (existing == null) return;
    await _db.updateSaveRecord(existing.copyWith(
      savedAmount: 0,
      status: 'pending',
      savedDate: null,
    ));
    await _recalcPlanAmount(planId);
    await loadRecords(planId);
  }

  Future<void> _recalcPlanAmount(int planId) async {
    final records = await _db.getSaveRecords(planId);
    final totalSaved = records
        .where((r) => r.status == 'done')
        .fold<double>(0, (sum, r) => sum + r.savedAmount);
    final plan = await _db.getSavePlanById(planId);
    if (plan != null) {
      final updated = plan.copyWith(currentAmount: totalSaved);
      await _db.updateSavePlan(updated);
    }
  }

  /// 类型感知的单期目标金额计算
  static double calcDayTarget(
      String type, double startAmount, int dayIndex, double coeff, double monthAmount) {
    switch (type) {
      case '365':
        return startAmount * dayIndex;
      case '52week':
        return startAmount * dayIndex;
      case '12deposit':
        return monthAmount;
      case 'elastic':
        return startAmount + coeff * (dayIndex - 1);
      case 'flexible':
        return 0;
      default:
        return startAmount + coeff * (dayIndex - 1);
    }
  }

  /// 类型感知的总目标计算
  static double calcTotalTarget(
      String type, double startAmount, int days, double coeff, double monthAmount) {
    switch (type) {
      case '365':
        return startAmount * days * (days + 1) / 2;
      case '52week':
        return startAmount * days * (days + 1) / 2;
      case '12deposit':
        return monthAmount * 12;
      case 'elastic':
        return startAmount * days + coeff * (days * (days - 1) / 2);
      case 'flexible':
        return 0;
      default:
        return startAmount * days + coeff * (days * (days - 1) / 2);
    }
  }

  static int calcDuration(String type, int? customDays) {
    switch (type) {
      case '365':
        return 365;
      case '52week':
        return 52;
      case '12deposit':
        return 12;
      case 'elastic':
        return customDays ?? 30;
      case 'flexible':
        return 0;
      default:
        return 30;
    }
  }
}
