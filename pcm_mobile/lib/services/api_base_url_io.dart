import 'dart:io' show Platform;

String get apiBaseUrl =>
    Platform.isAndroid ? 'http://10.0.2.2:5000/api' : 'http://localhost:5000/api';
String get signalRHubUrl =>
    Platform.isAndroid ? 'http://10.0.2.2:5000/pcmHub' : 'http://localhost:5000/pcmHub';
