import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiServiceProvider));
});

class AuthState {
  final String? userId;
  final String? token;
  final bool isLoading;
  final String? error;

  AuthState({
    this.userId,
    this.token,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    String? userId,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      userId: userId ?? this.userId,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => userId != null && token != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  AuthNotifier(this._api) : super(AuthState());

  Future<void> requestOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.requestOtp(phone);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> register(String name, String phone, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.register(name, phone, email, password);
      // Auto-login after registration
      final res = await _api.login(email, password);
      state = state.copyWith(
        isLoading: false,
        userId: res['user_id'],
        token: res['token'],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.login(email, password);
      state = state.copyWith(
        isLoading: false,
        userId: res['user_id'],
        token: res['token'],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> googleLogin(String email, String name, String googleId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.googleLogin(email, name, googleId);
      state = state.copyWith(
        isLoading: false,
        userId: res['user_id'],
        token: res['token'],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> verifyOtp(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.verifyOtp(phone, code);
      state = state.copyWith(
        isLoading: false,
        userId: res['user_id'],
        token: res['token'],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void logout() {
    state = AuthState();
  }
}
