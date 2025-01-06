import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:random_string/random_string.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Transmitter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const QRCodeDisplay(),
    );
  }
}

class QRCodeDisplay extends StatefulWidget {
  const QRCodeDisplay({super.key});

  @override
  State<QRCodeDisplay> createState() => _QRCodeDisplayState();
}

class _QRCodeDisplayState extends State<QRCodeDisplay> {
  String qrData = '';
  Timer? timer;

  @override
  void initState() {
    super.initState();
    // Update QR code every 1/30 second (30 FPS)
    timer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      setState(() {
        // Generate random string of 16 characters
        qrData = randomAlphaNumeric(16);
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Transmitter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 300.0,
            ),
            const SizedBox(height: 20),
            Text('Current Data: $qrData',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
} 