import 'package:mime/mime.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrCodeHelper {
  static final QrCodeHelper _helper = QrCodeHelper._internal();

  factory QrCodeHelper() {
    return _helper;
  }

  QrCodeHelper._internal();

  final _controller = MobileScannerController();

  Future<String?> analyseImage(String path) async {
    final mimeType = lookupMimeType(path);
    if (mimeType != "image/jpg" && mimeType != "image/jpeg") {
      // try to convert image to jpg.
    } else {
      return null;
    }

    return null;
  }
}
