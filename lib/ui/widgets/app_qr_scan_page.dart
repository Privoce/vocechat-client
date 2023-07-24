import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:voce_widgets/voce_widgets.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

// ignore: must_be_immutable
class AppQrScanPage extends StatefulWidget {
  void Function(String link)? onQrCodeDetected;

  AppQrScanPage({super.key, this.onQrCodeDetected});

  @override
  State<AppQrScanPage> createState() => _AppQrScanPageState();
}

class _AppQrScanPageState extends State<AppQrScanPage> {
  MobileScannerController cameraController = MobileScannerController();

  @override
  initState() {
    super.initState();
    // cameraController.barcodes.listen((capture) {

    // });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 16, top: topPadding),
                    child: VoceButton(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(16)),
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
                  ),
                ],
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        right: 16.0, bottom: bottomPadding + 24),
                    child: VoceButton(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(16)),
                      contentPadding: EdgeInsets.zero,
                      normal: const Center(
                        child: Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      action: () async {
                        _galleryQrScan(context);
                        return true;
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  void _onQrCodeDetected(String link, BuildContext context) async {
    if (widget.onQrCodeDetected != null) {
      Navigator.pop(context);
      widget.onQrCodeDetected?.call(link);
    } else {
      final uri = Uri.parse(link);

      // This pop should be put before [SharedFuncs.parseLink] as there will be
      // a [Navigator.push] in it.
      Navigator.pop(context);
      SharedFuncs.parseUniLink(uri);
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

  void _galleryQrScan(BuildContext context) async {
    await cameraController.stop().then((_) async {
      // assets list
      List<AssetEntity> assets = <AssetEntity>[];

      // config picker assets max count

      final List<AssetEntity>? assetsResult = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
            limitedPermissionOverlayPredicate: (s) =>
                s == PermissionState.authorized,
            maxAssets: 1,
            requestType: RequestType.image),
      );

      final asset = assetsResult?.first;
      if (asset == null) {
      } else {
        final path = (await asset.originFile)?.path;
        if (path == null) {
        } else {
          await cameraController.analyzeImage(path).then((value) async {
            if (value) {
              App.logger.info("qr code found in image");
            } else {
              // no bar code found.
              App.logger.info("qr code not found");
            }
          });
        }
      }
    });

    await cameraController.start();
  }
}
