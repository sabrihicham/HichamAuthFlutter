import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/auth_models.dart';
import '../services/api_service.dart';
import '../routes/app_routes.dart';
import 'auth_controller.dart';

class LoginController extends GetxController {
  final ApiService _apiService = ApiService();

  // Form controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Form key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Observable variables
  final RxBool isLoading = false.obs;

  @override
  void onClose() {
    // Safely dispose controllers
    try {
      emailController.dispose();
      passwordController.dispose();
    } catch (e) {
      // Controllers already disposed
    }
    super.onClose();
  }

  // Login user
  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final request = LoginRequest(
        email: emailController.text.trim(),
        password: passwordController.text,
      ); 

      final response = await _apiService.login(request);

      if (response.success && response.data != null) {
        // Update main auth controller
        final AuthController authController = Get.find<AuthController>();
        authController.user.value = response.data!.user;
        authController.isLoggedIn.value = true;

        _showSuccessMessage('تم تسجيل الدخول بنجاح');
        _clearFields();
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

  void _clearFields() {
    emailController.clear();
    passwordController.clear();
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
}
