import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/member.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  Member? _member;
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Member? get member => _member;

  bool get isLoggedIn => _member != null;

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);
      final token = response.data['token'];
      await _storage.write(key: 'jwt_token', value: token);
      
      _member = Member.fromJson(response.data['member']);
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
      _member = Member.fromJson(response.data);
      notifyListeners();
    } catch (e) {
      // Token might be expired
      await logout();
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    _member = null;
    notifyListeners();
  }
}
