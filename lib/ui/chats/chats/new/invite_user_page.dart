import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vocechat_client/api/lib/group_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:voce_widgets/voce_widgets.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum LinkStatus { loading, ready, error }

class InviteUserPage extends StatefulWidget {
  @override
  State<InviteUserPage> createState() => _InviteUserPageState();
}

class _InviteUserPageState extends State<InviteUserPage> {
  final TextEditingController _linkController = TextEditingController();

  final ValueNotifier<LinkStatus> _linkStatus =
      ValueNotifier(LinkStatus.loading);

  GlobalKey qrKey = GlobalKey();

  Uint8List? _image;

  // default to be 48 hours.
  final expiredIn = 48;

  String? _invitationLink;

  @override
  void initState() {
    super.initState();

    _generateInvitationMagicLink();
    _getServerImge();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: barHeight,
        elevation: 0,
        backgroundColor: AppColors.coolGrey200,
        title: Text(AppLocalizations.of(context)!.inviteNewUsers,
            style: AppTextStyles.titleLarge,
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context, null);
            },
            child: Icon(Icons.close, color: AppColors.grey97)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ValueListenableBuilder<LinkStatus>(
                  valueListenable: _linkStatus,
                  builder: (context, status, _) {
                    switch (status) {
                      case LinkStatus.loading:
                        return SizedBox(
                            height: 96,
                            width: 96,
                            child: Center(child: CupertinoActivityIndicator()));
                      case LinkStatus.ready:
                        return RepaintBoundary(
                          key: qrKey,
                          child: Container(
                            color: Colors.white,
                            child: Column(
                              children: [
                                _buildLinkQrCode(),
                                Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    child: Divider()),
                                _buildLinkText()
                              ],
                            ),
                          ),
                        );
                      default:
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: Text(
                            AppLocalizations.of(context)!
                                .invitationLinkGenerationError,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelMedium,
                          ),
                        );
                    }
                  }),
              _buildButtons()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkText() {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${AppLocalizations.of(context)!.invitationLink}:",
                style: AppTextStyles.titleMedium),
            SizedBox(height: 4),
            SelectableText(_invitationLink ?? "", style: AppTextStyles.snippet)
          ],
        ));
  }

  Widget _buildLinkQrCode() {
    return Column(
      children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: QrImageView(
              data: _invitationLink ?? "",
              // foregroundColor: Colors.blue.shade900,
            )),
        SizedBox(height: 8),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppLocalizations.of(context)!.scanQrCodeToRegister,
              style: AppTextStyles.labelMedium,
            )),
      ],
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ValueListenableBuilder<LinkStatus>(
              valueListenable: _linkStatus,
              builder: (context, status, _) {
                return VoceButton(
                  width: double.maxFinite,
                  contentColor: Colors.white,
                  enabled: ValueNotifier(status == LinkStatus.ready),
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8)),
                  normal: Text(
                    AppLocalizations.of(context)!.shareInvitationLink,
                    style: TextStyle(color: Colors.white),
                  ),
                  action: () async {
                    Share.share(_invitationLink ?? "");
                    return true;
                  },
                );
              }),
          SizedBox(height: 16),
          ValueListenableBuilder<LinkStatus>(
              valueListenable: _linkStatus,
              builder: (context, status, _) {
                return VoceButton(
                  width: double.maxFinite,
                  contentColor: Colors.white,
                  enabled: ValueNotifier(status == LinkStatus.ready),
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8)),
                  normal: Text(
                    AppLocalizations.of(context)!.shareQrCode,
                    style: TextStyle(color: Colors.white),
                  ),
                  action: () async {
                    _captureAndShareQrCode();
                    return true;
                  },
                );
              })
        ],
      ),
    );
  }

  Future<String?> _generateInvitationMagicLink() async {
    _linkStatus.value = LinkStatus.loading;

    try {
      final groupApi = GroupApi();
      final res = await groupApi.getRegMagicLink(expiredIn: expiredIn * 3600);

      if (res.statusCode == 200) {
        return _tempChangeInvitationLinkDomain(res.data as String);
      }
    } catch (e) {
      App.logger.severe(e);
    }

    _linkStatus.value = LinkStatus.error;
    return null;
  }

  Future<void> _getServerImge() async {
    _image = App.app.chatServerM.logo;
  }

  /// Temp function to replace server default domain for invitation link.
  /// Should be deleted after the issue resolves.
  String _tempChangeInvitationLinkDomain(String originalDomain) {
    const pattern = "http://1.2.3.4:4000";

    if (originalDomain.startsWith(pattern)) {
      originalDomain =
          originalDomain.replaceFirst(pattern, App.app.chatServerM.fullUrl);
    }

    _invitationLink = originalDomain;
    _linkController.text = originalDomain;

    _linkStatus.value = LinkStatus.ready;

    return originalDomain;
  }

  Future<void> _captureAndShareQrCode() async {
    try {
      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 4);

      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/invitation.jpg').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareFiles([file.path]);
    } catch (e) {
      App.logger.severe(e);
    }
  }
}
