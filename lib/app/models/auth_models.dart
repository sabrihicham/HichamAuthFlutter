import 'user_model.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      errors: json['errors'],
    );
  }
}

class AuthResponse {
  final UserModel user;
  final String token;

  AuthResponse({required this.user, required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user']),
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'user': user.toJson(), 'token': token};
  }
}

class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

class SocialLoginRequest {
  final String accessToken;

  SocialLoginRequest({required this.accessToken});

  Map<String, dynamic> toJson() {
    return {'access_token': accessToken};
  }
}

class SocialProvider {
  final String provider;
  final String name;
  final String icon;
  final String color;

  SocialProvider({
    required this.provider,
    required this.name,
    required this.icon,
    required this.color,
  });

  factory SocialProvider.fromJson(Map<String, dynamic> json) {
    return SocialProvider(
      provider: json['provider'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '',
    );
  }
}

class SocialProvidersResponse {
  final List<SocialProvider> providers;
  final int total;

  SocialProvidersResponse({required this.providers, required this.total});

  factory SocialProvidersResponse.fromJson(Map<String, dynamic> json) {
    return SocialProvidersResponse(
      providers: (json['providers'] as List)
          .map((provider) => SocialProvider.fromJson(provider))
          .toList(),
      total: json['total'] ?? 0,
    );
  }
}

class SocialAuthError {
  final String code;
  final String message;
  final String? provider;

  SocialAuthError({required this.code, required this.message, this.provider});

  factory SocialAuthError.fromJson(Map<String, dynamic> json) {
    return SocialAuthError(
      code: json['error_code'] ?? json['code'] ?? 'UNKNOWN_ERROR',
      message: json['message'] ?? 'حدث خطأ غير متوقع',
      provider: json['provider'],
    );
  }

  // Predefined error codes
  static const String invalidToken = 'INVALID_TOKEN';
  static const String tokenExpired = 'TOKEN_EXPIRED';
  static const String providerNotSupported = 'PROVIDER_NOT_SUPPORTED';
  static const String userNotFound = 'USER_NOT_FOUND';
  static const String emailAlreadyExists = 'EMAIL_ALREADY_EXISTS';
  static const String authenticationFailed = 'AUTHENTICATION_FAILED';

  // Get localized message
  String getLocalizedMessage() {
    switch (code) {
      case invalidToken:
        return 'الرمز المميز غير صالح';
      case tokenExpired:
        return 'انتهت صلاحية الرمز المميز';
      case providerNotSupported:
        return 'مقدم الخدمة غير مدعوم';
      case userNotFound:
        return 'المستخدم غير موجود';
      case emailAlreadyExists:
        return 'البريد الإلكتروني مستخدم بالفعل';
      case authenticationFailed:
        return 'فشل في المصادقة';
      default:
        return message;
    }
  }
}

class GoogleSocialLoginRequest {
  final String accessToken;
  final String idToken;

  GoogleSocialLoginRequest({required this.accessToken, required this.idToken});

  Map<String, dynamic> toJson() {
    return {'access_token': accessToken, 'id_token': idToken};
  }
}

class AppleSocialLoginRequest {
  final String idToken;
  final String rawNonce;
  final String? name;
  final String? email;

  AppleSocialLoginRequest({
    required this.idToken,
    required this.rawNonce,
    this.name,
    this.email,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id_token': idToken,
      'raw_nonce': rawNonce,
    };

    if (name != null) {
      data['name'] = name;
    }
    if (email != null) {
      data['email'] = email;
    }

    return data;
  }
}
