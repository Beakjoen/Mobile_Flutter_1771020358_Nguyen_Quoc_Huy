import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/member.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';

class UserProvider with ChangeNotifier {
  Member? _member;
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final SignalRService _signalRService = SignalRService();
  StreamSubscription<String>? _notificationSub;

  Member? get member => _member;

  bool get isLoggedIn => _member != null;

  String? _lastLoginError;

  String? get lastLoginError => _lastLoginError;

  Future<bool> login(String username, String password) async {
    _lastLoginError = null;
    try {
      final response = await _apiService.login(username, password);
      final token = response.data['token'];
      await _storage.write(key: 'jwt_token', value: token);
      
      _member = Member.fromJson(response.data['member']);
      
      // Init SignalR
      await _signalRService.initSignalR();
      
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _lastLoginError = _messageFromDio(e);
      return false;
    } catch (e) {
      _lastLoginError = e.toString();
      return false;
    }
  }

  static String _messageFromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['detail'] != null) return data['detail'].toString();
      if (data['message'] != null) return data['message'].toString();
      if (data['title'] != null) return data['title'].toString();
    }
    if (data is String && data.isNotEmpty) return data;
    if (e.response?.statusCode == 400) return 'Yêu cầu không hợp lệ';
    if (e.response?.statusCode == 401) return 'Sai tên đăng nhập hoặc mật khẩu';
    if (e.response?.statusCode != null && e.response!.statusCode! >= 500) return 'Lỗi máy chủ. Thử lại sau.';
    return e.message ?? 'Đăng nhập thất bại';
  }

  Future<void> loadUser() async {
    try {
      final response = await _apiService.getMe();
      final data = response.data is Map ? Map<String, dynamic>.from(response.data as Map) : response.data as Map<String, dynamic>;
      _member = Member.fromJson(data);
      
      // Init SignalR if logged in; khi có thông báo (vd. "Nạp tiền thành công") → refresh user để cập nhật hạng
      await _signalRService.initSignalR();
      _notificationSub ??= _signalRService.notificationStream.listen((_) {
        loadUser();
      });
      
      notifyListeners();
    } catch (e) {
      await logout();
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    _notificationSub?.cancel();
    _notificationSub = null;
    _member = null;
    _signalRService.stop();
    notifyListeners();
  }
}
