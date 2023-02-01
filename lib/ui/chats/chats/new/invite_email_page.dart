import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/lib/admin_smtp.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:voce_widgets/voce_widgets.dart';
import 'package:vocechat_client/ui/widgets/app_textfield.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class InviteEmailPage extends StatefulWidget {
  @override
  State<InviteEmailPage> createState() => _InviteEmailPageState();
}

class _InviteEmailPageState extends State<InviteEmailPage> {
  TextEditingController emailController = TextEditingController();

  ValueNotifier<bool> enableEmailButton = ValueNotifier(false);
  ValueNotifier<bool> smtpEnabled = ValueNotifier(false);
  ValueNotifier<bool> emailValid = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    checkSmtpEnabled();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        toolbarHeight: barHeight,
        elevation: 0,
        backgroundColor: AppColors.coolGrey200,
        title: Text("Invite by Email",
            style: AppTextStyles.titleLarge,
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context, null);
            },
            child: Icon(Icons.close, color: AppColors.grey97)),
        actions: [
          ValueListenableBuilder<bool>(
              valueListenable: enableEmailButton,
              builder: (context, enabled, _) {
                return VoceButton(
                  normal: Text(
                    AppLocalizations.of(context)!.send,
                    style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 17,
                        color: AppColors.primary400),
                  ),
                  enabled: enableEmailButton,
                  action: () async {
                    return true;
                  },
                );
              })
        ],
      ),
      body: SafeArea(
        child: _buildEmailInvitation(),
      ),
    );
  }

  Widget _buildEmailInvitation() {
    return ValueListenableBuilder<bool>(
        valueListenable: smtpEnabled,
        builder: (context, enabled, _) {
          String hintText = enabled ? "Enter email here" : "SMTP not enabled";
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              AppTextField(
                controller: emailController,
                hintText: hintText,
                enabled: enabled,
                onChanged: (email) => validateEmail(email, enabled),
              ),
              if (true)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                      height: 28.0,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: emailValid,
                          builder: (context, emailValid, child) {
                            if (!emailValid) {
                              return Text(
                                "Invalid Email Format",
                                style:
                                    TextStyle(fontSize: 12, color: Colors.red),
                              );
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      )),
                ),
            ],
          );
        });
  }

  void validateEmail(String email, bool smtpEnabled) {
    emailValid.value = email.isEmail;
    enableEmailButton.value = smtpEnabled && email.isEmail;
  }

  void checkSmtpEnabled() async {
    final adminSmtpApi = AdminSmtpApi(App.app.chatServerM.fullUrl);
    final res = await adminSmtpApi.getSmtpEnableStatus();

    if (res.statusCode == 200 && res.data == true) {
      smtpEnabled.value = true;
    }
    smtpEnabled.value = false;
  }

  Future<bool> sendEmailInvitation() async {
    return true;
  }
}
