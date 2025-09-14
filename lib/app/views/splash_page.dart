import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/social_auth_controller.dart';
import '../routes/app_routes.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade600,
      body: FutureBuilder(
        future: _initializeApp(),
        builder: (context, snapshot) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.security,
                    size: 60,
                    color: Colors.blue.shade600,
                  ),
                ),

                const SizedBox(height: 40),

                // App Title
                Text(
                  'Social Auth',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'تطبيق المصادقة الاجتماعية',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),

                const SizedBox(height: 60),

                // Loading Indicator
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _initializeApp() async {
    final controller = Get.find<SocialAuthController>();

    // Wait for initialization
    await Future.delayed(const Duration(seconds: 2));

    // Check if user is already logged in
    if (controller.isAuthenticated.value) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.emailLogin);
    }
  }
}
