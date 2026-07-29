/// How a monitored bundle came to exist.
enum BundleSource {
  /// Auto-enrolled from an in-app data purchase (or a top-up that re-anchored
  /// an existing bundle).
  purchase,

  /// Entered by the user for a bundle bought elsewhere (USSD, telco app, agent).
  selfReport,
}

/// A single monitored data bundle.
///
/// A bundle is modelled as an *anchor*, not a fixed countdown: live remaining is
/// [anchorBalanceBytes] minus the device-level mobile data used since
/// [anchorAtMs] (device-level, so hotspot/tethering counts — matching what the
/// carrier bills). Three events re-anchor it (each producing a new record with a
/// fresh [anchorAtMs]):
///   • self-report — the user enters a balance + expiry,
///   • manual re-sync — the user corrects the balance after a USSD check,
///   • top-up — a purchase adds `purchasedSize` to the *current remaining* and
///     sets the new expiry (never discards what was already left).
///
/// Persisted as JSON under the `data_bundle` shared-preferences key, read
/// natively by the background monitor ([MonitorPrefs.readBundle] in Kotlin), so
/// the two stay byte-for-byte in agreement. v1 tracks one active bundle.
class DataBundle {
  /// Balance (bytes) at the moment the bundle was anchored.
  final int anchorBalanceBytes;

  /// Epoch millis the anchor was set. Consumption is measured from here.
  final int anchorAtMs;

  /// Epoch millis the bundle expires (start + validity).
  final int expiryMs;

  /// Nominal full bundle size (bytes) — drives the progress bar only. Optional:
  /// a user who only knows "I have 2 GB left, valid 30 days" can still be
  /// monitored, since the projection anchors on the balance, not the size.
  final int? sizeBytes;

  final BundleSource source;

  const DataBundle({
    required this.anchorBalanceBytes,
    required this.anchorAtMs,
    required this.expiryMs,
    required this.source,
    this.sizeBytes,
  });

  DateTime get anchoredAt => DateTime.fromMillisecondsSinceEpoch(anchorAtMs);
  DateTime get expiry => DateTime.fromMillisecondsSinceEpoch(expiryMs);
  bool get isExpired => DateTime.now().millisecondsSinceEpoch >= expiryMs;

  /// Live remaining bytes given [consumedSinceAnchorBytes] (device-level mobile
  /// usage since [anchorAtMs], supplied by the platform channel). Never negative.
  int remainingBytes(int consumedSinceAnchorBytes) {
    final r = anchorBalanceBytes - consumedSinceAnchorBytes;
    return r < 0 ? 0 : r;
  }

  DataBundle copyWith({
    int? anchorBalanceBytes,
    int? anchorAtMs,
    int? expiryMs,
    int? sizeBytes,
    BundleSource? source,
  }) =>
      DataBundle(
        anchorBalanceBytes: anchorBalanceBytes ?? this.anchorBalanceBytes,
        anchorAtMs: anchorAtMs ?? this.anchorAtMs,
        expiryMs: expiryMs ?? this.expiryMs,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        source: source ?? this.source,
      );

  /// Wire keys mirror the Kotlin reader exactly — do not rename without updating
  /// `MonitorPrefs.readBundle`.
  Map<String, dynamic> toJson() => {
        'anchorBalanceBytes': anchorBalanceBytes,
        'anchorAtMs': anchorAtMs,
        'expiryMs': expiryMs,
        if (sizeBytes != null) 'sizeBytes': sizeBytes,
        'source': source == BundleSource.purchase ? 'purchase' : 'self_report',
      };

  factory DataBundle.fromJson(Map<String, dynamic> json) => DataBundle(
        anchorBalanceBytes: (json['anchorBalanceBytes'] as num).toInt(),
        anchorAtMs: (json['anchorAtMs'] as num).toInt(),
        expiryMs: (json['expiryMs'] as num).toInt(),
        sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
        source: json['source'] == 'purchase'
            ? BundleSource.purchase
            : BundleSource.selfReport,
      );
}
