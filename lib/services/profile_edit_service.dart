import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/user_model.dart';
import 'home_service.dart' show UnauthenticatedException;

/// PATCH /users/me -- mirrors app/schemas/user.py -> UserProfileUpdate.
class ProfileEditService {
  ProfileEditService(this._dio);

  final Dio _dio;

  static const List<String> validAvatarIds = [
    'avatar_1',
    'avatar_2',
    'avatar_3',
    'avatar_4',
    'avatar_5',
    'avatar_6',
  ];

  Future<UserModel> updateProfile({
    String? fullName,
    String? avatarId,
    String? bio,
  }) async {
    try {
      final res = await _dio.patch(
        '/users/me',
        data: {
          if (fullName != null) 'full_name': fullName,
          if (avatarId != null) 'avatar_id': avatarId,
          if (bio != null) 'bio': bio,
        },
      );
      return UserModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthenticatedException();
      rethrow;
    }
  }
}

final profileEditService = ProfileEditService(ApiClient.instance.dio);
