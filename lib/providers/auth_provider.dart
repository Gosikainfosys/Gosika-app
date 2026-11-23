import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

final apiClientProvider = Provider((ref) => ApiClient());

final authServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({User? user, bool? isLoading, String? error, bool clearError = false}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final AppLinks _appLinks = AppLinks();

  AuthNotifier(this._authService) : super(AuthState(isLoading: true)) {
    checkAuth();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks.uriLinkStream.listen((uri) async {
      if (uri.host == 'social-auth') {
        final token = uri.queryParameters['token'];
        if (token != null && token.isNotEmpty) {
          await handleSocialToken(token);
        }
      }
    });

    _appLinks.getInitialLink().then((uri) async {
      if (uri != null && uri.host == 'social-auth') {
        final token = uri.queryParameters['token'];
        if (token != null && token.isNotEmpty) {
          await handleSocialToken(token);
        }
      }
    });
  }

  Future<void> handleSocialToken(String token) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.handleSocialToken(token);
      final user = await _authService.getMe();
      state = AuthState(user: user, isLoading: false);
    } catch (e) {
      state = AuthState(
        user: null,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final user = await _authService.getMe();
    state = AuthState(user: user, isLoading: false);
  }

  void setUser(User? user) {
    state = AuthState(user: user, isLoading: false);
  }

  Future<void> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.login(
        identifier: identifier,
        password: password,
      );
      state = AuthState(user: result.user, isLoading: false);
    } catch (e) {
      state = AuthState(
        user: null,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.signInWithGoogle();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = AuthState(
        user: state.user,
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authService.logout();
    state = AuthState(user: null, isLoading: false);
  }
}
