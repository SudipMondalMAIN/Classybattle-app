import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/payment_method.dart';

class PaymentMethodService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<PaymentMethod>> list() async {
    try {
      final res = await _dio.get('/payment-methods');
      return (res.data as List).map((e) => PaymentMethod.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PaymentMethod> createUpi({
    required String accountHolderName,
    required String upiId,
  }) async {
    try {
      final res = await _dio.post('/payment-methods', data: {
        'method_type': 'upi',
        'account_holder_name': accountHolderName,
        'upi_id': upiId,
      });
      return PaymentMethod.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PaymentMethod> createBankAccount({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
  }) async {
    try {
      final res = await _dio.post('/payment-methods', data: {
        'method_type': 'bank_account',
        'account_holder_name': accountHolderName,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
      });
      return PaymentMethod.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> delete(String methodId) async {
    try {
      await _dio.delete('/payment-methods/$methodId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
