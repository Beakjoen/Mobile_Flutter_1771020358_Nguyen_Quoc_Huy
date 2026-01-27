import 'dart:async';
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

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);
      final token = response.data['token'];
      await _storage.write(key: 'jwt_token', value: token);
      
      _member = Member.fromJson(response.data['member']);
      
      // Init SignalR
      await _signalRService.initSignalR();
      
      notifyListeners();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
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
