import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/wallet.dart';

class WalletService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Wallet> getWallet() async {
    try {
      final res = await _dio.get('/wallet');
      return Wallet.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<WalletTransaction>> transactions({int page = 1, int pageSize = 20}) async {
    try {
      final res = await _dio.get('/wallet/transactions', queryParameters: {
        'page': page,
        'page_size': pageSize,
      });
      final items = res.data['items'] as List;
      return items.map((e) => WalletTransaction.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
