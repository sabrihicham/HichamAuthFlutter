import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/auth_models.dart';
import '../services/api_service.dart';

class RegisterController extends GetxController {
  final ApiService _apiService = ApiService();

  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController =
      TextEditingController();

  // Form key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Observable variables
  final RxBool isLoading = false.obs;

  bool _isDisposed = false;

  @override
  void onClose() {
    if (_isDisposed) return;

    // Mark as disposed to prevent multiple disposals
    _isDisposed = true;

    // Safely dispose controllers
    try {
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
      passwordConfirmController.dispose();
    } catch (e) {
      // Controllers already disposed or error occurred
      print('Error disposing controllers: $e');
    }

    super.onClose();
  }

  // Register new user
  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final request = RegisterRequest(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        passwordConfirmation: passwordConfirmController.text,
      );

      final response = await _apiService.register(request);

      if (response.success && response.data != null) {
        _showSuccessMessage('تم إنشاء الحساب بنجاح، يمكنك الآن تسجيل الدخول');
        _clearFields();

        // Delay navigation slightly to ensure UI updates complete
        Future.delayed(const Duration(milliseconds: 100), () {
          // Navigate and clean up controller
          Navigator.of(Get.context!).pop();
        });
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
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    passwordConfirmController.clear();
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
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'الاسم مطلوب';
    }
    if (value.length < 2) {
      return 'الاسم يجب أن يكون حرفين على الأقل';
    }
    return null;
  }

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

  String? validatePasswordConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }
    if (value != passwordController.text) {
      return 'كلمة المرور غير متطابقة';
    }
    return null;
  }
}
