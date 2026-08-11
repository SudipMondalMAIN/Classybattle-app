import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/banner.dart';

class BannerService {
  final Dio _dio = ApiClient.instance.dio;

  /// Public: active home-screen promo banners, already sorted by backend.
  Future<List<PromoBanner>> listActive() async {
    try {
      final res = await _dio.get('/banners');
      final items = res.data as List;
      return items.map((e) => PromoBanner.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}