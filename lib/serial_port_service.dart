import 'package:flutter/foundation.dart'; // For ValueNotifier
import 'package:flutter_libserialport/flutter_libserialport.dart';

class SerialPortService {
  static final SerialPortService _instance = SerialPortService._internal();
  factory SerialPortService() => _instance;
  SerialPortService._internal();

  SerialPort? _serialPort;
  SerialPortReader? _serialPortReader;
  final ValueNotifier<String> _dataNotifier = ValueNotifier<String>('');
  final ValueNotifier<String> _logNotifier = ValueNotifier<String>('');
  final ValueNotifier<String> _throttleRpmNotifier =
      ValueNotifier<String>(''); // Updated for RPM
  final ValueNotifier<String> _sideStandNotifier =
      ValueNotifier<String>(''); // Updated for Side Stand
  final ValueNotifier<String> _gpsNotifier =
      ValueNotifier<String>(''); // Updated for GPS
  final ValueNotifier<String> _grsNotifier =
      ValueNotifier<String>(''); // Updated for GRS
  final ValueNotifier<int> _fuelNotifier =
      ValueNotifier<int>(0); // Updated for Fuel

  ValueNotifier<String> get dataNotifier => _dataNotifier;
  ValueNotifier<String> get logNotifier => _logNotifier;
  ValueNotifier<String> get throttleRpmNotifier => _throttleRpmNotifier;
  ValueNotifier<String> get sideStandNotifier => _sideStandNotifier;
  ValueNotifier<String> get gpsNotifier => _gpsNotifier; // GPS Notifier getter
  ValueNotifier<String> get grsNotifier => _grsNotifier; // GRS Notifier getter
  ValueNotifier<int> get fuelNotifier => _fuelNotifier; // Fuel Notifier getter

  String _buffer = '';
  String _logBuffer = '';

  Future<void> initSerialPort(String portName) async {
    if (_serialPort != null) {
      await dispose(); // Close existing port if open
    }

    _serialPort = SerialPort(portName);

    _serialPort!.config.baudRate = 9600;
    _serialPort!.config.bits = 8;
    _serialPort!.config.parity = SerialPortParity.none;
    _serialPort!.config.stopBits = 1;

    if (!_serialPort!.openReadWrite()) {
      print('Error opening port: ${SerialPort.lastError}');
      return;
    }

    _serialPortReader = SerialPortReader(_serialPort!);

    _serialPortReader!.stream.listen(
      (Uint8List data) {
        _handleData(data);
      },
      onError: (error) {
        print('Error reading data: $error');
      },
    );
  }

  void _handleData(Uint8List data) {
    _buffer += String.fromCharCodes(data);

    List<String> messages = _buffer.split('\n');
    _buffer = messages.removeLast(); // Keep incomplete data in the buffer

    for (String message in messages) {
      if (message.isNotEmpty) {
        String cleanedMessage = _cleanMessage(message);

        if (cleanedMessage.startsWith('T:')) {
          String rpmValue = _extractRpmValue(cleanedMessage);
          if (_throttleRpmNotifier.value != rpmValue) {
            _throttleRpmNotifier.value = rpmValue;
            _dataNotifier.value = rpmValue;
          }
        } else if (cleanedMessage.startsWith('S:')) {
          String ssValue = _extractSideStandValue(cleanedMessage);
          if (_sideStandNotifier.value != ssValue) {
            _sideStandNotifier.value = ssValue;
          }
        } else if (cleanedMessage.startsWith('G:')) {
          String gpsValue = _extractGpsValue(cleanedMessage);
          if (gpsValue.isNotEmpty && _gpsNotifier.value != gpsValue) {
            _gpsNotifier.value = gpsValue;
          }
        } else if (cleanedMessage.startsWith('R:')) {
          String grsValue = _extractGrsValue(cleanedMessage);
          if (grsValue.isNotEmpty && _grsNotifier.value != grsValue) {
            _grsNotifier.value = grsValue;
          }
        } else if (cleanedMessage.startsWith('F:')) {
          int fuelValue = _extractFuelValue(cleanedMessage);
          if (_fuelNotifier.value != fuelValue) {
            _fuelNotifier.value = fuelValue;
          }
        }

        _logBuffer += '$cleanedMessage\n';
        _logNotifier.value = _logBuffer;
      }
    }
  }

  String _cleanMessage(String message) {
    // Efficiently clean the message to remove unwanted characters
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < message.length; i++) {
      final char = message[i];
      if ((char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) ||
          char == 'T' ||
          char == 'S' ||
          char == ':' ||
          char == 'G' ||
          char == 'N' ||
          char == 'R' ||
          char == 'F') {
        // Added 'F' for Fuel
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  String _extractRpmValue(String message) {
    // Directly extract RPM value from cleaned message
    final regExp =
        RegExp(r'T:(\d+)'); // Assuming the format is T: followed by digits
    final match = regExp.firstMatch(message);

    // If a match is found, append '0' to the extracted value. Otherwise, return '0'.
    return match != null ? '${match.group(1)}0' : '0';
  }

  String _extractSideStandValue(String message) {
    // Directly extract Side Stand value from cleaned message
    final regExp =
        RegExp(r'S:(\d+)'); // Assuming the format is S: followed by digits
    final match = regExp.firstMatch(message);
    return match?.group(1) ?? '';
  }

  String _extractGpsValue(String message) {
    // Extract GPS value from cleaned message including 'N'
    final regExp = RegExp(
        r'G:(\d|N)'); // Assuming the format is G: followed by a digit or N
    final match = regExp.firstMatch(message);
    return match?.group(1) ?? '';
  }

  String _extractGrsValue(String message) {
    // Extract GRS value, which can be 1, N, 2
    final regExp = RegExp(
        r'R:(\d|N)'); // Assuming the format is R: followed by a digit or N
    final match = regExp.firstMatch(message);
    return match?.group(1) ?? '';
  }

  int _extractFuelValue(String message) {
    // Extract Fuel value which can be 1 to 5
    final regExp =
        RegExp(r'F:(\d)'); // Assuming the format is F: followed by a digit
    final match = regExp.firstMatch(message);
    final fuelValue = match?.group(1);
    return fuelValue != null ? int.parse(fuelValue) : 0;
  }

  Future<void> dispose() async {
    _serialPortReader?.close();
    _serialPort?.close();
    _serialPort = null;
    _serialPortReader = null;
  }
}
