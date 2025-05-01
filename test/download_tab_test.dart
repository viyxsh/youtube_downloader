import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_downloader/screens/download_tab.dart';

void main() {
  testWidgets('shows error when invalid YouTube URL is entered', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DownloadTab()),
      ),
    );

    // Enter an invalid URL
    final urlField = find.byType(TextField);
    await tester.enterText(urlField, 'not-a-valid-url');
    await tester.pump();

    // Tap the Get Video Info button
    final button = find.text('Get Video Info');
    await tester.tap(button);
    await tester.pump(const Duration(seconds: 1)); // Allow time for async work

    // Check if error SnackBar appears
    expect(find.textContaining('Please enter a valid YouTube URL'), findsOneWidget);
  });
}
