import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/controllers/auth_controller.dart';
import 'app/controllers/social_auth_controller.dart';
import 'app/routes/app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize Controllers
    Get.put(AuthController());
    Get.put(SocialAuthController());

    return GetMaterialApp(
      title: 'Social Auth Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Cairo', // يمكنك تغييرها للخط العربي المفضل لك
      ),
      initialRoute: AppRoutes.emailLogin,
      getPages: AppRoutes.routes,
      locale: const Locale('ar', 'SA'), // اللغة العربية
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}
