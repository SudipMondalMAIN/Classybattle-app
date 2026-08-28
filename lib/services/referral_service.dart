import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/referral_model.dart';
import 'home_service.dart' show UnauthenticatedException;

/// Thrown when applying a referral code fails for a known, user-facing
/// reason (already applied, invalid code, window expired, etc).
class ReferralActionException implements Exception {
  ReferralActionException(this.message);
  final String message;
}

class ReferralService {
  ReferralService(this._dio);

  final Dio _dio;

  /// GET /referrals/my-code -- the "Refer & Earn" screen: the user's own
  /// shareable code plus running totals and next milestone.
  Future<MyReferralCodeModel> fetchMyCode() async {
    try {
      final res = await _dio.get('/referrals/my-code');
      return MyReferralCodeModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// GET /referrals/history -- everyone the current user has referred,
  /// with each one's progress.
  Future<List<ReferralStatusItemModel>> fetchHistory() async {
    try {
      final res = await _dio.get('/referrals/history');
      final data = res.data as List;
      return data
          .map((e) =>
              ReferralStatusItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// POST /referrals/apply -- apply someone else's referral code. Only
  /// allowed once, and only within the admin-configured window from
  /// the caller's own signup date.
  Future<ReferralStatusItemModel> applyCode(
    String code, {
    String? deviceId,
  }) async {
    try {
      final res = await _dio.post(
        '/referrals/apply',
        data: {
          'referral_code': code,
          if (deviceId != null) 'device_id': deviceId,
        },
      );
      return ReferralStatusItemModel.fromJson(
        res.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      final detail = e.response?.data is Map
          ? (e.response?.data as Map)['detail']
          : null;
      throw ReferralActionException(
        detail?.toString() ?? 'Could not apply that referral code.',
      );
    }
  }
}

final referralService = ReferralService(ApiClient.instance.dio);
