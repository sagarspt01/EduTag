import 'package:flutter/foundation.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

class NfcProvider extends ChangeNotifier {
  String _lastRead = 'No RegNo read yet';
  String get lastRead => _lastRead;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  /// Read RegNo from NFC tag (NDEF Text Record)
  Future<void> readRegNo() async {
    _setProcessing(true);

    final availability = await FlutterNfcKit.nfcAvailability;
    if (availability != NFCAvailability.available) {
      _updateLastRead('NFC not available on this device');
      _setProcessing(false);
      return;
    }

    try {
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 10),
        iosAlertMessage: "Hold your device near the NFC tag",
      );

      if (tag.ndefAvailable != true) {
        _updateLastRead('Tag is not NDEF formatted or readable');
        return;
      }

      final readRecords = await FlutterNfcKit.readNDEFRecords();

      if (readRecords.isEmpty) {
        _updateLastRead('No NDEF records found on tag');
      } else {
        String? regNo;
        for (final record in readRecords) {
          if (record is ndef.TextRecord) {
            final txt = record.text;
            if (txt != null && txt.isNotEmpty) {
              regNo = txt.trim();
              break;
            }
          }
        }

        if (regNo != null) {
          _updateLastRead("RegNo: $regNo");
        } else {
          _updateLastRead('No RegNo found in NDEF records');
        }
      }
    } catch (e) {
      _updateLastRead('Error during NFC read: $e');
    } finally {
      await _finishSafely();
      _setProcessing(false);
    }
  }

  void _updateLastRead(String message) {
    _lastRead = message;
    notifyListeners();
  }

  void _setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  Future<void> _finishSafely() async {
    try {
      await FlutterNfcKit.finish();
    } catch (e) {
      if (kDebugMode) {
        print('Error finishing NFC session: $e');
      }
    }
  }
}
