import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  // Use 10.0.2.2 for Android Emulator, localhost for iOS Simulator or Web
  static const String baseUrl = 'http://localhost:5001/api';

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          // Handle unauthorized (e.g., logout)
        }
        return handler.next(e);
      },
    ));
  }

  Future<Response> login(String username, String password) async {
    return await _dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
  }

  Future<Response> getMe() async {
    return await _dio.get('/auth/me');
  }

  // Booking
  Future<Response> getCourts() async {
    return await _dio.get('/courts');
  }

  Future<Response> getCalendar(DateTime from, DateTime to) async {
    return await _dio.get('/bookings/calendar', queryParameters: {
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
    });
  }

  Future<Response> createBooking(
      int courtId, DateTime start, DateTime end) async {
    return await _dio.post('/bookings', data: {
      'courtId': courtId,
      'startTime': start.toIso8601String(),
      'endTime': end.toIso8601String(),
    });
  }

  Future<Response> cancelBooking(int id) async {
    return await _dio.delete('/bookings/$id');
  }

  // Tournament
  Future<Response> getTournaments() async {
    return await _dio.get('/tournaments');
  }

  Future<Response> createTournament(
      String name, double prizePool, double entryFee) async {
    return await _dio.post('/tournaments', data: {
      'name': name,
      'prizePool': prizePool,
      'entryFee': entryFee,
      'status': 0 // Open
    });
  }

  Future<Response> joinTournament(int tournamentId, String teamName) async {
    return await _dio
        .post('/tournaments/$tournamentId/join', data: {'teamName': teamName});
  }

  // Admin
  Future<Response> getAdminStats() async {
    return await _dio.get('/admin/stats');
  }

  Future<Response> getPendingDeposits() async {
    return await _dio.get('/wallet/pending-deposits');
  }

  Future<Response> approveDeposit(int id) async {
    return await _dio.put('/wallet/approve/$id');
  }

  Future<Response> rejectDeposit(int id) async {
    return await _dio.put('/wallet/reject/$id');
  }

  // Wallet
  Future<Response> getTransactions() async {
    return await _dio.get('/wallet/transactions');
  }

  Future<Response> deposit(double amount) async {
    return await _dio.post('/wallet/deposit', data: {
      'amount': amount,
      'imageUrl': 'placeholder_for_now' // Implement image upload if needed
    });
  }

  // Members
  Future<Response> getMembers({String? search}) async {
    return await _dio.get('/members',
        queryParameters: search != null ? {'search': search} : null);
  }
}
