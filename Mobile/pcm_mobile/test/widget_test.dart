// Smoke test cho PCM Mobile app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pcm_mobile/main.dart';
import 'package:pcm_mobile/providers/user_provider.dart';

void main() {
  testWidgets('App khởi động và hiển thị màn Login (PCM Mobile)', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PCM Mobile'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
  });
}
