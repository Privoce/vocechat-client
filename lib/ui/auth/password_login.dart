import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_alert_dialog.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/services/auth_service.dart';
import 'package:vocechat_client/ui/chats/chats/chats_main_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:voce_widgets/voce_widgets.dart';

class PasswordLogin extends StatefulWidget {
  final ChatServerM chatServer;

  final String? email;

  final String? password;

  final bool isRelogin;

  PasswordLogin(
      {Key? key,
      required this.chatServer,
      this.email,
      this.password,
      this.isRelogin = false})
      : super(key: key) {
    // _isRelogin = email != null && email!.trim().isNotEmpty;
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
  bool rememberMe = true;

  late bool isLoggingIn;

  @override
  void initState() {
    super.initState();

    if (widget.email != null && widget.email!.isNotEmpty) {
      emailController.text = widget.email!;
      isEmailValid = emailController.text.isEmail;
    }

    if (widget.password != null && widget.password!.isNotEmpty) {
      pswdController.text = widget.password!;
      isPswdValid = pswdController.text.isValidPswd;
      rememberMe = true;
    }

    enableLogin.value = isEmailValid && isPswdValid;
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 30),
      SizedBox(height: 4),
      VoceTextField.filled(
        emailController,
        enabled: !widget.isRelogin,
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
        enableVisibleObscureText: true,
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
      SizedBox(height: 24),
      SizedBox(
          height: 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(AppLocalizations.of(context)!.loginPageRememberMe,
                  style: TextStyle(fontSize: 16)),
              Spacer(),
              CupertinoSwitch(
                  value: rememberMe,
                  onChanged: (value) => setState(() {
                        rememberMe = value;
                      }))
            ],
          )),
      SizedBox(height: 24),
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
      action: _onLogin,
      // onError: () => showAppAlert(context: context, title: title, actions: actions),

      enabled: enableLogin,
    );
  }

  /// Called when login button is pressed
  Future<bool> _onLogin() async {
    final email = emailController.text;
    final pswd = pswdController.text;
    final chatServerM = widget.chatServer;
    try {
      App.app.authService = AuthService(chatServerM: chatServerM);

      if (!await App.app.authService!.login(email, pswd, rememberMe)) {
        App.logger.severe("Login Failed");

        /*
      // TODO: to be deleted after error is handled.
      showAppAlert(context: context, title: "Login failed", actions: [
        AppAlertDialogAction(
            text: "OK", action: () => Navigator.of(context).pop())
      ]);

      */
        return false;
      }
    } catch (e) {
      App.logger.severe(e);

      /*
      // TODO: to be deleted after error is handled.
      showAppAlert(
          context: context,
          title: "Login failed",
          content: e.toString(),
          actions: [
            AppAlertDialogAction(
                text: "OK", action: () => Navigator.of(context).pop()),
            AppAlertDialogAction(
                text: "Copy",
                action: () {
                  Clipboard.setData(ClipboardData(text: e.toString()));
                  Navigator.of(context).pop();
                })
          ]);
          */
      return false;
    }

    Navigator.of(context)
        .pushNamedAndRemoveUntil(ChatsMainPage.route, (route) => false);
    return true;
  }

  // void _showLoginError()
}
