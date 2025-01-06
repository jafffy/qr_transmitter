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
  int errorCorrectionLevel = QrErrorCorrectLevel.L;  // Add error correction level state
  static const int maxLengthM1 = 5;   // Maximum length for Micro QR M1
  static const int maxLengthM2 = 10;  // Maximum length for Micro QR M2
  static const int maxLengthM3 = 23;  // Maximum length for Micro QR M3
  static const int maxLengthM4 = 35;  // Maximum length for Micro QR M4
  static const int maxLengthV1 = 25;  // Maximum length for Version 1 (alphabetical)
  static const int maxLengthV2 = 47;  // Maximum length for Version 2 (alphabetical)
  // Maximum lengths for Version 3-40 (alphabetical with L error correction)
  static const Map<int, int> versionMaxLengths = {
    3: 77,
    4: 114,
    5: 154,
    6: 195,
    7: 224,
    8: 279,
    9: 335,
    10: 395,
    11: 468,
    12: 535,
    13: 619,
    14: 667,
    15: 758,
    16: 854,
    17: 938,
    18: 1046,
    19: 1153,
    20: 1249,
    21: 1352,
    22: 1460,
    23: 1588,
    24: 1704,
    25: 1853,
    26: 1990,
    27: 2132,
    28: 2223,
    29: 2369,
    30: 2520,
    31: 2677,
    32: 2840,
    33: 3009,
    34: 3183,
    35: 3351,
    36: 3537,
    37: 3729,
    38: 3927,
    39: 4087,
    40: 4296,
  };
  static const roundDuration = Duration(seconds: 10);  // Round duration
  
  final TextEditingController textController = TextEditingController();
  bool isRandomMode = true;  // Track if we're in random generation mode
  bool isPaused = false;  // Track if the round is paused

  // -1 to -4 represents M1 to M4, 1 represents QR V1, 2 represents QR V2, 3-40 represents regular QR versions
  int currentVersion = -1;  // Start with Micro QR M1
  bool completedMicroQR = false;  // Track if we've completed Micro QR phases
  bool completedV1 = false;  // Track if we've completed Version 1

  // List of available versions for dropdown
  final List<Map<String, dynamic>> versions = [
    {'name': 'M1', 'value': -1},
    {'name': 'M2', 'value': -2},
    {'name': 'M3', 'value': -3},
    {'name': 'M4', 'value': -4},
    {'name': 'V1', 'value': 1},
    {'name': 'V2', 'value': 2},
    // Add versions 3-40
    for (int i = 3; i <= 40; i++) {'name': 'V$i', 'value': i},
  ];

  // List of available error correction levels for dropdown
  final List<Map<String, dynamic>> errorCorrectionLevels = [
    {'name': 'L - Low (7%)', 'value': QrErrorCorrectLevel.L},
    {'name': 'M - Medium (15%)', 'value': QrErrorCorrectLevel.M},
    {'name': 'Q - Quartile (25%)', 'value': QrErrorCorrectLevel.Q},
    {'name': 'H - High (30%)', 'value': QrErrorCorrectLevel.H},
  ];

  void pauseRound() {
    setState(() {
      isPaused = true;
      timer?.cancel();
      roundTimer?.cancel();
    });
  }

  void resumeRound() {
    setState(() {
      isPaused = false;
      initializeTimers();
    });
  }

  void resetToVersion(int version) {
    setState(() {
      currentVersion = version;
      currentLength = 1;
      completedMicroQR = version > 0;
      completedV1 = version == 2;
      isRandomMode = true;  // Reset to random mode when version changes
      
      // Reset timers
      timer?.cancel();
      roundTimer?.cancel();
      
      // Restart timers
      initializeTimers();
    });
  }

  void initializeTimers() {
    // Update QR code every 1/30 second (30 FPS)
    timer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (isRandomMode) {  // Only generate random data if in random mode
        setState(() {
          qrData = generateSafeQrData(currentLength);
        });
      }
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
      default:
        return versionMaxLengths[currentVersion] ?? maxLengthV2;  // Return V2 length if version not found
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
    initializeTimers();
  }

  @override
  void dispose() {
    timer?.cancel();
    roundTimer?.cancel();
    textController.dispose();  // Dispose the text controller
    super.dispose();
  }

  void encodeText() {
    String text = textController.text.toUpperCase();  // Convert to uppercase
    int maxLength = getMaxLengthForCurrentVersion();
    
    if (text.length <= maxLength) {
      setState(() {
        isRandomMode = false;  // Switch to manual mode
        qrData = text;
        // Stop the round when encoding text
        timer?.cancel();
        roundTimer?.cancel();
        isPaused = true;
      });
    } else {
      // Show error message if text is too long
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Text too long for current version (max: $maxLength characters)'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void switchToRandom() {
    setState(() {
      isRandomMode = true;
      textController.clear();  // Clear the text input
      if (!isPaused) {
        initializeTimers();
      }
    });
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DropdownButton<int>(
                value: currentVersion,
                isExpanded: true,  // Make dropdown take full width
                items: versions.map((version) {
                  return DropdownMenuItem<int>(
                    value: version['value'],
                    child: Text(version['name']),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    resetToVersion(newValue);
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DropdownButton<int>(
                value: errorCorrectionLevel,
                isExpanded: true,
                items: errorCorrectionLevels.map((level) {
                  return DropdownMenuItem<int>(
                    value: level['value'],
                    child: Text(level['name']),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      errorCorrectionLevel = newValue;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            // Add text input field and buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        hintText: 'Enter text to encode',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: encodeText,
                    child: const Text('Encode'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: switchToRandom,
                    child: const Text('Random'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            QrImageView(
              data: qrData.isNotEmpty ? qrData : ' ',  // Ensure data is never empty
              version: currentVersion > 0 ? currentVersion : QrVersions.auto,  // Use auto for Micro QR
              size: 300.0,
              errorCorrectionLevel: errorCorrectionLevel,  // Use selected error correction level
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: isPaused ? resumeRound : pauseRound,
                  child: Text(isPaused ? 'Resume' : 'Pause'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 