import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signalr_netcore/signalr_client.dart';

import 'api_base_url_io.dart' if (dart.library.html) 'api_base_url_web.dart' as _url;

class SignalRService {
  HubConnection? _hubConnection;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Singleton pattern
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  final _notificationController = StreamController<String>.broadcast();
  Stream<String> get notificationStream => _notificationController.stream;

  final _calendarUpdateController = StreamController<String>.broadcast();
  Stream<String> get calendarUpdateStream => _calendarUpdateController.stream;

  final _matchScoreUpdateController = StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get matchScoreUpdateStream => _matchScoreUpdateController.stream;

  // Store notifications in memory for the session
  final List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  Future<void> initSignalR() async {
    if (_hubConnection?.state == HubConnectionState.Connected) return;

    final serverUrl = _url.signalRHubUrl;

    _hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl,
            options: HttpConnectionOptions(
                accessTokenFactory: () async {
                  final token = await _storage.read(key: 'jwt_token');
                  return token ?? '';
                }))
        .withAutomaticReconnect()
        .build();

    _hubConnection?.onclose(({error}) {
      print("SignalR Connection Closed: $error");
    });

    _hubConnection?.on("ReceiveNotification", (arguments) {
      final message = arguments?[0] as String;
      print("Notification: $message");
      _notifications.insert(0, {
        'title': 'Thông báo mới',
        'body': message,
        'time': DateTime.now().toString(),
        'isRead': false
      });
      _notificationController.add(message);
    });

    _hubConnection?.on("UpdateCalendar", (arguments) {
      final message = arguments?[0] as String;
      print("Calendar Updated: $message");
      _calendarUpdateController.add(message);
    });

    _hubConnection?.on("UpdateMatchScore", (arguments) {
      final matchId = arguments?[0] as String?;
      final score = arguments?[1] as String?;
      if (matchId != null && score != null) {
        _matchScoreUpdateController.add({'matchId': matchId, 'score': score});
      }
    });

    try {
      await _hubConnection?.start();
      print("SignalR Connected");
    } catch (e) {
      print("SignalR Connection Error: $e");
    }
  }

  void stop() {
    _hubConnection?.stop();
  }
}
