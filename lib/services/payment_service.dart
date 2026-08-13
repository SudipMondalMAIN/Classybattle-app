import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/deposit_model.dart';
import 'home_service.dart' show UnauthenticatedException;

class PaymentService {
  PaymentService(this._dio);

  final Dio _dio;

  /// GET /payments/settings -- min/max deposit limits + whether UPI
  /// deposits are currently enabled.
  Future<PaymentSettingsModel> fetchSettings() async {
    try {
      final res = await _dio.get('/payments/settings');
      return PaymentSettingsModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// POST /payments/deposit/qr -- backend builds the real
  /// upi://pay?pa=...&am=...&cu=INR URI for the configured merchant
  /// UPI ID, ready to render as a QR code.
  Future<DepositQrModel> generateDepositQr(double amount) async {
    try {
      final res = await _dio.post('/payments/deposit/qr', data: {
        'amount': amount,
      });
      return DepositQrModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }

  /// POST /payments/deposit -- submit proof of payment (UTR + payment
  /// screenshot) for admin verification.
  Future<void> submitDeposit({
    required double amount,
    required String utrNumber,
    required File screenshot,
  }) async {
    try {
      final fileName = screenshot.path.split('/').last;
      final formData = FormData.fromMap({
        'screenshot': await MultipartFile.fromFile(
          screenshot.path,
          filename: fileName,
        ),
      });
      await _dio.post(
        '/payments/deposit',
        data: formData,
        queryParameters: {
          'amount': amount.toStringAsFixed(2),
          'utr_number': utrNumber,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }
}

final paymentService = PaymentService(ApiClient.instance.dio);
