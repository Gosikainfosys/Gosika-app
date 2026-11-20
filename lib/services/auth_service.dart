import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn(clientId: kGoogleWebClientId);
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      } catch (_) {}
    }
  }

  Future<({User user, String token})?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kGoogleWebClientId,
        serverClientId: kGoogleWebClientId,
        scopes: <String>['email', 'profile'],
      );

      // Sign out any cached local Google session first to ensure clean OAuth prompt
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled sign-in flow
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String tokenToSend = googleAuth.idToken ?? googleAuth.accessToken ?? '';

      if (tokenToSend.isEmpty) {
        throw 'Failed to obtain Google authentication token. Please try again.';
      }

      Response response;
      try {
        response = await _apiClient.dio.post('/auth/google', data: {
          'id_token': tokenToSend,
          'token': tokenToSend,
          'access_token': googleAuth.accessToken,
          'device_name': 'Flutter',
        });
      } on DioException catch (dioErr) {
        if (dioErr.response?.statusCode == 405 ||
            dioErr.response?.data?.toString().contains('Supported methods: GET') == true) {
          try {
            response = await _apiClient.dio.get('/auth/google', queryParameters: {
              'id_token': tokenToSend,
              'token': tokenToSend,
              'access_token': googleAuth.accessToken,
              'device_name': 'Flutter',
            });
          } on DioException catch (_) {
            response = await _apiClient.dio.post('/auth/google/callback', data: {
              'id_token': tokenToSend,
              'token': tokenToSend,
              'access_token': googleAuth.accessToken,
              'device_name': 'Flutter',
            });
          }
        } else {
          rethrow;
        }
      }

      final data = response.data?['data'] ?? response.data;
      final user = User.fromJson(data['user']);
      final token = (data['token'] ?? data['access_token'] ?? '').toString();

      await _storage.write(key: kTokenKey, value: token);
      return (user: user, token: token);
    } catch (e) {
      if (e is String) rethrow;
      if (e is PlatformException) {
        if (e.code == 'channel-error' ||
            (e.message != null && e.message!.contains('Unable to establish connection'))) {
          throw 'Google Sign-In requires a full app restart. Please stop the app and rebuild/run it.';
        }
        if (e.code == '10' ||
            e.toString().contains('ApiException: 10') ||
            e.toString().contains('DEVELOPER_ERROR')) {
          throw 'Google Sign-In Error (ApiException 10): Ensure Package Name "com.gosika.app" and SHA-1 (80:61:AD:B5:6B:70:93:BF:AC:4A:B3:E3:38:38:6F:D5:A0:14:45:A3) are registered under the Android OAuth Client in Google Cloud Console.';
        }
        throw e.message ?? e.toString();
      }
      throw ApiClient.parseError(e);
    }
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
