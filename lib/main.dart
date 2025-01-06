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
  Timer? roundTimer;
  int currentLength = 1;  // Start with length of 1
  static const int maxLengthM1 = 5;   // Maximum length for Micro QR M1
  static const int maxLengthM2 = 10;  // Maximum length for Micro QR M2
  static const int maxLengthM3 = 23;  // Maximum length for Micro QR M3
  static const int maxLengthM4 = 35;  // Maximum length for Micro QR M4
  static const int maxLengthV1 = 25;  // Maximum length for Version 1 (alphabetical)
  static const int maxLengthV2 = 47;  // Maximum length for Version 2 (alphabetical)
  static const roundDuration = Duration(seconds: 10);  // Round duration
  
  // -1 to -4 represents M1 to M4, 1 represents QR V1, 2 represents QR V2
  int currentVersion = -1;  // Start with Micro QR M1
  bool completedMicroQR = false;  // Track if we've completed Micro QR phases
  bool completedV1 = false;  // Track if we've completed Version 1

  String getCurrentVersionName() {
    if (currentVersion < 0) {
      return 'M${-currentVersion}';  // Convert -1..-4 to M1..M4
    }
    return 'V$currentVersion';  // Regular QR versions
  }

  int getMaxLengthForCurrentVersion() {
    switch (currentVersion) {
      case -1: return maxLengthM1;
      case -2: return maxLengthM2;
      case -3: return maxLengthM3;
      case -4: return maxLengthM4;
      case 1: return maxLengthV1;
      case 2: return maxLengthV2;
      default: return maxLengthV2;
    }
  }

  String generateSafeQrData(int length) {
    // Ensure length doesn't exceed version capacity
    int safeLength = length;
    int maxLength = getMaxLengthForCurrentVersion();
    if (safeLength > maxLength) {
      safeLength = maxLength;
    }
    return randomAlpha(safeLength).toUpperCase();  // Use only uppercase alphabetical characters
  }

  @override
  void initState() {
    super.initState();
    // Update QR code every 1/30 second (30 FPS)
    timer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      setState(() {
        qrData = generateSafeQrData(currentLength);
      });
    });

    // Round timer to double the length every 10 seconds
    roundTimer = Timer.periodic(roundDuration, (timer) {
      setState(() {
        int maxLength = getMaxLengthForCurrentVersion();
        
        if (!completedMicroQR) {
          // Handle Micro QR phases (M1 to M4)
          if (currentLength < maxLength) {
            currentLength *= 2;
            if (currentLength > maxLength) {
              currentLength = maxLength;
            }
          } else {
            // Move to next Micro QR version or to QR V1
            if (currentVersion > -4) {
              // Still in Micro QR phases
              currentVersion--;  // Move to next M version
              currentLength = 1;
            } else {
              // Completed Micro QR, move to QR V1
              currentVersion = 1;
              currentLength = 1;
              completedMicroQR = true;
            }
          }
        } else if (!completedV1) {
          // Handle Version 1 phase
          if (currentLength < maxLength) {
            currentLength *= 2;
            if (currentLength > maxLength) {
              currentLength = maxLength;
            }
          } else {
            // Switch to Version 2 and start from 1
            currentVersion = 2;
            currentLength = 1;
            completedV1 = true;
          }
        } else {
          // Handle Version 2 phase
          if (currentLength < maxLength) {
            currentLength *= 2;
          } else {
            // Reset to 1 but stay in Version 2
            currentLength = 1;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    roundTimer?.cancel();
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
              data: qrData.isNotEmpty ? qrData : ' ',  // Ensure data is never empty
              version: currentVersion > 0 ? currentVersion : QrVersions.auto,  // Use auto for Micro QR
              size: 300.0,
              errorCorrectionLevel: QrErrorCorrectLevel.L,  // Add error correction
            ),
            const SizedBox(height: 20),
            Text(
              'Current Data: ${qrData.length > 4 ? '${qrData.substring(0, 4)}...' : qrData}',
              style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Current Length: $currentLength',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('QR Version: ${getCurrentVersionName()}',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
} 