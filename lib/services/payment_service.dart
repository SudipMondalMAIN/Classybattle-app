import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/payment.dart';

/// Wraps the user-facing deposit flow in app/api/v1/payment_routes.py.
class PaymentService {
  final Dio _dio = ApiClient.instance.dio;

  /// Merchant UPI id, min/max deposit limits — shown before the user
  /// picks an amount.
  Future<PaymentSettings> getSettings() async {
    try {
      final res = await _dio.get('/payments/settings');
      return PaymentSettings.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Generates a UPI QR payload for the given amount (POST /payments/deposit/qr).
  Future<DepositQuote> generateDepositQr(double amount) async {
    try {
      final res = await _dio.post('/payments/deposit/qr', data: {'amount': amount});
      return DepositQuote.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Submits proof of a completed UPI transfer: the UTR/reference number
  /// plus a screenshot of the payment. `amount` and `utr_number` are sent
  /// as query params and `screenshot` as multipart form data, matching
  /// the FastAPI route signature (mixed Query + File params).
  Future<PaymentRequest> submitDeposit({
    required double amount,
    required String utrNumber,
    required String screenshotPath,
  }) async {
    try {
      final fileName = screenshotPath.split('/').last;
      final formData = FormData.fromMap({
        'screenshot': await MultipartFile.fromFile(screenshotPath, filename: fileName),
      });
      final res = await _dio.post(
        '/payments/deposit',
        queryParameters: {
          'amount': amount.toStringAsFixed(2),
          'utr_number': utrNumber,
        },
        data: formData,
      );
      return PaymentRequest.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<PaymentRequest>> listMyDeposits({int page = 1, int pageSize = 20}) async {
    try {
      final res = await _dio.get('/payments/deposits', queryParameters: {
        'page': page,
        'page_size': pageSize,
      });
      final items = res.data['items'] as List;
      return items.map((e) => PaymentRequest.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
