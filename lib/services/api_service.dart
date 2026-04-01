import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/delivery.dart';
import 'app_config.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.normalizedBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      contentType: 'application/json',
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status != null && status >= 200 && status < 500,
      followRedirects: true,
    ),
  );

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    final jar = PersistCookieJar(storage: FileStorage('${dir.path}/cookies'));
    _dio.interceptors.add(CookieManager(jar));
    _initialized = true;
  }

  Future<Map<String, dynamic>> _unwrap(Response response) async {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['result'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['result'] as Map);
      }
      return data;
    }
    throw Exception('Réponse API invalide');
  }

  String _friendlyDioError(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final result = responseData['result'];
        if (result is Map<String, dynamic> && result['message'] != null) {
          return result['message'].toString();
        }
        if (responseData['message'] != null) {
          return responseData['message'].toString();
        }
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connexion expirée vers ${AppConfig.normalizedBaseUrl}';
        case DioExceptionType.sendTimeout:
          return 'Envoi expiré vers ${AppConfig.normalizedBaseUrl}';
        case DioExceptionType.receiveTimeout:
          return 'Réponse expirée depuis ${AppConfig.normalizedBaseUrl}';
        case DioExceptionType.connectionError:
          return 'Impossible de joindre le serveur ${AppConfig.normalizedBaseUrl}. Vérifie Internet, DNS et HTTPS.';
        case DioExceptionType.badCertificate:
          return 'Certificat SSL rejeté par Android pour ${AppConfig.normalizedBaseUrl}.';
        case DioExceptionType.badResponse:
          return 'Réponse HTTP ${error.response?.statusCode ?? ''} depuis le serveur.';
        default:
          return error.message ?? error.toString();
      }
    }
    return error.toString();
  }

  Future<bool> login(String login, String password) async {
    await init();
    try {
      final response = await _dio.post('/dumiya/mobile/login', data: {
        'db': AppConfig.db,
        'login': login,
        'password': password,
      });
      final data = await _unwrap(response);
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('login', login);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception(_friendlyDioError(e));
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('login');
  }

  Future<String?> lastLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('login');
  }

  Future<List<Delivery>> getDeliveries() async {
    await init();
    try {
      final response = await _dio.post('/dumiya/mobile/deliveries', data: {});
      final raw = await _unwrap(response);
      final List items = raw['deliveries'] ?? [];
      return items
          .map((e) => Delivery.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw Exception(_friendlyDioError(e));
    }
  }

  Future<Map<String, dynamic>> getDeliveryDetail(int deliveryId) async {
    await init();
    try {
      final response = await _dio.post('/dumiya/mobile/delivery/$deliveryId', data: {});
      return _unwrap(response);
    } catch (e) {
      throw Exception(_friendlyDioError(e));
    }
  }

  Future<void> startDelivery(int deliveryId) async {
    await init();
    try {
      final response = await _dio.post('/dumiya/mobile/delivery/$deliveryId/start', data: {});
      final raw = await _unwrap(response);
      if (raw['success'] != true) {
        throw Exception(raw['message'] ?? 'Impossible de démarrer la mission');
      }
    } catch (e) {
      throw Exception(_friendlyDioError(e));
    }
  }

  Future<List<Map<String, dynamic>>> getPosList() async {
    await init();
    try {
      final response = await _dio.post('/dumiya/mobile/pos/list', data: {});
      final raw = await _unwrap(response);
      final List items = raw['items'] ?? [];
      return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      throw Exception(_friendlyDioError(e));
    }
  }

  Future<Map<String, dynamic>> submitProof({
    required int deliveryId,
    required String receiverName,
    required String receiverPhone,
    required String signatureBase64,
    required String status,
    required double amountCollected,
    required int targetPosConfigId,
    String? note,
  }) async {
    await init();
    try {
      final response = await _dio.post('/dumiya/mobile/delivery/$deliveryId/proof', data: {
        'receiver_name': receiverName,
        'receiver_phone': receiverPhone,
        'signature_image': signatureBase64,
        'delivery_status': status,
        'amount_collected': amountCollected,
        'target_pos_config_id': targetPosConfigId,
        'note': note,
      });
      final raw = await _unwrap(response);
      if (raw['success'] != true) {
        throw Exception(raw['message'] ?? 'Envoi de preuve échoué');
      }
      return raw;
    } catch (e) {
      throw Exception(_friendlyDioError(e));
    }
  }
}
