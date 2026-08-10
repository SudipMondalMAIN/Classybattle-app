import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/withdrawal.dart';

class WithdrawalService {
  final Dio _dio = ApiClient.instance.dio;

  Future<WithdrawalRequest> requestWithdrawal({
    required String paymentMethodId,
    required double amount,
  }) async {
    try {
      final res = await _dio.post('/withdrawals', data: {
        'payment_method_id': paymentMethodId,
        'amount': amount,
      });
      return WithdrawalRequest.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<WithdrawalRequest>> myWithdrawals({int page = 1, int pageSize = 20, String? status}) async {
    try {
      final res = await _dio.get('/withdrawals', queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (status != null) 'status': status,
      });
      final items = res.data['items'] as List;
      return items.map((e) => WithdrawalRequest.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<WithdrawalRequest> cancel(String withdrawalId) async {
    try {
      final res = await _dio.post('/withdrawals/$withdrawalId/cancel');
      return WithdrawalRequest.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
