import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/config/build_config.dart';
import '../domain/entities/data_plan.dart';
import '../domain/entities/initiate_result.dart';
import '../domain/entities/network_provider.dart';
import '../domain/entities/purchase_type.dart';

/// Thrown for user-facing Top Up failures with a message safe to display.
class TopUpException implements Exception {
  final String message;
  const TopUpException(this.message);
  @override
  String toString() => message;
}

/// Thin HTTP client for the Top Up Cloudflare Worker. Every call is
/// authenticated with the caller's Firebase (anonymous) ID token; the Worker
/// holds all payment/VTU secrets and re-verifies every payment server-side.
class TopUpApiClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: BuildConfig.topUpApiBaseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  Future<List<DataPlan>> getDataPlans(NetworkProvider network) async {
    try {
      final res = await _dio.get(
        '/data/plans',
        queryParameters: {'network': network.wire},
        options: await _authOptions(),
      );
      final plans = (res.data['plans'] as List)
          .map((e) => DataPlan.fromJson(e as Map<String, dynamic>))
          .toList();
      return plans;
    } on DioException catch (e) {
      throw _mapError(e, 'Couldn\'t load data plans. Please try again.');
    }
  }

  Future<InitiateResult> initiate({
    required PurchaseType type,
    required NetworkProvider network,
    required String phone,
    int? amount,
    String? variationCode,
  }) async {
    try {
      final res = await _dio.post(
        '/purchase/initiate',
        data: {
          'type': type.wire,
          'network': network.wire,
          'phone': phone,
          if (amount != null) 'amount': amount,
          if (variationCode != null) 'variationCode': variationCode,
        },
        options: await _authOptions(),
      );
      return InitiateResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, 'Couldn\'t start your purchase. Please try again.');
    }
  }

  Future<Options> _authOptions() async {
    final token = await _idToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  /// Current Firebase ID token, signing in anonymously first if needed.
  Future<String> _idToken() async {
    var user = FirebaseAuth.instance.currentUser;
    user ??= (await FirebaseAuth.instance.signInAnonymously()).user;
    final token = await user?.getIdToken();
    if (token == null) {
      throw const TopUpException(
          'Couldn\'t verify your device. Check your connection and try again.');
    }
    return token;
  }

  /// Prefers the Worker's `{error}` message when present; otherwise a friendly
  /// fallback keyed to the failure kind.
  TopUpException _mapError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) {
      return TopUpException(data['error'] as String);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const TopUpException(
          'Network problem. Check your connection and try again.');
    }
    return TopUpException(fallback);
  }
}
