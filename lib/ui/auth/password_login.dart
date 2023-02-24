import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/extensions.dart';
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

  final bool enable;

  PasswordLogin(
      {Key? key,
      required this.chatServer,
      this.email,
      this.password,
      this.isRelogin = false,
      this.enable = true})
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

  // final Color _titleColor = Colors.black;
  final Color _titleColorDisabled = Colors.grey;

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
        enabled: widget.enable ? !widget.isRelogin : false,
        title: Text(
          AppLocalizations.of(context)!.loginPageEmail,
          style: TextStyle(
              fontSize: 16, color: widget.enable ? null : _titleColorDisabled),
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
        enabled: widget.enable,
        title: Text(
          AppLocalizations.of(context)!.password,
          style: TextStyle(
              fontSize: 16, color: widget.enable ? null : _titleColorDisabled),
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
              Text(AppLocalizations.of(context)!.rememberMe,
                  style: TextStyle(
                      fontSize: 16,
                      color: widget.enable ? null : _titleColorDisabled)),
              Spacer(),
              AbsorbPointer(
                absorbing: !widget.enable,
                child: CupertinoSwitch(
                    value: rememberMe,
                    activeColor: widget.enable ? null : Colors.grey,
                    trackColor: widget.enable ? null : Colors.grey,
                    onChanged: (value) => setState(() {
                          rememberMe = value;
                        })),
              )
            ],
          )),
      SizedBox(height: 24),
      _buildLoginButton(),
    ]);
  }

  Widget _buildLoginButton() {
    final themeData = Theme.of(context);
    final bgColor = themeData.primaryColor;

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
      enabled: enableLogin,
    );
  }

  /// Called when login button is pressed
  Future<bool> _onLogin() async {
    final email = emailController.text;
    final pswd = pswdController.text;
    final chatServerM = widget.chatServer;

    String errorMsg = "Login Failed";

    try {
      App.app.authService = AuthService(chatServerM: chatServerM);

      if (await App.app.authService!.login(email, pswd, rememberMe)) {
        await Navigator.of(context)
            .pushNamedAndRemoveUntil(ChatsMainPage.route, (route) => false);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      App.logger.severe(e);
      errorMsg = e.toString();
    }

    App.logger.severe("Login Failed");

    // TODO: to be deleted after error is handled.
    showAppAlert(
        context: context,
        title: "Login failed",
        content:
            "This is only for testing. If this shows, please tap 'copy' button and contact us.",
        actions: [
          AppAlertDialogAction(
              text: "OK", action: () => Navigator.of(context).pop()),
          AppAlertDialogAction(
              text: "Copy",
              action: () {
                Clipboard.setData(ClipboardData(text: errorMsg));
                Navigator.of(context).pop();
              })
        ]);
    return false;
  }
}
