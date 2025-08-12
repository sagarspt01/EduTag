import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

class NFCService {
  /// Reads text content from NFC tag's NDEF records (read-only)
  Future<Map<String, String>> readTag() async {
    try {
      // Start NFC polling
      final tag = await FlutterNfcKit.poll();
      final records = await FlutterNfcKit.readNDEFRecords();

      String content = 'No text data found';

      for (final record in records) {
        if (record is ndef.TextRecord) {
          content = record.text ?? content;
          break;
        }
      }

      // End NFC session
      await FlutterNfcKit.finish();

      return {"id": tag.id, "content": content};
    } catch (e) {
      await FlutterNfcKit.finish();
      return {"id": "", "content": "Error: $e"};
    }
  }
}
