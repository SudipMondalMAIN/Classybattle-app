import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/payment_method_model.dart';
import 'home_service.dart' show UnauthenticatedException;

class PaymentMethodService {
  PaymentMethodService(this._dio);

  final Dio _dio;

  /// GET /payment-methods -- the user's saved UPI/bank withdrawal
  /// destinations.
  Future<List<PaymentMethodModel>> fetchMethods() async {
    try {
      final res = await _dio.get('/payment-methods');
      final data = res.data as List;
      return data
          .map((e) => PaymentMethodModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// POST /payment-methods -- add a new UPI VPA as a withdrawal
  /// destination.
  Future<PaymentMethodModel> addUpiMethod({
    required String accountHolderName,
    required String upiId,
  }) async {
    try {
      final res = await _dio.post('/payment-methods', data: {
        'method_type': 'upi',
        'account_holder_name': accountHolderName,
        'upi_id': upiId,
      });
      return PaymentMethodModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// POST /payment-methods -- add a bank account as a withdrawal
  /// destination.
  Future<PaymentMethodModel> addBankMethod({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
  }) async {
    try {
      final res = await _dio.post('/payment-methods', data: {
        'method_type': 'bank',
        'account_holder_name': accountHolderName,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
      });
      return PaymentMethodModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// DELETE /payment-methods/{id}
  Future<void> deleteMethod(String id) async {
    try {
      await _dio.delete('/payment-methods/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }
}

final paymentMethodService = PaymentMethodService(ApiClient.instance.dio);
