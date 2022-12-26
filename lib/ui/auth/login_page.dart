import 'package:flutter/material.dart';
import 'package:voce_widgets/voce_widgets.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/ui/auth/magiclink_login.dart';
import 'package:vocechat_client/ui/auth/password_login.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/auth/password_register_page.dart';
import 'package:vocechat_client/ui/widgets/banner_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  // static const route = '/auth/login';

  final ChatServerM chatServerM;

  final String? email;

  final String? password;

  late final BoxDecoration _bgDeco;

  final bool isRelogin;

  LoginPage(
      {required this.chatServerM,
      this.email,
      this.password,
      this.isRelogin = false,
      Key? key})
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

    // isRelogin = email != null && email!.trim().isNotEmpty;
  }

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // late ChatServerM _chatServer;
  final ValueNotifier<LoginType> _loginTypeNotifier =
      ValueNotifier(LoginType.password);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // _chatServer = ModalRoute.of(context)!.settings.arguments as ChatServerM;

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
                      _buildLoginBlock(),
                      _buildRegister(),
                      // _buildDivider(),
                      // _buildLoginTypeSwitch()
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginBlock() {
    return ValueListenableBuilder<LoginType>(
        valueListenable: _loginTypeNotifier,
        builder: (context, loginType, _) {
          switch (loginType) {
            case LoginType.password:
              return PasswordLogin(
                  chatServer: widget.chatServerM,
                  email: widget.email,
                  password: widget.password,
                  isRelogin: widget.isRelogin);
            case LoginType.magiclink:
              return MagiclinkLogin(chatServer: widget.chatServerM);
            default:
              return PasswordLogin(chatServer: widget.chatServerM);
          }
        });
  }

  Widget _buildRegister() {
    if (widget.chatServerM.properties.config == null) {
      return SizedBox.shrink();
    }

    if (widget.chatServerM.properties.config?.whoCanSignUp != "EveryOne") {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
              "Only invited user can sign up to this server. Please seek help from server admin for sign up link.",
              style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: AppColors.grey500)));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.loginPageNoAccount,
            style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: AppColors.grey500),
          ),
          SizedBox(width: 5),
          GestureDetector(
            onTap: _onTapSignUp,
            child: Text(AppLocalizations.of(context)!.loginPageSignUp,
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.cyan500)),
          )
        ],
      ),
    );
  }

  void _onTapSignUp() {
    Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) {
              return PasswordRegisterPage(chatServer: widget.chatServerM);
            }));
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        children: [
          Divider(thickness: 0.5, color: AppColors.grey300),
          Center(
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.zero,
                    color: AppColors.edgeColor),
                child: Text(
                  "OR",
                  style: TextStyle(color: AppColors.grey500),
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: FittedBox(
          child: !widget.isRelogin
              ? VoceButton(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16)),
                  contentPadding: EdgeInsets.zero,
                  normal: Center(
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  action: () async {
                    Navigator.pop(context);
                    return true;
                  },
                )
              : VoceButton(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                      color: Colors.blue,
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
                )),
    );
  }

  Widget _buildTitle() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(
          text: TextSpan(
        children: [
          TextSpan(
              text: AppLocalizations.of(context)!.loginPageTitle + " ",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyan500)),
          TextSpan(
            text: widget.chatServerM.properties.serverName,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade700),
          ),
        ],
      )),
      Text(widget.chatServerM.fullUrlWithoutPort,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.grey500)),
    ]);
  }

  Widget _buildLoginTypeSwitch() {
    return ValueListenableBuilder(
        valueListenable: _loginTypeNotifier,
        builder: (context, loginType, _) {
          switch (loginType) {
            case LoginType.magiclink:
              return BannerButton(
                onTap: () => _loginTypeNotifier.value = LoginType.password,
                title: "Sign in with Password",
              );
            case LoginType.password:
              return BannerButton(
                  onTap: () => _loginTypeNotifier.value = LoginType.magiclink,
                  title: "Sign in with Magic Link");
            default:
              return SizedBox.shrink();
          }
        });
  }
}
