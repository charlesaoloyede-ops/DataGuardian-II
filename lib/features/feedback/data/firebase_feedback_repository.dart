import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../services/storage/shared_prefs_service.dart';
import '../domain/entities/feedback_category.dart';
import '../domain/entities/feedback_submission.dart';
import '../domain/entities/feedback_thread.dart';
import '../domain/i_feedback_repository.dart';

/// Firestore-backed feedback repository.
///
/// Identity is an invisible anonymous auth user (no sign-in, no PII) so the
/// security rules can tie a doc to its install and the app can read its own
/// replies back. Writes are fire-and-forget: Firestore persists to its on-disk
/// cache immediately and syncs when online, so the UI never blocks on the
/// network. See docs/backend/firestore-schema.md.
///
/// Kept dependency-free (resolves [SharedPrefsService] lazily) so it stays a
/// synchronous get_it singleton — depending on the async prefs singleton would
/// make every synchronous consumer (providers, use case) fail with
/// "not ready yet". See the async-DI note in project memory.
@LazySingleton(as: IFeedbackRepository)
class FirebaseFeedbackRepository implements IFeedbackRepository {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('feedback');

  @override
  Future<void> submit({
    required String message,
    required FeedbackCategory category,
    String? email,
  }) async {
    final prefs = await getIt.getAsync<SharedPrefsService>();
    final trimmedEmail = email?.trim();
    final submission = FeedbackSubmission(
      message: message.trim(),
      category: category,
      email: (trimmedEmail == null || trimmedEmail.isEmpty) ? null : trimmedEmail,
      installId: prefs.getOrCreateInstallId(),
      appVersion: AppConstants.appVersion,
      createdAtIso: DateTime.now().toUtc().toIso8601String(),
    );

    final uid = await _uidOrNull();
    if (uid == null) {
      // No identity yet (offline on first launch). Keep it locally; flushed on
      // the next submit once anonymous auth succeeds.
      await prefs.enqueuePendingFeedback(submission.toJson());
      return;
    }

    // Flush anything queued while offline (or by the pre-Firebase stopgap).
    final pending = await prefs.drainPendingFeedback();
    for (final p in pending) {
      unawaited(_write(_toDoc(p, uid)));
    }
    unawaited(_write(_toDoc(submission.toJson(), uid)));
  }

  @override
  Stream<List<FeedbackThread>> watchMyFeedback() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _col.where('uid', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(_toThread).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> _write(Map<String, dynamic> doc) async {
    try {
      await _col.add(doc);
    } catch (e) {
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

  FeedbackThread _toThread(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final reply = d['reply'] as Map<String, dynamic>?;
    return FeedbackThread(
      id: doc.id,
      message: (d['message'] as String?) ?? '',
      category: (d['category'] as String?) ?? 'other',
      status: (d['status'] as String?) ?? 'new',
      createdAt: _asDate(d['createdAt']) ??
          _asIso(d['clientCreatedAt']) ??
          DateTime.now(),
      replyText: reply?['text'] as String?,
      repliedAt: _asDate(reply?['repliedAt']),
    );
  }

  DateTime? _asDate(dynamic v) => v is Timestamp ? v.toDate() : null;
  DateTime? _asIso(dynamic v) => v is String ? DateTime.tryParse(v) : null;
}
