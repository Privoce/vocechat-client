import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:voce_widgets/voce_widgets.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/api/models/user/register_request.dart';
import 'package:vocechat_client/api/models/user/send_reg_magic_token_request.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/extensions.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/auth/register/register_naming_page.dart';

class PasswordRegisterPage extends StatefulWidget {
  late final BoxDecoration _bgDeco;
  ChatServerM chatServer;
  String? magicToken;
  Uri? invitationLink;

  PasswordRegisterPage(
      {Key? key,
      required this.chatServer,
      this.magicToken,
      this.invitationLink})
      : super(key: key) {
    _bgDeco = BoxDecoration(
        gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 0.9,
            colors: [
          AppColors.centerColor,
          AppColors.midColor,
          AppColors.edgeColor
        ],
            stops: const [
          0,
          0.6,
          1
        ]));
  }

  @override
  State<PasswordRegisterPage> createState() => _PasswordRegisterPageState();
}

class _PasswordRegisterPageState extends State<PasswordRegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pswdController = TextEditingController();
  final TextEditingController _confirmPswdController = TextEditingController();

  bool rememberMe = true;

  final double cornerRadius = 10.0;

  bool isValidEmail = false;
  ValueNotifier<bool> showEmailWarning = ValueNotifier(false);

  bool isValidPassword = false;
  ValueNotifier<bool> showPswdWarning = ValueNotifier(false);

  bool arePswdsSame = false;
  ValueNotifier<bool> showPswdConfirmWarning = ValueNotifier(false);

  ValueNotifier<bool> enableSignUp = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.edgeColor,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: widget._bgDeco,
          child: SafeArea(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildBackButton(context),
                      _buildTitle(),
                      const SizedBox(height: 50),
                      _buildRegister(),
                      SizedBox(height: 30.0),
                      _buildSignUpBtn()
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: FittedBox(
        child: VoceButton(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(16)),
          contentPadding: EdgeInsets.zero,
          normal: Center(
            child: const Icon(
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
    );
  }

  Widget _buildTitle() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(
          text: TextSpan(children: [
        TextSpan(
            text: AppLocalizations.of(context)!.signUpTo + " ",
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.cyan500)),
        TextSpan(
            text: widget.chatServer.properties.serverName,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue))
      ])),
      Text(widget.chatServer.fullUrlWithoutPort,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.grey500)),
    ]);
  }

  Widget _buildRegister() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VoceTextField.filled(
          _emailController,
          autofocus: true,
          title: Text(AppLocalizations.of(context)!.email),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          scrollPadding: EdgeInsets.only(bottom: 100),
          onChanged: (email) {
            isValidEmail = email.isEmail;
            showEmailWarning.value =
                _emailController.text.trim().isNotEmpty && !isValidEmail;

            enableSignUp.value =
                isValidEmail && isValidPassword && arePswdsSame;
          },
        ),
        SizedBox(
            height: 28.0,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ValueListenableBuilder<bool>(
                valueListenable: showEmailWarning,
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

        // Password

        VoceTextField.filled(
          _pswdController,
          autofocus: true,
          title: Text(AppLocalizations.of(context)!.password),
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.next,
          scrollPadding: EdgeInsets.only(bottom: 100),
          onChanged: (pswd) {
            isValidPassword = pswd.isNotEmpty && pswd.isValidPswd;
            arePswdsSame =
                pswd.isNotEmpty && pswd == _confirmPswdController.text;

            showPswdWarning.value = !isValidPassword;
            enableSignUp.value =
                isValidEmail && isValidPassword && arePswdsSame;
          },
        ),
        SizedBox(
            height: 28.0,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ValueListenableBuilder<bool>(
                valueListenable: showPswdWarning,
                builder: (context, showPswdAlert, child) {
                  if (showPswdAlert) {
                    return Text(
                      AppLocalizations.of(context)!
                          .passwordRegisterPageInvalidPasswordFormat,
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            )),

        // Confirm Password

        VoceTextField.filled(
          _confirmPswdController,
          autofocus: true,
          title: Text(AppLocalizations.of(context)!.confirmPassword),
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.go,
          scrollPadding: EdgeInsets.only(bottom: 100),
          onChanged: (pswd) {
            arePswdsSame = pswd.isNotEmpty && pswd == _pswdController.text;

            showPswdConfirmWarning.value = !arePswdsSame;
            enableSignUp.value =
                isValidEmail && isValidPassword && arePswdsSame;
          },
        ),
        SizedBox(
            height: 28.0,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ValueListenableBuilder<bool>(
                valueListenable: showPswdConfirmWarning,
                builder: (context, showPswdConfirmAlert, child) {
                  if (showPswdConfirmAlert) {
                    return Text(
                      AppLocalizations.of(context)!
                          .passwordRegisterPagePasswordNotMatch,
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            )),
        SizedBox(
            height: 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.rememberMe,
                    style: TextStyle(fontSize: 16)),
                Spacer(),
                CupertinoSwitch(
                    value: rememberMe,
                    activeColor: AppColors.primary400,
                    onChanged: (value) => setState(() {
                          rememberMe = value;
                        }))
              ],
            )),
      ],
    );
  }

  Widget _buildSignUpBtn() {
    return VoceButton(
      width: double.maxFinite,
      enabled: enableSignUp,
      contentColor: Colors.white,
      decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(8)),
      normal: Text(AppLocalizations.of(context)!.signUp,
          style: TextStyle(color: Colors.white)),
      action: _onTapSignUpBtn,
    );
  }

  Future<bool> _onTapSignUpBtn() async {
    try {
      await _checkEmail();
      return true;
    } catch (e) {
      App.logger.severe(e);

      return false;
    }
  }

  Future<void> _checkEmail() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _pswdController.text;

    if (!email.isEmail) {
      _showEmailFormattingErrorSnack();
    }

    try {
      final checkEmailRes =
          await UserApi(serverUrl: widget.chatServer.fullUrl).checkEmail(email);
      if (checkEmailRes.statusCode == 200 && checkEmailRes.data == true) {
        if (widget.magicToken != null && widget.magicToken!.isNotEmpty) {
          await _sendRegMagicLink(widget.magicToken!, email, password);
        } else {
          _navigateToNamingPage(email, password, null);
        }
      } else if (checkEmailRes.statusCode == 200 &&
          checkEmailRes.data == false) {
        _showEmailConflictErrorSnack();
      } else {
        _showNetworkErrorSnack();
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  /// Call backend server to send a registration magic link to the provided
  /// email address.
  Future<void> _sendRegMagicLink(
      String magicToken, String email, String password) async {
    final SendRegMagicTokenRequest req = SendRegMagicTokenRequest(
        magicToken: magicToken, email: email, password: password);
    final res = await UserApi(serverUrl: widget.chatServer.fullUrl)
        .sendRegMagicLink(req);
    if (res.statusCode == 200 && res.data != null) {
      final resData = res.data;
      if (resData!.mailIsSent) {
        _showEmailSentAlert();
      } else {
        _navigateToNamingPage(email, password, resData.newMagicToken);
      }
    } else {
      _showRegistrationFailAlert();
    }
  }

  void _navigateToNamingPage(
      String email, String password, String? magicToken) {
    final registerReq = RegisterRequest(
        email: email, password: password, magicToken: magicToken);
    Navigator.of(context).push(MaterialPageRoute(
        builder: ((context) => RegisterNamingPage(registerReq, rememberMe,
            widget.chatServer, widget.invitationLink))));
  }

  void _showEmailFormattingErrorSnack() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!
              .passwordRegisterPageInvalidEmailFormat)));
    }
  }

  void _showEmailConflictErrorSnack() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.emailConflictError)));
    }
  }

  void _showNetworkErrorSnack() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.networkError)));
    }
  }

  void _showEmailSentAlert() {
    if (mounted) {
      showAppAlert(
          context: context,
          title: AppLocalizations.of(context)!.registrationSuccess,
          content: AppLocalizations.of(context)!.registerEmailSentDes,
          actions: [
            AppAlertDialogAction(
                text: AppLocalizations.of(context)!.ok,
                action: () {
                  Navigator.of(context).pop();
                })
          ]);
    }
  }

  void _showRegistrationFailAlert() {
    if (mounted) {
      showAppAlert(
          context: context,
          title: AppLocalizations.of(context)!.registrationFailed,
          content: AppLocalizations.of(context)!.registrationFailedDes,
          actions: [
            AppAlertDialogAction(
                text: AppLocalizations.of(context)!.ok,
                action: () {
                  Navigator.pop(context);
                })
          ]);
    }
  }
}
