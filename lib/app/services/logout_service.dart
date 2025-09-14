import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import 'api_service.dart';
import 'social_auth_service.dart';

/// خدمة مركزية لتسجيل الخروج في التطبيق
/// تتعامل مع جميع عمليات تسجيل الخروج من مكان واحد
class LogoutService {
  static final ApiService _apiService = ApiService();

  /// دالة تسجيل الخروج الموحدة للتطبيق
  /// تقوم بـ:
  /// 1. استدعاء API لتسجيل الخروج من الخادم
  /// 2. تسجيل الخروج من جميع منصات التواصل الاجتماعي
  /// 3. مسح البيانات المحلية
  /// 4. إظهار رسالة نجاح أو خطأ
  /// 5. التنقل إلى صفحة تسجيل الدخول
  static Future<void> logout({
    String? successMessage = 'تم تسجيل الخروج بنجاح',
    String? errorMessage = 'حدث خطأ أثناء تسجيل الخروج',
    String? routeName,
    Function(String)? onError,
    Function(String)? onSuccess,
  }) async {
    try {


      // إظهار رسالة النجاح
      if (successMessage != null) {
        if (onSuccess != null) {
          onSuccess(successMessage);
        } else {
          _showSuccessMessage(successMessage);
        }
      }

      // التنقل إلى صفحة تسجيل الدخول
      final route = routeName ?? AppRoutes.emailLogin;
      Get.offAllNamed(route);
    } catch (e) {
      // إظهار رسالة الخطأ
      if (errorMessage != null) {
        if (onError != null) {
          onError(errorMessage);
        } else {
          _showErrorMessage(errorMessage);
        }
      }
      rethrow;
    }
  }

  /// دالة تسجيل خروج سريعة بدون رسائل
  static Future<void> silentLogout({String? routeName}) async {
    try {
      await _apiService.logout();
      await SocialAuthService.signOutAll();

      final route = routeName ?? AppRoutes.emailLogin;
      Get.offAllNamed(route);
    } catch (e) {
      // تجاهل الأخطاء في التسجيل الصامت
    }
  }

  /// إظهار رسالة النجاح الافتراضية
  static void _showSuccessMessage(String message) {
    Get.snackbar(
      'نجح',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.primaryColor,
      colorText: Get.theme.colorScheme.onPrimary,
    );
  }

  /// إظهار رسالة الخطأ الافتراضية
  static void _showErrorMessage(String message) {
    Get.snackbar(
      'خطأ',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
  }

  /// دالة مساعدة لتسجيل الخروج مع تأكيد
  static Future<void> logoutWithConfirmation({
    required BuildContext context,
    String title = 'تسجيل الخروج',
    String content = 'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
    String confirmText = 'تسجيل الخروج',
    String cancelText = 'إلغاء',
    Function(String)? onSuccess,
    Function(String)? onError,
  }) async {
    final bool? shouldLogout = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await logout(onSuccess: onSuccess, onError: onError);
    }
  }
}
