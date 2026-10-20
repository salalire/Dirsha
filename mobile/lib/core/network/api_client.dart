import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import 'auth_interceptor.dart';

/// Central HTTP client for all Dirsha API requests.
///
/// Wraps Dio and provides:
/// - A single configured [Dio] instance.
/// - Automatic Bearer token injection via [AuthInterceptor].
/// - Consistent error mapping to [AppException] subtypes.
/// - No networking logic in presentation code.
///
/// All repository classes use this client — they do not create their own
/// Dio instances.
///
/// Important: Never log request/response bodies that may contain tokens,
/// passwords, or sensitive financial data.  The logging interceptor below
/// is active only in non-production builds and redacts the Authorization
/// header.
class ApiClient {
  ApiClient({
    required FlutterSecureStorage storage,
    required void Function() onUnauthenticated,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Do not follow redirects automatically for API calls.
        followRedirects: false,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    _authInterceptor = AuthInterceptor(
      storage: storage,
      dio: _dio,
      onUnauthenticated: onUnauthenticated,
    );

    _dio.interceptors.add(_authInterceptor);

    // Developer log interceptor — redacts Authorization value, disabled in
    // production to avoid leaking tokens or response bodies to log streams.
    if (!AppConfig.isProduction) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // Redact Authorization header before any logging occurs.
            final safeHeaders = Map<String, dynamic>.from(options.headers);
            if (safeHeaders.containsKey('Authorization')) {
              safeHeaders['Authorization'] = '[redacted]';
            }
            handler.next(options);
          },
        ),
      );
    }
  }

  late final Dio _dio;
  late final AuthInterceptor _authInterceptor;

  /// Exposes the auth interceptor so repositories can call [saveTokens] and
  /// [clearTokens] after sign-in / sign-out.
  AuthInterceptor get auth => _authInterceptor;

  // ---------------------------------------------------------------------------
  // HTTP verbs — all return typed response data or throw [AppException]
  // ---------------------------------------------------------------------------

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _execute(
      () =>
          _dio.get<T>(path, queryParameters: queryParameters, options: options),
    );
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _execute(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<T> put<T>(String path, {Object? data, Options? options}) async {
    return _execute(() => _dio.put<T>(path, data: data, options: options));
  }

  Future<T> patch<T>(String path, {Object? data, Options? options}) async {
    return _execute(() => _dio.patch<T>(path, data: data, options: options));
  }

  Future<T> delete<T>(String path, {Object? data, Options? options}) async {
    return _execute(() => _dio.delete<T>(path, data: data, options: options));
  }

  // ---------------------------------------------------------------------------
  // Error mapping
  // ---------------------------------------------------------------------------

  Future<T> _execute<T>(Future<Response<T>> Function() call) async {
    try {
      final response = await call();
      // Dio validates status in BaseOptions.validateStatus; if we reach here
      // the status is 2xx and response.data is the parsed body.
      return response.data as T;
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw ParseException(
        message: 'Unexpected error processing the response.',
        cause: e,
      );
    }
  }

  AppException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        return _mapHttpError(e.response);

      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request was cancelled.');

      case DioExceptionType.unknown:
      default:
        // Could be a socket exception, TLS error, etc.
        return const NetworkException(
          message: 'Could not reach the server. Check your connection.',
        );
    }
  }

  AppException _mapHttpError(Response<dynamic>? response) {
    if (response == null) return const NetworkException();

    final status = response.statusCode ?? 0;
    final body = response.data;

    // Extract human-readable message from the agreed error response shape:
    // { "message": "...", "error": "ERROR_CODE", "statusCode": 400 }
    final serverMessage = _extractMessage(body);
    final errorCode = _extractErrorCode(body);

    switch (status) {
      case 400:
        final fieldErrors = _extractFieldErrors(body);
        return ValidationException(
          message: serverMessage ?? 'The request contained invalid data.',
          fieldErrors: fieldErrors,
        );
      case 401:
        return const UnauthorizedException();
      case 403:
        return const ForbiddenException();
      case 404:
        return const NotFoundException();
      case 409:
        return ApiException(
          statusCode: status,
          message:
              serverMessage ?? 'A conflict occurred with the current state.',
          errorCode: errorCode,
        );
      case 422:
        return ValidationException(
          message: serverMessage ?? 'The data provided could not be processed.',
          fieldErrors: _extractFieldErrors(body),
        );
      case >= 500:
        return ApiException(
          statusCode: status,
          message: 'The server encountered an error. Please try again later.',
          errorCode: errorCode,
        );
      default:
        return ApiException(
          statusCode: status,
          message: serverMessage ?? 'An unexpected error occurred.',
          errorCode: errorCode,
          serverMessage: serverMessage,
        );
    }
  }

  String? _extractMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body['message'] as String?;
    }
    return null;
  }

  String? _extractErrorCode(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body['error'] as String?;
    }
    return null;
  }

  Map<String, String> _extractFieldErrors(dynamic body) {
    if (body is! Map<String, dynamic>) return {};
    final errors = body['errors'];
    if (errors is! Map<String, dynamic>) return {};
    return errors.map((k, v) => MapEntry(k, v.toString()));
  }
}
