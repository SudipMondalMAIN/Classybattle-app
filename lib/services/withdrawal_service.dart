import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/withdrawal_model.dart';
import 'home_service.dart' show UnauthenticatedException;

class WithdrawalService {
  WithdrawalService(this._dio);

  final Dio _dio;

  /// POST /withdrawals -- request a payout against a saved payment
  /// method.
  Future<WithdrawalModel> requestWithdrawal({
    required String paymentMethodId,
    required double amount,
  }) async {
    try {
      final res = await _dio.post('/withdrawals', data: {
        'payment_method_id': paymentMethodId,
        'amount': amount,
      });
      return WithdrawalModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// GET /withdrawals -- the user's own withdrawal history.
  Future<List<WithdrawalModel>> fetchMyWithdrawals({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final res = await _dio.get('/withdrawals', queryParameters: {
        'page': page,
        'page_size': pageSize,
      });
      final items = (res.data['items'] as List)
          .map((e) => WithdrawalModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return items;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }
}

final withdrawalService = WithdrawalService(ApiClient.instance.dio);
