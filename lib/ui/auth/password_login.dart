import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:voce_widgets/voce_widgets.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/extensions.dart';
import 'package:vocechat_client/services/auth_service.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chats/chats_main_page.dart';

class PasswordLogin extends StatefulWidget {
  final ChatServerM chatServer;

  final String? email;

  final String? password;

  final bool isRelogin;

  final bool enable;

  const PasswordLogin(
      {Key? key,
      required this.chatServer,
      this.email,
      this.password,
      this.isRelogin = false,
      this.enable = true})
      : super(key: key);

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

    enableLogin.value = isEmailValid && isPswdValid && widget.enable;
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 34),
      VoceTextField.filled(
        emailController,
        autofocus: true,
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
          enableLogin.value = isEmailValid && isPswdValid && widget.enable;
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
                    AppLocalizations.of(context)!
                        .passwordRegisterPageInvalidEmailFormat,
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
        autofocus: true,
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
          enableLogin.value = isEmailValid && isPswdValid && widget.enable;
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
                    activeColor:
                        widget.enable ? AppColors.primaryBlue : Colors.grey,
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
    }

    App.logger.severe("Login Failed");
    return false;
  }
}
