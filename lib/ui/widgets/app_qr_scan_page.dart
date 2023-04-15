import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:voce_widgets/voce_widgets.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/ui/auth/chat_server_helper.dart';
import 'package:vocechat_client/ui/auth/password_register_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AppQrScanPage extends StatelessWidget {
  MobileScannerController cameraController =
      MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);

  // final void Function(String link) onLinkDetected;

  AppQrScanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final barcodes = capture.barcodes;

                if (barcodes.isNotEmpty) {
                  final barcode = barcodes.first;
                  if (barcode.rawValue == null) {
                    App.logger.warning('Failed to scan Barcode');
                  } else {
                    final String code = barcode.rawValue!;
                    _onQrCodeDetected(code, context);
                    // cameraController.stop();
                    App.logger.info('Barcode found! $code');
                  }
                }
              }),
          SafeArea(
              child: Padding(
            padding: EdgeInsets.only(left: 16),
            child: VoceButton(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                  color: Colors.blue, borderRadius: BorderRadius.circular(16)),
              contentPadding: EdgeInsets.zero,
              normal: Center(
                child: const Icon(
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
    // showLoaderDialog(context);
    // onLinkDetected(link);
    // Dismiss loading dialog.
    Navigator.pop(context, link);
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

  void _showUrlUnmatchAlert() {
    final context = navigatorKey.currentContext!;
    showAppAlert(
        context: context,
        title: AppLocalizations.of(context)!.invitationLinkError,
        content: AppLocalizations.of(context)!.invitationLinkUrlNotMatch,
        actions: [
          AppAlertDialogAction(
              text: AppLocalizations.of(context)!.ok,
              action: () => Navigator.of(context).pop())
        ]);
  }
}
