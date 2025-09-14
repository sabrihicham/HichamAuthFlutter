import 'package:get/get.dart';
import '../models/auth_models.dart';
import '../models/user_model.dart';
import '../services/social_auth_service.dart';
import '../services/api_service.dart';
import '../services/logout_service.dart';

class SocialAuthController extends GetxController {
  final ApiService _apiService = ApiService();

  var isLoading = false.obs;
  var availableProviders = <SocialProvider>[].obs;
  var currentUser = Rxn<UserModel>();
  var isAuthenticated = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeAuth();
    loadSocialProviders();
  }

  Future<void> _initializeAuth() async {
    await _apiService.initializeToken();
    isAuthenticated.value = ApiService.getAuthToken() != null;
    if (isAuthenticated.value) {
      await loadUserProfile();
    }
  }

  // Load available social providers
  Future<void> loadSocialProviders() async {
    try {
      isLoading.value = true;
      final response = await SocialAuthService.getSocialProviders();

      if (response.success && response.data != null) {
        availableProviders.value = response.data!.providers;
      } else {
        Get.snackbar(
          'خطأ',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحميل مقدمي الخدمة الاجتماعية',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Facebook login
  Future<void> signInWithFacebook() async {
    try {
      isLoading.value = true;
      final response = await SocialAuthService.signInWithFacebook();

      if (response.success && response.data != null) {
        currentUser.value = response.data!.user;
        isAuthenticated.value = true;

        Get.snackbar(
          'نجح',
          'تم تسجيل الدخول بنجاح',
          snackPosition: SnackPosition.BOTTOM,
        );

        // Navigate to home or dashboard
        Get.offAllNamed('/home');
      } else {
        Get.snackbar(
          'خطأ',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل تسجيل الدخول بـ Facebook',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Google login
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      final response = await SocialAuthService.signInWithGoogle();

      if (response.success && response.data != null) {
        currentUser.value = response.data!.user;
        isAuthenticated.value = true;

        Get.snackbar(
          'نجح',
          'تم تسجيل الدخول بنجاح',
          snackPosition: SnackPosition.BOTTOM,
        );

        // Navigate to home or dashboard
        Get.offAllNamed('/home');
      } else {
        Get.snackbar(
          'خطأ',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل تسجيل الدخول بـ Google',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Apple login
  Future<void> signInWithApple() async {
    try {
      isLoading.value = true;
      final response = await SocialAuthService.signInWithApple();

      if (response.success && response.data != null) {
        currentUser.value = response.data!.user;
        isAuthenticated.value = true;

        Get.snackbar(
          'نجح',
          'تم تسجيل الدخول بنجاح',
          snackPosition: SnackPosition.BOTTOM,
        );

        // Navigate to home or dashboard
        Get.offAllNamed('/home');
      } else {
        Get.snackbar(
          'خطأ',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل تسجيل الدخول بـ Apple',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load user profile
  Future<void> loadUserProfile() async {
    try {
      final response = await _apiService.getProfile();

      if (response.success && response.data != null) {
        currentUser.value = response.data;
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    isLoading.value = true;
    try {
      await LogoutService.logout(
        successMessage: 'تم تسجيل الخروج بنجاح',
        errorMessage: 'فشل في تسجيل الخروج',
      );
      currentUser.value = null;
      isAuthenticated.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      isLoading.value = true;

      final response = await _apiService.deleteAccount('');

      if (response.success) {
        // تسجيل الخروج من الخادم
        await _apiService.logout();

        // تسجيل الخروج من جميع منصات التواصل الاجتماعي
        await SocialAuthService.signOutAll();
      } else {
        Get.snackbar(
          'خطأ',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في حذف الحساب',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
