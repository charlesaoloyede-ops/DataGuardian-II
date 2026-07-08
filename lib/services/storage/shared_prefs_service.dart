import 'dart:convert';
import 'dart:math';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../features/alerts/domain/entities/user_preferences.dart';

@lazySingleton
class SharedPrefsService {
  late SharedPreferences _prefs;

  @factoryMethod
  static Future<SharedPrefsService> create() async {
    final service = SharedPrefsService();
    service._prefs = await SharedPreferences.getInstance();
    return service;
  }

  bool get onboardingComplete =>
      _prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;

  Future<void> setOnboardingComplete(bool value) =>
      _prefs.setBool(AppConstants.keyOnboardingComplete, value);

  UserPreferences getPreferences() {
    final json = _prefs.getString('user_preferences');
    if (json == null) return const UserPreferences();
    return UserPreferences.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> savePreferences(UserPreferences prefs) =>
      _prefs.setString('user_preferences', jsonEncode(prefs.toJson()));

  bool get isDarkMode => _prefs.getBool(AppConstants.keyDarkMode) ?? false;
  Future<void> setDarkMode(bool value) =>
      _prefs.setBool(AppConstants.keyDarkMode, value);

  /// Whether the one-time analytics consent prompt has been shown. Used to ask
  /// already-onboarded users about the new opt-in analytics exactly once, after
  /// they update — without a reinstall.
  bool get analyticsConsentPrompted =>
      _prefs.getBool('analytics_consent_prompted') ?? false;

  Future<void> setAnalyticsConsentPrompted(bool value) =>
      _prefs.setBool('analytics_consent_prompted', value);

  /// IDs of feedback threads whose reply the user has already seen — used to
  /// show an unread badge only for replies they haven't opened yet.
  Set<String> getSeenReplyIds() =>
      _prefs.getStringList('seen_reply_ids')?.toSet() ?? <String>{};

  Future<void> addSeenReplyIds(Iterable<String> ids) async {
    final updated = getSeenReplyIds()..addAll(ids);
    await _prefs.setStringList('seen_reply_ids', updated.toList());
  }

  /// Returns a map of packageName → budget in bytes. Empty if none set.
  Map<String, int> getAppBudgets() {
    final json = _prefs.getString('app_budgets');
    if (json == null) return {};
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as int));
  }

  Future<void> saveAppBudgets(Map<String, int> budgets) =>
      _prefs.setString('app_budgets', jsonEncode(budgets));

  /// Returns a map of packageName → last notified budget threshold percent
  /// (70/80/90/100) for the current billing cycle. Empty if none notified yet.
  Map<String, int> getBudgetAlertProgress() {
    final json = _prefs.getString('budget_alert_progress');
    if (json == null) return {};
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as int));
  }

  Future<void> saveBudgetAlertProgress(Map<String, int> progress) =>
      _prefs.setString('budget_alert_progress', jsonEncode(progress));

  /// Billing-cycle key that [getBudgetAlertProgress] was last recorded for.
  /// A mismatch means the cycle has rolled over and progress should reset.
  String? get budgetAlertCycleKey => _prefs.getString('budget_alert_cycle_key');

  Future<void> setBudgetAlertCycleKey(String key) =>
      _prefs.setString('budget_alert_cycle_key', key);

  /// Anonymous per-install id used to correlate a user's feedback threads
  /// without collecting PII. Generated once, then stable for the install.
  String getOrCreateInstallId() {
    const key = 'install_id';
    var id = _prefs.getString(key);
    if (id == null || id.isEmpty) {
      id = _generateInstallId();
      _prefs.setString(key, id);
    }
    return id;
  }

  String _generateInstallId() {
    final rnd = Random();
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final tail =
        List.generate(8, (_) => rnd.nextInt(16).toRadixString(16)).join();
    return 'ins_${ts}_$tail';
  }

  /// Appends a feedback submission to the local pending queue. Drained and sent
  /// to Firestore once the Firebase layer is wired (see
  /// docs/backend/firestore-schema.md).
  Future<void> enqueuePendingFeedback(Map<String, dynamic> submission) async {
    final list = _pendingFeedback()..add(submission);
    await _prefs.setString('pending_feedback', jsonEncode(list));
  }

  List<Map<String, dynamic>> _pendingFeedback() {
    final json = _prefs.getString('pending_feedback');
    if (json == null || json.isEmpty) return [];
    try {
      return (jsonDecode(json) as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Reads and clears queued feedback so the Firestore sync can flush it.
  Future<List<Map<String, dynamic>>> drainPendingFeedback() async {
    final list = _pendingFeedback();
    if (list.isNotEmpty) await _prefs.remove('pending_feedback');
    return list;
  }

  /// Reads and clears alerts the native background monitor
  /// ([UsageMonitorWorker]) fired while the app was closed, so the foreground
  /// app can persist them to the Alerts Center. Each entry has `type`,
  /// `message`, and `triggeredAtMs`.
  Future<List<Map<String, dynamic>>> drainPendingNativeAlerts() async {
    final json = _prefs.getString('pending_native_alerts');
    if (json == null || json.isEmpty) return [];
    await _prefs.remove('pending_native_alerts');
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
