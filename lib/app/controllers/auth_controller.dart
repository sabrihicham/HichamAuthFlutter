import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/auth_models.dart';
import '../services/api_service.dart';
import '../services/social_auth_service.dart';
import '../services/logout_service.dart';
import '../routes/app_routes.dart';

class AuthController extends GetxController {
  final ApiService _apiService = ApiService();

  // Observable variables
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = false.obs;

  // Form controllers for login
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Form controllers for registration
  final TextEditingController registerNameController = TextEditingController();
  final TextEditingController registerEmailController = TextEditingController();
  final TextEditingController registerPasswordController =
      TextEditingController();
  final TextEditingController registerPasswordConfirmController =
      TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _checkAuthStatus();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    registerNameController.dispose();
    registerEmailController.dispose();
    registerPasswordController.dispose();
    registerPasswordConfirmController.dispose();
    super.onClose();
  }

  // Check if user is authenticated
  Future<void> _checkAuthStatus() async {
    await _apiService.initializeToken();
    if (ApiService.getAuthToken() != null) {
      await getProfile();
    }
  }

  // Register new user
  Future<void> register() async {
    // Manual validation without GlobalKey
    if (!_validateRegistrationFields()) return;

    isLoading.value = true;
    try {
      final request = RegisterRequest(
        name: registerNameController.text.trim(),
        email: registerEmailController.text.trim(),
        password: registerPasswordController.text,
        passwordConfirmation: registerPasswordConfirmController.text,
      );

      final response = await _apiService.register(request);

      if (response.success && response.data != null) {
        _showSuccessMessage('تم إنشاء الحساب بنجاح، يمكنك الآن تسجيل الدخول');
        _clearRegistrationFields();
        Get.offAllNamed(AppRoutes.emailLogin);
      } else {
        _showErrorMessage(response.message);
        _handleValidationErrors(response.errors);
      }
    } catch (e) {
      _showErrorMessage('حدث خطأ غير متوقع');
    } finally {
      isLoading.value = false;
    }
  }

  // Login user
  Future<void> login() async {
    // Manual validation without GlobalKey
    if (!_validateLoginFields()) return;

    isLoading.value = true;
    try {
      final request = LoginRequest(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final response = await _apiService.login(request);

      if (response.success && response.data != null) {
        user.value = response.data!.user;
        isLoggedIn.value = true;
        _showSuccessMessage('تم تسجيل الدخول بنجاح');
        _clearLoginFields();
        Get.offAllNamed(AppRoutes.home);
      } else {
        _showErrorMessage(response.message);
        _handleValidationErrors(response.errors);
      }
    } catch (e) {
      _showErrorMessage('حدث خطأ غير متوقع');
    } finally {
      isLoading.value = false;
    }
  }

  // Social Login with Facebook
  Future<void> signInWithFacebook() async {
    isLoading.value = true;
    try {
      final response = await SocialAuthService.signInWithFacebook();
      if (response.success && response.data != null) {
        await _handleSuccessfulAuth(response.data!);
      } else {
        _showErrorMessage(response.message);
      }
    } catch (e) {
      debugPrint('Facebook auth error: $e');
      _showErrorMessage(
        'حدث خطأ أثناء تسجيل الدخول بـ Facebook: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Get user profile
  Future<void> getProfile() async {
    try {
      final response = await _apiService.getProfile();

      if (response.success && response.data != null) {
        user.value = response.data;
        isLoggedIn.value = true;
      } else {
        await logout();
      }
    } catch (e) {
      await logout();
    }
  }

  // Update profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      final response = await _apiService.updateProfile(data);

      if (response.success && response.data != null) {
        user.value = response.data;
        _showSuccessMessage('تم تحديث الملف الشخصي بنجاح');
      } else {
        _showErrorMessage(response.message);
      }
    } catch (e) {
      _showErrorMessage('حدث خطأ أثناء تحديث الملف الشخصي');
    } finally {
      isLoading.value = false;
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
      user.value = null;
      isLoggedIn.value = false;
      
    } finally {
      isLoading.value = false;
    }
  }

  // Helper methods
  Future<void> _handleSuccessfulAuth(AuthResponse authResponse) async {
    user.value = authResponse.user;
    isLoggedIn.value = true;
    ApiService.setAuthToken(authResponse.token);
    _showSuccessMessage('تم تسجيل الدخول بنجاح');
    _clearAllFields();
    Get.offAllNamed(AppRoutes.home);
  }

  void _showSuccessMessage(String message) {
    Get.snackbar(
      'نجح',
      message,
      backgroundColor: Colors.green.withValues(alpha: 0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showErrorMessage(String message) {
    Get.snackbar(
      'خطأ',
      message,
      backgroundColor: Colors.red.withValues(alpha: 0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _handleValidationErrors(Map<String, dynamic>? errors) {
    if (errors != null) {
      errors.forEach((field, messages) {
        if (messages is List) {
          for (String message in messages) {
            _showErrorMessage(message);
          }
        }
      });
    }
  }

  void _clearLoginFields() {
    emailController.clear();
    passwordController.clear();
  }

  void _clearRegistrationFields() {
    registerNameController.clear();
    registerEmailController.clear();
    registerPasswordController.clear();
    registerPasswordConfirmController.clear();
  }

  void _clearAllFields() {
    _clearLoginFields();
    _clearRegistrationFields();
  }

  // Manual validation methods
  bool _validateLoginFields() {
    String? emailError = validateEmail(emailController.text);
    String? passwordError = validatePassword(passwordController.text);

    if (emailError != null) {
      _showErrorMessage(emailError);
      return false;
    }

    if (passwordError != null) {
      _showErrorMessage(passwordError);
      return false;
    }

    return true;
  }

  bool _validateRegistrationFields() {
    String? nameError = validateName(registerNameController.text);
    String? emailError = validateEmail(registerEmailController.text);
    String? passwordError = validatePassword(registerPasswordController.text);
    String? confirmError = validatePasswordConfirmation(
      registerPasswordConfirmController.text,
    );

    if (nameError != null) {
      _showErrorMessage(nameError);
      return false;
    }

    if (emailError != null) {
      _showErrorMessage(emailError);
      return false;
    }

    if (passwordError != null) {
      _showErrorMessage(passwordError);
      return false;
    }

    if (confirmError != null) {
      _showErrorMessage(confirmError);
      return false;
    }

    return true;
  }

  // Validation methods
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    if (!GetUtils.isEmail(value)) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'الاسم مطلوب';
    }
    if (value.length < 2) {
      return 'الاسم يجب أن يكون حرفين على الأقل';
    }
    return null;
  }

  String? validatePasswordConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }
    if (value != registerPasswordController.text) {
      return 'كلمة المرور غير متطابقة';
    }
    return null;
  }
}
