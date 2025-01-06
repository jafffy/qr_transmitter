import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_transmitter/main.dart';

void main() {
  group('QRConfig Tests', () {
    test('QRConfig constants are correctly defined', () {
      // Test Micro QR version constants
      expect(QRConfig.maxLengthM1, equals(5));
      expect(QRConfig.maxLengthM2, equals(10));
      expect(QRConfig.maxLengthM3, equals(23));
      expect(QRConfig.maxLengthM4, equals(35));

      // Test regular QR version constants
      expect(QRConfig.maxLengthV1, equals(25));
      expect(QRConfig.maxLengthV2, equals(47));

      // Test round duration
      expect(QRConfig.roundDuration, equals(const Duration(seconds: 10)));

      // Test a few version max lengths
      expect(QRConfig.versionMaxLengths[3], equals(77));
      expect(QRConfig.versionMaxLengths[40], equals(4296));
    });
  });

  group('QRCodeDisplay Widget Tests', () {
    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 800,
              height: 1000,
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets('QRCodeDisplay widget initializes correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const QRCodeDisplay()));

      expect(find.text('QR Code Transmitter'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNWidgets(3));
      expect(find.byType(DropdownButton<int>), findsNWidgets(2));
    });

    testWidgets('Initial QR version is M1', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const QRCodeDisplay()));
      
      expect(find.text('QR Version: M1'), findsOneWidget);
      expect(find.text('Current Length: 1'), findsOneWidget);
    });

    testWidgets('Can switch QR versions', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const QRCodeDisplay()));

      // Open version dropdown
      await tester.tap(find.byType(DropdownButton<int>).first);
      await tester.pumpAndSettle();

      // Select M2 version
      await tester.tap(find.text('M2').last);
      await tester.pumpAndSettle();

      expect(find.text('QR Version: M2'), findsOneWidget);
      expect(find.text('Current Length: 1'), findsOneWidget);
    });

    testWidgets('Can switch error correction levels', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const QRCodeDisplay()));

      // Initially at L level
      final qrImage = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrImage.errorCorrectionLevel, equals(QrErrorCorrectLevel.L));

      // Open error correction dropdown
      await tester.tap(find.byType(DropdownButton<int>).last);
      await tester.pumpAndSettle();

      // Select M level
      await tester.tap(find.text('M - Medium (15%)').last);
      await tester.pumpAndSettle();

      final updatedQrImage = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(updatedQrImage.errorCorrectionLevel, equals(QrErrorCorrectLevel.M));
    });

    testWidgets('Can encode text', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const QRCodeDisplay()));

      // Enter text
      await tester.enterText(find.byType(TextField), 'TEST');
      await tester.pump();

      // Tap encode button
      await tester.tap(find.text('Encode'));
      await tester.pump();

      // Verify display text
      expect(find.text('Current Data: TEST'), findsOneWidget);
    });

    testWidgets('Shows error when text is too long', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const QRCodeDisplay()));

      // Enter text longer than M1 capacity (5 characters)
      await tester.enterText(find.byType(TextField), 'TOOLONG');
      await tester.pump();

      // Tap encode button
      await tester.tap(find.text('Encode'));
      await tester.pump();

      // Verify error message
      expect(find.text('Text too long for current version (max: 5 characters)'), findsOneWidget);
    });

    testWidgets('Can switch between random and manual mode', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const QRCodeDisplay()));

      // Initially in random mode
      expect(find.text('Random'), findsOneWidget);

      // Enter text and switch to manual mode
      await tester.enterText(find.byType(TextField), 'TEST');
      await tester.tap(find.text('Encode'));
      await tester.pump();

      // Verify display text in manual mode
      expect(find.text('Current Data: TEST'), findsOneWidget);

      // Switch back to random mode
      await tester.tap(find.text('Random'));
      await tester.pump();

      // Verify text field is cleared
      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, isEmpty);
    });

    group('Pause/Resume Tests', () {
      testWidgets('Can pause and resume QR generation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(const QRCodeDisplay()));

        // Find and ensure pause button is visible
        final pauseButton = find.text('Pause');
        await tester.ensureVisible(pauseButton);
        await tester.pumpAndSettle();

        // Initially should show Pause button
        expect(pauseButton, findsOneWidget);
        expect(find.text('Resume'), findsNothing);

        // Tap pause button
        await tester.tap(pauseButton);
        await tester.pumpAndSettle();

        // Should now show Resume button
        final resumeButton = find.text('Resume');
        expect(resumeButton, findsOneWidget);
        expect(pauseButton, findsNothing);

        // Record current QR data
        final currentDataFinder = find.textContaining('Current Data:', findRichText: true);
        final String pausedData = (tester.widget(currentDataFinder) as RichText)
            .text.toPlainText()
            .replaceAll('Current Data: ', '');

        // Wait a moment and verify data hasn't changed
        await tester.pump(const Duration(milliseconds: 100));
        
        final String newData = (tester.widget(currentDataFinder) as RichText)
            .text.toPlainText()
            .replaceAll('Current Data: ', '');
        expect(newData, equals(pausedData));

        // Tap resume button
        await tester.ensureVisible(resumeButton);
        await tester.pumpAndSettle();
        await tester.tap(resumeButton);
        await tester.pumpAndSettle();

        // Should show Pause button again
        expect(pauseButton, findsOneWidget);
        expect(resumeButton, findsNothing);
      });
    });

    group('Automatic Length Doubling Tests', () {
      testWidgets('Length doubles after round duration', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(const QRCodeDisplay()));

        // Initial length should be 1
        expect(find.text('Current Length: 1'), findsOneWidget);

        // Wait for round duration
        await tester.pump(QRConfig.roundDuration);
        await tester.pump(); // Extra pump to process state changes

        // Length should be doubled to 2
        expect(find.text('Current Length: 2'), findsOneWidget);

        // Wait for another round
        await tester.pump(QRConfig.roundDuration);
        await tester.pump();

        // Length should be doubled to 4
        expect(find.text('Current Length: 4'), findsOneWidget);
      });

      testWidgets('Length respects version maximum', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(const QRCodeDisplay()));

        // Wait for multiple rounds until we hit M1 max (5)
        for (int i = 0; i < 3; i++) {
          await tester.pump(QRConfig.roundDuration);
          await tester.pump();
        }

        // Length should be capped at M1 maximum (5)
        expect(find.text('Current Length: 5'), findsOneWidget);
      });
    });

    group('Version Progression Tests', () {
      testWidgets('Progresses from M1 to M2 when max length reached', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(const QRCodeDisplay()));

        // Wait until M1 max length is reached
        while (find.text('Current Length: 5').evaluate().isEmpty) {
          await tester.pump(QRConfig.roundDuration);
          await tester.pump();
        }

        // One more round should switch to M2
        await tester.pump(QRConfig.roundDuration);
        await tester.pump();

        expect(find.text('QR Version: M2'), findsOneWidget);
        expect(find.text('Current Length: 1'), findsOneWidget);
      });
    });

    group('QR Code Appearance Tests', () {
      testWidgets('QR code has correct size', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(const QRCodeDisplay()));

        final qrImage = tester.widget<QrImageView>(find.byType(QrImageView));
        expect(qrImage.size, equals(300.0));
      });

      testWidgets('QR code updates with version changes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(const QRCodeDisplay()));

        // Get initial QR version
        final initialQrImage = tester.widget<QrImageView>(find.byType(QrImageView));
        expect(initialQrImage.version, equals(QrVersions.auto));

        // Open version dropdown and select V1
        await tester.tap(find.byType(DropdownButton<int>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('V1').last);
        await tester.pumpAndSettle();

        // Check if QR version updated
        final updatedQrImage = tester.widget<QrImageView>(find.byType(QrImageView));
        expect(updatedQrImage.version, equals(1));
      });
    });
  });
} 