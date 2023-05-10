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
  MobileScannerController cameraController = MobileScannerController();

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
                    _onQrCodeDetected(code, context);
                    App.logger.info('Barcode found! $code');
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
    showLoaderDialog(context);
    await _validateLink(link).then((valid) {
      if (valid) {
        App.logger.info("success, $link");
      } else {
        // Dismiss loading dialog.
        Navigator.pop(context);

        showAppAlert(
            context: context,
            title:
                AppLocalizations.of(context)!.appQrCodeScanPageInvalidCodeTitle,
            content: AppLocalizations.of(context)!
                .appQrCodeScanPageInvalidCodeContent,
            actions: [
              AppAlertDialogAction(
                  text: AppLocalizations.of(context)!.ok,
                  action: () => Navigator.of(context).pop())
            ]);

        // Pop scan page.
        Navigator.pop(context);
      }
    });
  }

  Future<bool> _validateLink(String link) async {
    try {
      final context = navigatorKey.currentContext!;

      Uri uri = Uri.parse(link);

      String host = uri.host;
      if (host == "privoce.voce.chat") {
        host = "dev.voce.chat";
      }

      // Check if host is the same when a pre-set server url is available
      if (SharedFuncs.hasPreSetServerUrl() &&
          Uri.parse(App.app.customConfig!.configs.serverUrl).host != host) {
        _showUrlUnmatchAlert();

        return false;
      }

      final apiPath =
          "${uri.scheme}://$host${uri.hasPort ? ":${uri.port}" : ""}";
      final userApi = UserApi(serverUrl: apiPath);
      final magicToken = uri.queryParameters["magic_token"] as String;

      final res = await userApi.checkMagicToken(magicToken);
      if (res.statusCode == 200 && res.data == true) {
        final chatServerM =
            await ChatServerHelper().prepareChatServerM(apiPath);
        if (chatServerM != null) {
          // Dismiss loading dialog.
          Navigator.pop(context);

          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => PasswordRegisterPage(
                    chatServer: chatServerM,
                    magicToken: magicToken,
                  )));
        }
      } else {
        App.logger.warning("Link not valid.");

        return false;
      }
    } catch (e) {
      App.logger.severe(e);

      return false;
    }

    return true;
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
