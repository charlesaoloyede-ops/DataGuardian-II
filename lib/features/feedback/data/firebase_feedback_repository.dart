import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/storage/shared_prefs_service.dart';
import '../domain/entities/feedback_category.dart';
import '../domain/entities/feedback_submission.dart';
import '../domain/i_feedback_repository.dart';

/// Writes feedback to the Firestore `feedback` collection.
///
/// Identity is an invisible anonymous auth user (no sign-in, no PII) so the
/// security rules can tie a doc to its install and the app can later read its
/// own reply status. Writes are fire-and-forget: Firestore persists them to its
/// on-disk cache immediately and syncs when online, so the UI never blocks on
/// the network. See docs/backend/firestore-schema.md.
@LazySingleton(as: IFeedbackRepository)
class FirebaseFeedbackRepository implements IFeedbackRepository {
  final SharedPrefsService _prefs;
  FirebaseFeedbackRepository(this._prefs);

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('feedback');

  @override
  Future<void> submit({
    required String message,
    required FeedbackCategory category,
    String? email,
  }) async {
    final trimmedEmail = email?.trim();
    final submission = FeedbackSubmission(
      message: message.trim(),
      category: category,
      email: (trimmedEmail == null || trimmedEmail.isEmpty) ? null : trimmedEmail,
      installId: _prefs.getOrCreateInstallId(),
      appVersion: AppConstants.appVersion,
      createdAtIso: DateTime.now().toUtc().toIso8601String(),
    );

    final uid = await _uidOrNull();
    if (uid == null) {
      // No identity yet (offline on first launch). Keep it locally; it will be
      // flushed on the next submit once anonymous auth succeeds.
      await _prefs.enqueuePendingFeedback(submission.toJson());
      return;
    }

    // Flush anything captured by the local queue (offline first-runs, or the
    // pre-Firebase stopgap) now that we have an identity.
    final pending = await _prefs.drainPendingFeedback();
    for (final p in pending) {
      unawaited(_write(_toDoc(p, uid)));
    }
    unawaited(_write(_toDoc(submission.toJson(), uid)));
  }

  Future<void> _write(Map<String, dynamic> doc) async {
    try {
      await _col.add(doc);
    } catch (e) {
      // Offline writes resolve later via the Firestore cache; only genuine
      // failures (e.g. rules) land here.
      debugPrint('[Feedback] write failed: $e');
    }
  }

  /// Current anonymous uid, signing in if needed. Returns null if sign-in can't
  /// complete (e.g. offline), so the caller can fall back to the local queue.
  Future<String?> _uidOrNull() async {
    final existing = FirebaseAuth.instance.currentUser?.uid;
    if (existing != null) return existing;
    try {
      final cred = await FirebaseAuth.instance
          .signInAnonymously()
          .timeout(const Duration(seconds: 5));
      return cred.user?.uid;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _toDoc(Map<String, dynamic> s, String uid) => {
        'message': s['message'],
        'category': s['category'],
        'email': s['email'],
        'installId': s['installId'],
        'uid': uid,
        'appVersion': s['appVersion'],
        'platform': s['platform'] ?? 'android',
        'osVersion': s['osVersion'],
        'deviceModel': s['deviceModel'],
        'clientCreatedAt': s['createdAtIso'],
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'new',
      };
}
