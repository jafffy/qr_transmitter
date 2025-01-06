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
          body: SizedBox(
            width: 800,
            height: 600,
            child: child,
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
  });
} 