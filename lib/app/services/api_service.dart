import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';
import '../models/user_model.dart';
import '../../core/api_config.dart';

class ApiService {
  late final Dio _dio;
  static String? _authToken;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: ApiConfig.defaultHeaders,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
      ),
    );

    // Add interceptor for authentication
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          // Ensure ngrok header is always present
          options.headers['ngrok-skip-browser-warning'] = 'any';
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired, remove token locally without making another API call
            await removeToken();
          }
          handler.next(error);
        },
      ),
    );
  }

  // Set auth token
  static void setAuthToken(String token) {
    _authToken = token;
  }

  // Get auth token
  static String? getAuthToken() {
    return _authToken;
  }

  // Initialize token from storage
  Future<void> initializeToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  // Save token to storage
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    setAuthToken(token);
  }

  // Remove token from storage
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _authToken = null;
  }

  // Convert Laravel API response to our expected format
  Map<String, dynamic> _authResponse(
    Map<String, dynamic> responseData, {
    String? dataKey,
  }) {
    // Handle both 'success' and 'status' fields for backward compatibility
    bool isSuccess =
        responseData['success'] == true ||
        responseData['status'] == 'success' ||
        responseData['status'] == true;

    return {
      'success': isSuccess,
      'message': responseData['message'] ?? '',
      'data': isSuccess && responseData['data'] != null
          ? (dataKey != null
                ? responseData['data'][dataKey]
                : responseData['data'])
          : null,
      'errors': responseData['errors'],
    };
  }

  // Convert social auth response specifically
  Map<String, dynamic> _socialAuthResponse(Map<String, dynamic> responseData) {
    bool isSuccess =
        responseData['success'] == true ||
        responseData['status'] == 'success' ||
        responseData['status'] == true;

    // Debug logging
    print('Social Auth Response: $responseData');
    print('Is Success: $isSuccess');

    Map<String, dynamic> convertedData = {
      'success': isSuccess,
      'message': responseData['message'] ?? '',
      'data': null,
      'errors': responseData['errors'],
    };

    // Handle successful social auth response
    if (isSuccess && responseData['data'] != null) {
      final data = responseData['data'];

      print('User data: ${data['user']}');
      print('Token data: ${data['token']}');

      convertedData['data'] = {
        'user': data['user'],
        'token': data['token'], // Use 'token' directly from PHP response
      };
    } else if (!isSuccess) {
      print('Social auth failed: ${responseData['message']}');
      print('Errors: ${responseData['errors']}');
    }

    return convertedData;
  }

  // Register user
  Future<ApiResponse<AuthResponse>> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.register,
        data: request.toJson(),
      );

      final responseData = response.data;

      // Convert Laravel API response structure to our expected format
      final convertedData = _authResponse(responseData);

      // Transform auth data structure
      if (convertedData['success'] && convertedData['data'] != null) {
        convertedData['data'] = {
          'user': convertedData['data']['user'],
          'token': convertedData['data']['access_token'],
        };
      }

      final apiResponse = ApiResponse<AuthResponse>.fromJson(
        convertedData,
        (json) => AuthResponse.fromJson(json),
      );

      if (apiResponse.success && apiResponse.data != null) {
        await saveToken(apiResponse.data!.token);
      }

      return apiResponse;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Login user
  Future<ApiResponse<AuthResponse>> login(LoginRequest request) async {
    try {
      final response = await _dio.post(ApiConfig.login, data: request.toJson());

      final responseData = response.data;

      // Convert Laravel API response structure to our expected format
      final convertedData = _authResponse(responseData);

      // Transform auth data structure
      if (convertedData['success'] && convertedData['data'] != null) {
        convertedData['data'] = {
          'user': convertedData['data']['user'],
          'token': convertedData['data']['access_token'],
        };
      }

      final apiResponse = ApiResponse<AuthResponse>.fromJson(
        convertedData,
        (json) => AuthResponse.fromJson(json),
      );

      if (apiResponse.success && apiResponse.data != null) {
        await saveToken(apiResponse.data!.token);
      }

      return apiResponse;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Get available social providers
  Future<ApiResponse<SocialProvidersResponse>> getSocialProviders() async {
    try {
      final response = await _dio.get(ApiConfig.socialProviders);
      return ApiResponse<SocialProvidersResponse>.fromJson(
        response.data,
        (json) => SocialProvidersResponse.fromJson(json),
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Social login - Facebook
  Future<ApiResponse<AuthResponse>> loginWithFacebook(
    String accessToken,
  ) async {
    try {
      // Validate access token
      if (!_isValidAccessToken(accessToken)) {
        return ApiResponse<AuthResponse>(
          success: false,
          message: 'رمز الوصول غير صالح',
        );
      }

      final response = await _dio.post(
        ApiConfig.socialFacebook,
        data: {'access_token': accessToken},
      );

      final responseData = response.data;

      // Convert social auth response structure to our expected format
      final convertedData = _socialAuthResponse(responseData);

      final apiResponse = ApiResponse<AuthResponse>.fromJson(
        convertedData,
        (json) => AuthResponse.fromJson(json),
      );

      if (apiResponse.success && apiResponse.data != null) {
        await saveToken(apiResponse.data!.token);
      }

      return apiResponse;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Social login - Google
  Future<ApiResponse<AuthResponse>> loginWithGoogle(
    String accessToken,
    String idToken,
  ) async {
    try {
      // Validate tokens
      if (!_isValidAccessToken(accessToken)) {
        return ApiResponse<AuthResponse>(
          success: false,
          message: 'رمز الوصول من Google غير صالح',
        );
      }

      if (!_isValidGoogleIdToken(idToken)) {
        return ApiResponse<AuthResponse>(
          success: false,
          message: 'رمز التعريف من Google غير صالح',
        );
      }

      final request = GoogleSocialLoginRequest(
        accessToken: accessToken,
        idToken: idToken,
      );

      final response = await _dio.post(
        ApiConfig.socialGoogle,
        data: request.toJson(),
      );

      final responseData = response.data;

      // Convert social auth response structure to our expected format
      final convertedData = _socialAuthResponse(responseData);

      final apiResponse = ApiResponse<AuthResponse>.fromJson(
        convertedData,
        (json) => AuthResponse.fromJson(json),
      );

      if (apiResponse.success && apiResponse.data != null) {
        await saveToken(apiResponse.data!.token);
      }

      return apiResponse;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Social login - Apple
  Future<ApiResponse<AuthResponse>> loginWithApple(
    String idToken,
    String rawNonce, {
    String? name,
    String? email,
  }) async {
    try {
      print('Apple Login Request:');
      print('ID Token: $idToken');
      print('Raw Nonce: $rawNonce');
      print('Name: $name');
      print('Email: $email');

      final request = AppleSocialLoginRequest(
        idToken: idToken,
        rawNonce: rawNonce,
        name: name,
        email: email,
      );

      final response = await _dio.post(
        ApiConfig.socialApple,
        data: request.toJson(),
      );

      final responseData = response.data;

      // Convert social auth response structure to our expected format
      final convertedData = _socialAuthResponse(responseData);

      final apiResponse = ApiResponse<AuthResponse>.fromJson(
        convertedData,
        (json) => AuthResponse.fromJson(json),
      );

      if (apiResponse.success && apiResponse.data != null) {
        await saveToken(apiResponse.data!.token);
      }

      return apiResponse;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Generic social login method
  Future<ApiResponse<AuthResponse>> socialLogin({
    required String provider,
    required String accessToken,
    String? idToken,
  }) async {
    try {
      Map<String, dynamic> requestData = {'access_token': accessToken};

      // Add id_token for Google
      if (provider == 'google' && idToken != null) {
        requestData['id_token'] = idToken;
      }

      final response = await _dio.post(
        ApiConfig.getSocialLoginEndpoint(provider),
        data: requestData,
      );

      final responseData = response.data;

      // Convert social auth response structure to our expected format
      final convertedData = _socialAuthResponse(responseData);

      final apiResponse = ApiResponse<AuthResponse>.fromJson(
        convertedData,
        (json) => AuthResponse.fromJson(json),
      );

      if (apiResponse.success && apiResponse.data != null) {
        await saveToken(apiResponse.data!.token);
      }

      return apiResponse;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Get user profile from social auth endpoint
  Future<ApiResponse<UserModel>> getSocialProfile() async {
    try {
      final response = await _dio.get(ApiConfig.socialProfile);
      final convertedData = _authResponse(response.data, dataKey: 'user');

      return ApiResponse<UserModel>.fromJson(
        convertedData,
        (json) => UserModel.fromJson(json),
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Logout from all devices (including social providers)
  Future<ApiResponse<dynamic>> logoutAll() async {
    try {
      final response = await _dio.post(ApiConfig.socialLogoutAll);

      final convertedData = _authResponse(response.data);
      convertedData['data'] = null; // No data expected for logout operation

      await removeToken();
      return ApiResponse<dynamic>.fromJson(convertedData, null);
    } on DioException catch (e) {
      await removeToken(); // Remove token even if request fails
      return _handleDioError(e);
    }
  }

  // Delete account (including social provider connections)
  Future<ApiResponse<dynamic>> deleteSocialAccount() async {
    try {
      final response = await _dio.delete(ApiConfig.socialDeleteAccount);

      final convertedData = _authResponse(response.data);
      convertedData['data'] = null; // No data expected for delete operation

      await removeToken();
      return ApiResponse<dynamic>.fromJson(convertedData, null);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Get user profile
  Future<ApiResponse<UserModel>> getProfile() async {
    try {
      final response = await _dio.get(ApiConfig.getUser);
      final convertedData = _authResponse(response.data, dataKey: 'user');

      return ApiResponse<UserModel>.fromJson(
        convertedData,
        (json) => UserModel.fromJson(json),
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Update profile
  Future<ApiResponse<UserModel>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(ApiConfig.updateProfile, data: data);
      final convertedData = _authResponse(response.data, dataKey: 'user');

      return ApiResponse<UserModel>.fromJson(
        convertedData,
        (json) => UserModel.fromJson(json),
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Delete account
  Future<ApiResponse<dynamic>> deleteAccount(String password) async {
    try {
      final response = await _dio.delete(
        ApiConfig.deleteAccount,
        data: {'password': password},
      );

      final convertedData = _authResponse(response.data);
      convertedData['data'] = null; // No data expected for delete operation

      await removeToken();
      return ApiResponse<dynamic>.fromJson(convertedData, null);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Logout current device
  Future<ApiResponse<dynamic>> logout() async {
    try {
      final response = await _dio.post(ApiConfig.logout);

      final convertedData = _authResponse(response.data);
      convertedData['data'] = null; // No data expected for logout operation

      await removeToken();
      return ApiResponse<dynamic>.fromJson(convertedData, null);
    } on DioException catch (e) {
      await removeToken(); // Remove token even if request fails
      return _handleDioError(e);
    }
  }

  // Test API connection
  Future<ApiResponse<dynamic>> testAPI() async {
    try {
      final response = await _dio.get(ApiConfig.test);
      return ApiResponse<dynamic>.fromJson(response.data, null);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Get protected data (example endpoint)
  Future<ApiResponse<dynamic>> getProtectedData() async {
    try {
      final response = await _dio.get(ApiConfig.protectedData);
      return ApiResponse<dynamic>.fromJson(response.data, null);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Validate access token before sending to server
  bool _isValidAccessToken(String token) {
    return token.isNotEmpty && token.length > 10;
  }

  // Validate JWT token format
  bool _isValidJWTToken(String token) {
    return token.split('.').length == 3;
  }

  // Validate Google ID token
  bool _isValidGoogleIdToken(String idToken) {
    if (!_isValidJWTToken(idToken)) return false;

    try {
      // Decode payload to check basic structure
      final parts = idToken.split('.');
      final payload = Uri.decodeFull(parts[1]);
      // Additional validation can be added here
      return payload.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Handle Dio errors
  ApiResponse<T> _handleDioError<T>(DioException e) {
    String message = 'حدث خطأ غير متوقع';
    Map<String, dynamic>? errors;

    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        // Handle different Laravel API error structures
        if (data['success'] == false) {
          message = data['message'] ?? message;
          errors = data['errors'];

          // Handle specific social auth errors
          if (data['error_code'] != null) {}
        } else if (data['status'] == 'error') {
          message = data['message'] ?? message;
          errors = data['errors'];
        } else {
          message = data['message'] ?? message;
          errors = data['errors'];
        }
      }
    } else {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'انتهت مهلة الاتصال';
          break;
        case DioExceptionType.connectionError:
          message = 'خطأ في الاتصال بالإنترنت';
          break;
        default:
          message = 'حدث خطأ غير متوقع';
      }
    }

    return ApiResponse<T>(success: false, message: message, errors: errors);
  }
}
