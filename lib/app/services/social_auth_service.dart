import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import '../models/auth_models.dart';
import 'api_service.dart';

class SocialAuthService {
  static final ApiService _apiService = ApiService();

  // Configure GoogleSignIn without Firebase
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '249506325762-bhbvkmqpiq18s84pkcr73mnd46ql6gm7.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // Facebook Login
  static Future<ApiResponse<AuthResponse>> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken?.tokenString;
        print('Facebook Access Token: $accessToken');

        // copy to clipboard for testing purposes
        await Clipboard.setData(ClipboardData(text: accessToken ?? ''));

        if (accessToken != null) {
          return await _apiService.loginWithFacebook(accessToken);
        } else {
          return ApiResponse<AuthResponse>(
            success: false,
            message: 'Failed to get Facebook access token',
          );
        }
      } else {
        return ApiResponse<AuthResponse>(
          success: false,
          message: 'Facebook login cancelled or failed: ${result.status}',
        );
      }
    } catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'Facebook login error: $e',
      );
    }
  }

  // دالة للحصول على بيانات المستخدم من Google فقط (بدون إرسال للخادم)
  static Future<Map<String, dynamic>?> getGoogleUserInfo() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;

        return {
          'id': account.id,
          'email': account.email,
          'displayName': account.displayName,
          'photoUrl': account.photoUrl,
          'accessToken': auth.accessToken,
          'idToken': auth.idToken,
        };
      }
      return null;
    } catch (e) {
      debugPrint('خطأ في الحصول على بيانات Google: $e');
      return null;
    }
  }

  // Google Login
  static Future<ApiResponse<AuthResponse>> signInWithGoogle() async {
    try {
      debugPrint('بدء تسجيل الدخول عبر Google...');

      // التأكد من تسجيل الخروج أولاً للحصول على حالة نظيفة
      if (await _googleSignIn.isSignedIn()) {
        debugPrint('المستخدم مسجل دخول بالفعل، جاري تسجيل الخروج...');
        await _googleSignIn.signOut();
      }

      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account != null) {
        debugPrint('تم تسجيل الدخول بنجاح: ${account.email}');

        final GoogleSignInAuthentication auth = await account.authentication;
        final accessToken = auth.accessToken;
        final idToken = auth.idToken;

        debugPrint('Google Access Token: $accessToken');
        debugPrint('Google ID Token: $idToken');

        // نسخ Access Token للحافظة للاختبار
        if (accessToken != null) {
          await Clipboard.setData(ClipboardData(text: accessToken));
          debugPrint('تم نسخ Access Token إلى الحافظة');
        }

        // التحقق من وجود كل من accessToken و idToken
        if (accessToken != null && idToken != null) {
          return await _apiService.loginWithGoogle(accessToken, idToken);
        } else {
          return ApiResponse<AuthResponse>(
            success: false,
            message:
                'فشل في الحصول على Google tokens (access_token أو id_token مفقود)',
          );
        }
      } else {
        debugPrint('تم إلغاء تسجيل الدخول عبر Google');
        return ApiResponse<AuthResponse>(
          success: false,
          message: 'تم إلغاء تسجيل الدخول عبر Google',
        );
      }
    } catch (e) {
      debugPrint('خطأ في تسجيل الدخول عبر Google: $e');
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'خطأ في تسجيل الدخول عبر Google: ${e.toString()}',
      );
    }
  }

  // Get available social providers
  static Future<ApiResponse<SocialProvidersResponse>>
  getSocialProviders() async {
    return await _apiService.getSocialProviders();
  }

  // Apple Sign-In helper methods
  static String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Apple Login
  static Future<ApiResponse<AuthResponse>> signInWithApple() async {
    try {
      debugPrint('بدء تسجيل الدخول عبر Apple...');

      // توليد nonce
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      debugPrint('Generated raw nonce: $rawNonce');
      debugPrint('SHA256 nonce: $nonce');

      // طلب تسجيل الدخول من Apple
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      debugPrint('Apple Sign-In successful');
      debugPrint('User ID: ${credential.userIdentifier}');
      debugPrint('Email: ${credential.email}');
      debugPrint('Given Name: ${credential.givenName}');
      debugPrint('Family Name: ${credential.familyName}');

      // إعداد الاسم إذا كان متوفراً
      String? fullName;
      if (credential.givenName != null && credential.familyName != null) {
        fullName = '${credential.givenName} ${credential.familyName}';
      } else if (credential.givenName != null) {
        fullName = credential.givenName;
      } else if (credential.familyName != null) {
        fullName = credential.familyName;
      }

      // إرسال البيانات إلى الـ Backend
      return await _apiService.loginWithApple(
        credential.identityToken!,
        rawNonce,
        name: fullName,
        email: credential.email,
      );
    } catch (e) {
      debugPrint('خطأ في تسجيل الدخول عبر Apple: $e');
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'خطأ في تسجيل الدخول عبر Apple: ${e.toString()}',
      );
    }
  }

  // Sign out from all social platforms
  static Future<void> signOutAll() async {
    try {
      await FacebookAuth.instance.logOut();

      await _googleSignIn.signOut();

      // Apple doesn't have a programmatic sign out,
      // but we can clear any stored credentials
    } catch (e) {
      debugPrint('Error signing out from social platforms: $e');
    }
  }
}
