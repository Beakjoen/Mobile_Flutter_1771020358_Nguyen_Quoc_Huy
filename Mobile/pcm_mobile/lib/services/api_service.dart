import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_base_url_io.dart' if (dart.library.html) 'api_base_url_web.dart' as url;

class ApiService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  // Backend port 5000. Web: localhost. Android emulator: 10.0.2.2
  static String get baseUrl => url.apiBaseUrl;

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

  /// PHẦN 3: POST /api/bookings/cancel/{id}
  Future<Response> cancelBookingByPost(int id) async {
    return await _dio.post('/bookings/cancel/$id');
  }

  Future<Response> holdBooking(int courtId, DateTime start, DateTime end) async {
    return await _dio.post('/bookings/hold', data: {
      'courtId': courtId,
      'startTime': start.toIso8601String(),
      'endTime': end.toIso8601String(),
    });
  }

  Future<Response> confirmHold(int bookingId) async {
    return await _dio.post('/bookings/confirm/$bookingId');
  }

  /// POST /api/bookings/recurring — VIP (Gold+). daysOfWeek: 0=CN, 1=T2, … 6=T7.
  Future<Response> createRecurringBooking({
    required int courtId,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime startTime,
    required DateTime endTime,
    required List<int> daysOfWeek,
  }) async {
    return await _dio.post('/bookings/recurring', data: {
      'courtId': courtId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'daysOfWeek': daysOfWeek,
    });
  }

  // Tournament
  Future<Response> getTournaments() async {
    return await _dio.get('/tournaments');
  }

  /// Tạo giải đấu (user/Admin). format: 0=Knockout, 1=RoundRobin.
  Future<Response> createTournament({
    required String name,
    required double prizePool,
    required double entryFee,
    DateTime? startDate,
    DateTime? endDate,
    int format = 0,
  }) async {
    final start = startDate ?? DateTime.now().add(const Duration(days: 7));
    final end = endDate ?? start.add(const Duration(days: 7));
    return await _dio.post('/tournaments', data: {
      'name': name,
      'prizePool': prizePool,
      'entryFee': entryFee,
      'startDate': start.toIso8601String(),
      'endDate': end.toIso8601String(),
      'format': format,
      'status': 0, // Open
    });
  }

  Future<Response> joinTournament(int tournamentId, String teamName) async {
    return await _dio
        .post('/tournaments/$tournamentId/join', data: {'teamName': teamName});
  }

  /// GET /api/tournaments/{id}/participants — danh sách người tham gia + currentUserJoined
  Future<Response> getTournamentParticipants(int tournamentId) async {
    return await _dio.get('/tournaments/$tournamentId/participants');
  }

  /// PHẦN 3: POST /api/tournaments/{id}/generate-schedule
  Future<Response> generateTournamentSchedule(int tournamentId) async {
    return await _dio.post('/tournaments/$tournamentId/generate-schedule');
  }

  /// Lấy danh sách trận đấu của giải (có tên VĐV)
  Future<Response> getTournamentMatches(int tournamentId) async {
    return await _dio.get('/tournaments/$tournamentId/matches');
  }

  // Matches
  Future<Response> getMatches({int? tournamentId}) async {
    return await _dio.get('/matches',
        queryParameters:
            tournamentId != null ? {'tournamentId': tournamentId} : null);
  }

  /// PHẦN 3: POST /api/matches/{id}/result
  Future<Response> updateMatchResult(
    int matchId, {
    required int score1,
    required int score2,
    String? details,
    required int winningSide,
  }) async {
    return await _dio.post('/matches/$matchId/result', data: {
      'score1': score1,
      'score2': score2,
      'details': details,
      'winningSide': winningSide,
    });
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
  Future<Response> getMembers(
      {String? search, int page = 1, int pageSize = 20}) async {
    final q = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (search != null && search.isNotEmpty) q['search'] = search;
    return await _dio.get('/members', queryParameters: q);
  }

  /// Bảng xếp hạng theo tổng nạp (top nạp tiền) — dùng cho màn chính
  Future<Response> getLeaderboard({int top = 10}) async {
    return await _dio.get('/members/leaderboard', queryParameters: {'top': top});
  }

  /// PHẦN 3: GET /api/members/{id}/profile - Lịch sử đấu + Rank History
  Future<Response> getMemberProfile(int memberId) async {
    return await _dio.get('/members/$memberId/profile');
  }

  /// PHẦN 3: PUT /api/admin/wallet/approve/{transactionId}
  Future<Response> approveDepositAdmin(int transactionId) async {
    return await _dio.put('/admin/wallet/approve/$transactionId');
  }

  // Challenges (Thách đấu / Duel)
  /// GET /api/challenges?filter=mine|open|finished
  Future<Response> getChallenges({String? filter}) async {
    return await _dio.get('/challenges', queryParameters: filter != null ? {'filter': filter} : null);
  }

  /// GET /api/challenges/{id}
  Future<Response> getChallenge(int id) async {
    return await _dio.get('/challenges/$id');
  }

  /// POST /api/challenges — stakeAmount, opponentId?, message?
  Future<Response> createChallenge({
    required double stakeAmount,
    int? opponentId,
    String? message,
  }) async {
    return await _dio.post('/challenges', data: {
      'stakeAmount': stakeAmount,
      if (opponentId != null) 'opponentId': opponentId,
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }

  /// POST /api/challenges/{id}/accept
  Future<Response> acceptChallenge(int id) async {
    return await _dio.post('/challenges/$id/accept');
  }

  /// POST /api/challenges/{id}/result — body: { winnerId }
  Future<Response> setChallengeResult(int id, {required int winnerId}) async {
    return await _dio.post('/challenges/$id/result', data: {'winnerId': winnerId});
  }

  /// POST /api/challenges/{id}/cancel
  Future<Response> cancelChallenge(int id) async {
    return await _dio.post('/challenges/$id/cancel');
  }
}
