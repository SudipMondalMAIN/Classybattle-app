import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_exception.dart';
import '../core/token_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/push_notification_handler.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState()) {
    _restoreSession();
  }

  final _authService = AuthService();

  /// Called once at app start. We only know a session *might* exist
  /// (refresh token present) — the profile screen / first authed call
  /// will confirm it's still valid.
  Future<void> _restoreSession() async {
    final hasSession = await TokenStorage.instance.hasSession;
    state = state.copyWith(
      status: hasSession ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.login(email: email, password: password);
      state = state.copyWith(status: AuthStatus.authenticated, user: user, isLoading: false);
      // Best-effort: attach this device's FCM token to the now-authenticated user.
      PushNotificationHandler.instance.registerTokenAfterLogin();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  Future<String?> signupInit({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final msg = await _authService.signupInit(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
      );
      state = state.copyWith(isLoading: false);
      return msg;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return null;
    }
  }

  Future<bool> verifySignupOtp({required String email, required String otp}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.verifySignupOtp(email: email, otp: otp);
      state = state.copyWith(status: AuthStatus.authenticated, user: user, isLoading: false);
      PushNotificationHandler.instance.registerTokenAfterLogin();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  Future<bool> resendOtp({required String email, required String purpose}) async {
    try {
      await _authService.resendOtp(email: email, purpose: purpose);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    await PushNotificationHandler.instance.deregisterCurrentToken();
    await _authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Refetches the current user from GET /users/me. Used by the Profile
  /// screen so stats like avatar/name are live, not just what login returned.
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getMe();
      state = state.copyWith(user: user);
    } on ApiException {
      // Non-fatal — keep whatever user we already have cached.
    }
  }

  Future<bool> updateProfile({String? fullName, String? avatarId, String? bio}) async {
    try {
      final user = await _authService.updateProfile(fullName: fullName, avatarId: avatarId, bio: bio);
      state = state.copyWith(user: user);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});
