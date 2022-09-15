import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/models/token/credential.dart';
import 'package:vocechat_client/api/models/token/token_login_request.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/services/auth_service.dart';
import 'package:vocechat_client/services/status_service.dart';
import 'package:vocechat_client/ui/chats/chats/chats_main_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:voce_widgets/voce_widgets.dart';

class PasswordLogin extends StatefulWidget {
  final ChatServerM chatServer;

  final String? email;

  late final bool _isRelogin;

  PasswordLogin({Key? key, required this.chatServer, this.email})
      : super(key: key) {
    _isRelogin = email != null && email!.trim().isNotEmpty;
  }

  @override
  State<PasswordLogin> createState() => _PasswordLoginState();
}

class _PasswordLoginState extends State<PasswordLogin> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pswdController = TextEditingController();

  bool isEmailValid = false;
  bool isPswdValid = false;
  ValueNotifier<bool> showEmailAlert = ValueNotifier(false);
  // ValueNotifier<bool> showInvalidPswdWarning = ValueNotifier(false);
  ValueNotifier<bool> enableLogin = ValueNotifier(false);

  late bool isLoggingIn;

  @override
  void initState() {
    super.initState();

    if (widget._isRelogin) {
      emailController.text = widget.email!;
      isEmailValid = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 30),
      SizedBox(height: 4),
      VoceTextField.filled(
        emailController,
        enabled: !widget._isRelogin,
        title: Text(
          AppLocalizations.of(context)!.loginPageEmail,
          style: TextStyle(fontSize: 16),
        ),
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        scrollPadding: EdgeInsets.only(bottom: 100),
        onChanged: (email) {
          isEmailValid = email.isEmail;
          showEmailAlert.value =
              emailController.text.trim().isNotEmpty && !isEmailValid;
          enableLogin.value = isEmailValid && isPswdValid;
        },
      ),
      SizedBox(
          height: 28.0,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: ValueListenableBuilder<bool>(
              valueListenable: showEmailAlert,
              builder: (context, showEmailAlert, child) {
                if (showEmailAlert) {
                  return Text(
                    "Invalid Email Format",
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          )),
      SizedBox(height: 4),
      VoceTextField.filled(
        pswdController,
        title: Text(
          AppLocalizations.of(context)!.loginPagePassword,
          style: TextStyle(fontSize: 16),
        ),
        obscureText: true,
        textInputAction: TextInputAction.go,
        onSubmitted: (_) => _onLogin,
        scrollPadding: EdgeInsets.only(bottom: 100),
        onChanged: (pswd) {
          isPswdValid = pswd.isValidPswd;

          // showInvalidPswdWarning.value =
          //     pswdController.text.trim().isNotEmpty && !pswd.isValidPswd;
          enableLogin.value = isEmailValid && isPswdValid;
        },
      ),
      SizedBox(
        height: 36,
        // child: ValueListenableBuilder<bool>(
        //   valueListenable: showInvalidPswdWarning,
        //   builder: (context, showInvalidPswdWarning, child) {
        //     if (showInvalidPswdWarning) {
        //       return Text("Password invalid");
        //     } else {
        //       return SizedBox.shrink();
        //     }
        //   },
        // )
      ),
      _buildLoginButton(),
    ]);
  }

  Widget _buildLoginButton() {
    final themeData = Theme.of(context);
    final bgColor = themeData.primaryColor;
    // final textColor = themeData.textTheme.
    return VoceButton(
      width: double.maxFinite,
      contentColor: Colors.white,
      decoration:
          BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      normal: Text(
        AppLocalizations.of(context)!.loginPageLogin,
        style: TextStyle(color: Colors.white),
      ),
      action: () async {
        if (await _onLogin()) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil(ChatsMainPage.route, (route) => false);
          return true;
        } else {
          return false;
        }
      },
      enabled: enableLogin,
    );
  }

  /// Called when login button is pressed
  ///
  /// The following will be done in sequence:
  /// 1. Save [LoginResponse] to user_db and in memory;
  /// 2. Update related db. Create a new if not exist.
  Future<bool> _onLogin() async {
    // String pswd = "";
    // Uint8List content = Utf8Encoder().convert(widget._pswdController.text);
    // Digest digest = md5.convert(content);
    // pswd = hex.encode(digest.bytes);

    String device;

    try {
      String deviceToken = "";
      try {
        deviceToken = await FirebaseMessaging.instance.getToken() ?? "";
      } catch (e) {
        App.logger.warning(e);
        // TODO: alert firebase not working, no notification.
        deviceToken = "";
      }

      if (Platform.isIOS) {
        device = "iOS";
      } else if (Platform.isAndroid) {
        device = "Android";
      } else {
        device = "Others";
      }

      final credential = Credential(
          emailController.value.text, pswdController.value.text, "password");

      final req = TokenLoginRequest(
          device: device, credential: credential, deviceToken: deviceToken);

      App.app.statusService = StatusService();
      App.app.authService = AuthService(chatServerM: widget.chatServer);

      if (!await App.app.authService!.login(req)) {
        App.logger.severe("Login Failed");
        return false;
      } else {
        // App.logger.config(req.toJson().toString());
      }

      // await App.app.chatService.preSseDataFetch();
      App.app.chatService.initSse();
    } catch (e) {
      App.logger.severe(e);
      return false;
    }
    return true;
  }
}
