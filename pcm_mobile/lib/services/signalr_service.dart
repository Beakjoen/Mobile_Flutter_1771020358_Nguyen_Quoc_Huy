import 'package:signalr_netcore/signalr_client.dart';


class SignalRService {
  HubConnection? _hubConnection;
  
  Future<void> initSignalR() async {
    // 10.0.2.2 for Android Emulator
    const serverUrl = "http://localhost:5000/pcmHub";
    
    _hubConnection = HubConnectionBuilder().withUrl(serverUrl).build();
    
    _hubConnection?.onclose(({error}) {
      print("SignalR Connection Closed");
    });

    _hubConnection?.on("ReceiveNotification", (arguments) {
      final message = arguments?[0] as String;
      print("Notification: $message");
      // Use a StreamController or Provider to notify UI
    });

    _hubConnection?.on("UpdateCalendar", (arguments) {
      print("Calendar Updated");
      // Notify BookingProvider to refresh
    });

    await _hubConnection?.start();
    print("SignalR Connected");
  }

  void stop() {
    _hubConnection?.stop();
  }
}
