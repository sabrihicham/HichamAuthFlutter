import 'package:get/get.dart';
import '../views/splash_page.dart';
import '../views/login_page.dart';
import '../views/register_page.dart';
import '../views/home_page.dart';
import '../views/profile_page.dart';

class AppRoutes { 
  static const String splash = '/splash';
  static const String emailLogin = '/email-login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';

  static List<GetPage> routes = [
    GetPage(name: splash, page: () => const SplashPage()),
    GetPage(name: emailLogin, page: () => const EmailLoginPage()),
    GetPage(name: register, page: () => const RegisterPage()),
    GetPage(name: home, page: () => const HomePage()),
    GetPage(name: profile, page: () => const ProfilePage()),
  ];
}
