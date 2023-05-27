import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voce_widgets/voce_widgets.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/ui/auth/chat_server_helper.dart';
import 'package:vocechat_client/ui/auth/password_register_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// ignore: must_be_immutable
class AppQrScanPage extends StatelessWidget {
  MobileScannerController cameraController = MobileScannerController();

  void Function(String link)? onQrCodeDetected;

  AppQrScanPage({super.key, this.onQrCodeDetected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                App.logger.info("Barcodes detected");
                final barcodes = capture.barcodes;

                if (barcodes.isNotEmpty) {
                  final barcode = barcodes.first;
                  if (barcode.rawValue == null) {
                    App.logger.warning('Failed to scan Barcode');
                  } else {
                    final String code = barcode.rawValue!;
                    App.logger.info('Barcode found! $code');
                    _onQrCodeDetected(code, context);
                  }
                }
              }),
          SafeArea(
              child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: VoceButton(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                  color: Colors.blue, borderRadius: BorderRadius.circular(16)),
              contentPadding: EdgeInsets.zero,
              normal: const Center(
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              action: () async {
                Navigator.pop(context);
                return true;
              },
            ),
          )),
        ],
      ),
    );
  }

  void _onQrCodeDetected(String link, BuildContext context) async {
    if (onQrCodeDetected != null) {
      onQrCodeDetected!(link);
      Navigator.pop(context);
    } else {
      final uri = Uri.parse(link);

      // This pop should be put before [SharedFuncs.parseLink] as there will be
      // a [Navigator.push] in it.
      Navigator.pop(context);
      SharedFuncs.parseLink(uri);
    }
  }

  void showLoaderDialog(BuildContext context) {
    Widget alert = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
          color: Colors.grey, borderRadius: BorderRadius.circular(8)),
      child: Platform.isIOS
          ? CupertinoActivityIndicator(
              color: Colors.white,
            )
          : CircularProgressIndicator(),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Center(child: alert);
      },
    );
  }
}
