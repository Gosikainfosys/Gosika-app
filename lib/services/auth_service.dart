import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService(this._apiClient);

  Future<({User user, String token})> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'identifier': identifier,
        'password': password,
        'device_name': 'Flutter',
      });

      final data = response.data['data'];
      final user = User.fromJson(data['user']);
      final token = data['token'].toString();

      await _storage.write(key: kTokenKey, value: token);
      return (user: user, token: token);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<({User? user, String? token})> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiClient.dio.post('/auth/register', data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

      final data = response.data?['data'];
      User? user;
      String? token;

      if (data != null) {
        if (data['user'] != null) {
          user = User.fromJson(data['user']);
        }
        if (data['token'] != null) {
          token = data['token'].toString();
          await _storage.write(key: kTokenKey, value: token);
        }
      }

      return (user: user, token: token);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<User?> getMe() async {
    final token = await _storage.read(key: kTokenKey);
    if (token == null) return null;

    try {
      final response = await _apiClient.dio.get('/auth/me');
      return User.fromJson(response.data['data']);
    } catch (e) {
      await logout();
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } catch (_) {
    } finally {
      await _storage.delete(key: kTokenKey);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final origin = kBaseUrl.replaceFirst('/api/v1', '');
      final url = Uri.parse('$origin/api/v1/auth/google/redirect');
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw 'Could not launch Google Sign-In';
      }
    } catch (e) {
      if (e is String) rethrow;
      throw ApiClient.parseError(e);
    }
  }

  Future<void> handleSocialToken(String token) async {
    await _storage.write(key: kTokenKey, value: token);
  }

  Future<String> forgotPassword(String email) async {
    try {
      final response = await _apiClient.dio.post('/auth/forgot-password', data: {
        'email': email,
      });
      return response.data?['message']?.toString() ??
          'Password reset link sent to your email!';
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<({User? user, String? token})> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _apiClient.dio.post('/auth/email/verify', data: {
        'email': email,
        'code': code,
      });

      final data = response.data?['data'];
      User? user;
      String? token;

      if (data != null) {
        if (data['user'] != null) {
          user = User.fromJson(data['user']);
        }
        if (data['token'] != null) {
          token = data['token'].toString();
          await _storage.write(key: kTokenKey, value: token);
        }
      }

      return (user: user, token: token);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> resendEmailVerification(String email) async {
    try {
      await _apiClient.dio.post('/auth/email/resend', data: {'email': email});
    } catch (_) {
      try {
        await _apiClient.dio.post('/auth/email/send', data: {'email': email});
      } catch (e) {
        throw ApiClient.parseError(e);
      }
    }
  }

  Future<void> sendPhoneOtp() async {
    try {
      await _apiClient.dio.post('/auth/phone/otp');
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<({User? user, String? token})> verifyPhoneOtp(String code) async {
    try {
      final response = await _apiClient.dio.post('/auth/phone/verify', data: {'code': code});
      final data = response.data?['data'];
      User? user;
      String? token;

      if (data != null) {
        if (data['user'] != null) {
          user = User.fromJson(data['user']);
        }
        if (data['token'] != null) {
          token = data['token'].toString();
          await _storage.write(key: kTokenKey, value: token);
        }
      }

      return (user: user, token: token);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
