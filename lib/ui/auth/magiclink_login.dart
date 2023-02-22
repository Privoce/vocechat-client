import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/extensions.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/widgets/banner_button.dart';
import 'package:vocechat_client/ui/widgets/full_width_textfield.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MagiclinkLogin extends StatefulWidget {
  final ChatServerM chatServer;

  const MagiclinkLogin({Key? key, required this.chatServer}) : super(key: key);

  final _cornerRadius = 10.0;

  @override
  State<MagiclinkLogin> createState() => _MagiclinkLoginState();
}

class _MagiclinkLoginState extends State<MagiclinkLogin> {
  final TextEditingController emailController = TextEditingController();

  final ValueNotifier<String> notificationStr = ValueNotifier("");

  late bool enableContinue;
  late bool isSending;
  late bool hasSent;

  @override
  void initState() {
    super.initState();
    enableContinue = false;
    isSending = false;
    hasSent = false;
  }

  @override
  Widget build(BuildContext context) {
    return _buildMagicLinkBlock();
  }

  Column _buildMagicLinkBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 30),
        Text(
          'Email',
          style: TextStyle(fontSize: 16),
        ),
        Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(widget._cornerRadius)),
            child: FullWidthTextField(
              emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              scrollPadding: EdgeInsets.only(bottom: 100),
              onChanged: (text) {
                if (text.isEmail) {
                  setState(() {
                    enableContinue = true;
                  });
                } else {
                  setState(() {
                    enableContinue = false;
                  });
                }
              },
            )),
        SizedBox(height: 20.0),
        _buildContinueBtn(),
        if (hasSent) _buildMagicSentBlock(),
      ],
    );
  }

  Widget _buildContinueBtn() {
    if (isSending) {
      return BannerButton(
          leading: CupertinoActivityIndicator(
            color: Colors.white,
          ),
          title: 'Sending...',
          onTap: () {});
    } else if (hasSent) {
      return BannerButton(
          onTap: () {
            setState(() {
              hasSent = false;
            });
            emailController.text = "";
          },
          title: "Use a different Email");
    } else if (enableContinue) {
      return BannerButton(
          title: 'Continue with Email',
          onTap: _sendMagicLink,
          fontColor: Colors.white);
    } else {
      return BannerButton(
          title: 'Continue with Email', onTap: null, fontColor: Colors.white);
    }
  }

  void _sendMagicLink() async {
    setState(() {
      isSending = true;
    });

    UserApi userApi = UserApi(serverUrl: widget.chatServer.fullUrl);

    String email = emailController.text;

    try {
      final res = await userApi.sendLoginMagicLink(email);
      if (res.statusCode == 200 && res.data != null) {
        setState(() {
          hasSent = true;
          isSending = false;
        });
      }
    } catch (e) {
      setState(() {
        isSending = false;
      });
      await showAppAlert(
          context: context,
          title: AppLocalizations.of(context)!.magicLinkLoginSendError,
          content: AppLocalizations.of(context)!.magicLinkLoginSendErrorContent,
          actions: [
            AppAlertDialogAction(
                text: AppLocalizations.of(context)!.ok,
                action: () => Navigator.pop(context))
          ]);
      App.logger.severe(e);
    }
    setState(() {
      isSending = false;
    });
  }

  // The followings are shown after magic link has been sent.

  Widget _buildMagicSentBlock() {
    String email = emailController.text;
    final notificationStr =
        "We've sent you a magic link to $email. Click on the link to continue.";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 30),
        Text(
          "Check your email inbox",
          style: TextStyle(
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
              fontSize: 16),
        ),
        SizedBox(height: 10),
        Text(
          notificationStr,
          style: TextStyle(
              color: AppColors.grey500,
              fontWeight: FontWeight.w300,
              fontSize: 17),
        ),
      ],
    );
  }
}
