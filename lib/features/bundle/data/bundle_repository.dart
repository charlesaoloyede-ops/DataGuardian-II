import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/storage/shared_prefs_service.dart';
import '../domain/entities/data_bundle.dart';
import '../domain/entities/bundle_status.dart';

/// Owns the single monitored data bundle: persistence (shared with the native
/// worker via [SharedPrefsService]) plus the device-level consumption queries
/// used to compute live status. Every mutation re-anchors the bundle to "now"
/// so remaining is always `anchorBalance − usageSinceAnchor`.
class BundleRepository {
  final SharedPrefsService _prefs;
  final MethodChannel _channel;

  BundleRepository(this._prefs)
      : _channel = const MethodChannel(AppConstants.networkStatsChannel);

  DataBundle? get current => _prefs.getDataBundle();

  /// Device-level mobile bytes used since [anchorMs] (hotspot/tethering
  /// included). Returns 0 if the platform can't answer, so status still renders.
  Future<int> _usedSince(int anchorMs) async {
    try {
      final total = await _channel.invokeMethod<int>('getMobileDeviceTotal', {
        'startMs': anchorMs,
        'endMs': DateTime.now().millisecondsSinceEpoch,
      });
      return total ?? 0;
    } on PlatformException {
      return 0;
    }
  }

  /// Average daily device-level mobile usage over the previous up-to-7 completed
  /// days; null when fewer than 3 of those days have usage (no reliable pace).
  /// Mirrors the native worker's `deviceDailyAverage` exactly.
  Future<double?> _dailyAverage() async {
    final todayStart = _startOfToday();
    const dayMs = Duration.millisecondsPerDay;
    final futures = <Future<int>>[];
    for (var i = 1; i <= 7; i++) {
      final dayStart = todayStart - i * dayMs;
      futures.add(_mobileTotal(dayStart, dayStart + dayMs - 1));
    }
    final totals = await Future.wait(futures);
    final used = totals.where((b) => b > 0).toList();
    if (used.length < 3) return null;
    return used.reduce((a, b) => a + b) / used.length;
  }

  Future<int> _mobileTotal(int startMs, int endMs) async {
    try {
      final total = await _channel.invokeMethod<int>('getMobileDeviceTotal', {
        'startMs': startMs,
        'endMs': endMs,
      });
      return total ?? 0;
    } on PlatformException {
      return 0;
    }
  }

  /// Builds a live [BundleStatus] for the current bundle, or null if none.
  Future<BundleStatus?> buildStatus() async {
    final b = current;
    if (b == null) return null;
    final used = await _usedSince(b.anchorAtMs);
    final avg = await _dailyAverage();
    return BundleStatus(
      bundle: b,
      remainingBytes: b.remainingBytes(used),
      dailyAverageBytes: avg,
    );
  }

  /// R4: create a monitored bundle from self-reported details. Tracking starts
  /// now from [currentBalanceBytes]; the bundle expires [validityDays] after
  /// [startDate] (which may be in the past).
  Future<void> saveSelfReport({
    required DateTime startDate,
    required int validityDays,
    required int currentBalanceBytes,
    int? sizeBytes,
  }) async {
    final now = DateTime.now();
    final expiry = DateTime(startDate.year, startDate.month, startDate.day)
        .add(Duration(days: validityDays));
    await _prefs.saveDataBundle(DataBundle(
      anchorBalanceBytes: currentBalanceBytes,
      anchorAtMs: now.millisecondsSinceEpoch,
      expiryMs: expiry.millisecondsSinceEpoch,
      sizeBytes: sizeBytes,
      source: BundleSource.selfReport,
    ));
  }

  /// Manual re-sync: correct the balance from a fresh USSD check, wiping any
  /// accumulated device-vs-carrier drift. Keeps the existing expiry and size.
  Future<void> reSync(int currentBalanceBytes) async {
    final b = current;
    if (b == null) return;
    await _prefs.saveDataBundle(b.copyWith(
      anchorBalanceBytes: currentBalanceBytes,
      anchorAtMs: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  /// Top-up re-anchor (R-Q3): a delivered data purchase adds its size to the
  /// *current remaining* and sets the new expiry — never discarding what was
  /// already left. Idempotent per [reference]. No-op when size/validity can't
  /// be derived from the plan (the user can still self-report).
  Future<void> applyTopUp({
    required String reference,
    required int purchasedSizeBytes,
    required int validityDays,
  }) async {
    if (_prefs.bundleTopUpApplied(reference)) return;
    final now = DateTime.now();
    final b = current;
    var remainingNow = 0;
    if (b != null && !b.isExpired) {
      remainingNow = b.remainingBytes(await _usedSince(b.anchorAtMs));
    }
    final newBalance = remainingNow + purchasedSizeBytes;
    await _prefs.saveDataBundle(DataBundle(
      anchorBalanceBytes: newBalance,
      anchorAtMs: now.millisecondsSinceEpoch,
      expiryMs: now.add(Duration(days: validityDays)).millisecondsSinceEpoch,
      sizeBytes: newBalance, // full at the moment of top-up
      source: BundleSource.purchase,
    ));
    await _prefs.markBundleTopUpApplied(reference);
  }

  Future<void> clear() => _prefs.clearDataBundle();

  int _startOfToday() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day).millisecondsSinceEpoch;
  }
}
