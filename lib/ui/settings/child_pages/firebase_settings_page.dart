import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocechat_client/api/lib/admin_firebase_api.dart';

import 'package:vocechat_client/api/models/admin/fcm/fcm.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';

import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/widgets/app_textfield.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FirebaseSettingPage extends StatefulWidget {
  @override
  State<FirebaseSettingPage> createState() => _FirebaseSettingPageState();
}

class _FirebaseSettingPageState extends State<FirebaseSettingPage> {
  final _tokenUrlController = TextEditingController();
  final _projectIdController = TextEditingController();
  final _privateKeyController = TextEditingController();
  final _clientEmailController = TextEditingController();

  bool _enabled = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    getFcmSettings();
    _tokenUrlController.text = "https://oauth2.googleapis.com/token";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: Text("Firebase",
            style: AppTextStyles.titleLarge,
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
        toolbarHeight: barHeight,
        elevation: 0,
        backgroundColor: AppColors.barBg,
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
        actions: [
          CupertinoButton(
              onPressed: _onSubmit,
              child: Text(AppLocalizations.of(context)!.done,
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 17,
                      color: AppColors.primary400)))
        ],
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BannerTile(
              onTap: () {},
              title: AppLocalizations.of(context)!.firebaseEnable,
              titleWidget:
                  _loading ? CupertinoActivityIndicator() : SizedBox.shrink(),
              keepArrow: false,
              trailing: CupertinoSwitch(
                  value: _enabled,
                  onChanged: (value) {
                    setState(() {
                      _enabled = value;
                    });
                  }),
            ),
            _enabled
                ? SizedBox(
                    height: 420,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          header: "Token Url",
                          textInputAction: TextInputAction.next,
                          autofocus: false,
                          maxLines: 1,
                          controller: _tokenUrlController,
                        ),
                        AppTextField(
                          header: "Project Id",
                          textInputAction: TextInputAction.next,
                          autofocus: false,
                          maxLines: 1,
                          controller: _projectIdController,
                        ),
                        AppTextField(
                          maxLines: 5,
                          textInputAction: TextInputAction.next,
                          autofocus: false,
                          header: "Private Key",
                          controller: _privateKeyController,
                        ),
                        AppTextField(
                          maxLines: 1,
                          textInputAction: TextInputAction.done,
                          autofocus: false,
                          header: "Client Email",
                          controller: _clientEmailController,
                        ),
                      ],
                    ),
                  )
                : SizedBox.shrink()
          ],
        ),
      )),
    );
  }

  void _onSubmit() async {
    AdminFcm req;
    if (_enabled = false) {
      req = AdminFcm(enabled: false);
    } else {
      final tokenUrl = _tokenUrlController.text.trim();
      final projectId = _projectIdController.text.trim();
      final privateKey = _privateKeyController.text.trim();
      final clientEmail = _clientEmailController.text.trim();

      if (tokenUrl.isNotEmpty &&
          projectId.isNotEmpty &&
          privateKey.isNotEmpty &&
          clientEmail.isNotEmpty) {
        req = AdminFcm(
            tokenUrl: tokenUrl,
            projectId: projectId,
            privateKey: privateKey,
            clientEmail: clientEmail);
      } else {
        // TODO: show alert that info is not suffcient.
        return;
      }
    }

    try {
      final adminFirebaseApi = AdminFirebaseApi();
      final res = await adminFirebaseApi.postFcmConfigs(req);
      if (res.statusCode == 200) {
        App.logger.info("FCM Config successful.");
        Navigator.of(context).pop();
      }
    } catch (e) {
      App.logger.severe(e);
      _showAlert(e);
    }
  }

  void getFcmSettings() async {
    setState(() {
      _loading = true;
    });
    final adminFirebaseApi = AdminFirebaseApi();
    final res = await adminFirebaseApi.getFcmConfigs();
    if (res.statusCode == 200 && res.data != null) {
      final fcmConfigs = res.data!;

      if (fcmConfigs.enabled) {
        setState(() {
          _enabled = true;
        });
        _tokenUrlController.text = fcmConfigs.tokenUrl;
        _projectIdController.text = fcmConfigs.projectId!;
        _privateKeyController.text = fcmConfigs.privateKey!;
        _clientEmailController.text = fcmConfigs.clientEmail!;
      } else {
        setState(() {
          _enabled = false;
        });
      }
    }
    setState(() {
      _loading = false;
    });
  }

  void _showAlert(Object error) async {
    showAppAlert(
        context: context,
        title: AppLocalizations.of(context)!.fcmError,
        content: AppLocalizations.of(context)!.fcmErrorContent,
        primaryAction: AppAlertDialogAction(
          text: AppLocalizations.of(context)!.fcmErrorCopyErrorLog,
          action: () {
            Clipboard.setData(ClipboardData(text: error.toString()));
          },
        ),
        actions: [
          AppAlertDialogAction(
              text: AppLocalizations.of(context)!.cancel,
              action: () => Navigator.pop(context))
        ]);
  }
}
