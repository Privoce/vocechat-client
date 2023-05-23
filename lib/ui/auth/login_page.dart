import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:voce_widgets/voce_widgets.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/ui/auth/chat_server_helper.dart';
import 'package:vocechat_client/ui/auth/invitation_link_paste_page.dart';
import 'package:vocechat_client/ui/auth/magiclink_login.dart';
import 'package:vocechat_client/ui/auth/password_login.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/auth/password_register_page.dart';
import 'package:vocechat_client/ui/widgets/banner_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  // static const route = '/auth/login';

  // final ChatServerM chatServerM;
  final String baseUrl;

  final String? email;

  final String? password;

  late final BoxDecoration _bgDeco;

  final bool isRelogin;

  /// Back button will be hidden if this flag is set.
  ///
  /// This should be set when [EnvConstants.voceBaseUrl] is set. This flag is
  /// originally set false.
  final bool disableBackButton;

  LoginPage(
      {
      // required this.chatServerM,
      required this.baseUrl,
      this.email,
      this.password,
      this.isRelogin = false,
      this.disableBackButton = false,
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
  final ValueNotifier<_ServerInfoFetchingStatus> serverInfoFetchingStatus =
      ValueNotifier(_ServerInfoFetchingStatus.fetching);

  ChatServerM? _chatServerM;

  @override
  void initState() {
    super.initState();
    _getChatServerM();
  }

  @override
  Widget build(BuildContext context) {
    // _chatServer = ModalRoute.of(context)!.settings.arguments as ChatServerM;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.edgeColor,
      body: _buildBody(context),
      bottomNavigationBar:
          SharedFuncs.hasPreSetServerUrl() ? _buildBottomNavBar() : null,
    );
  }

  GestureDetector _buildBody(BuildContext context) {
    return GestureDetector(
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
                    ])),
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
              return ValueListenableBuilder<_ServerInfoFetchingStatus>(
                  valueListenable: serverInfoFetchingStatus,
                  builder: (context, status, _) {
                    switch (status) {
                      case _ServerInfoFetchingStatus.done:
                        return PasswordLogin(
                            key: ObjectKey(_chatServerM),
                            chatServer: _chatServerM!,
                            email: widget.email,
                            password: widget.password,
                            isRelogin: widget.isRelogin,
                            enable: true);
                      case _ServerInfoFetchingStatus.error:
                        return Center(
                          child: SizedBox(
                            height: 48,
                            width: double.maxFinite,
                            child: CupertinoButton.filled(
                                padding: EdgeInsets.zero,
                                child:
                                    Text(AppLocalizations.of(context)!.retry),
                                onPressed: () => _getChatServerM()),
                          ),
                        );

                      default:
                        return PasswordLogin(
                            key: ObjectKey(_chatServerM),
                            chatServer: ChatServerM(),
                            email: widget.email,
                            password: widget.password,
                            isRelogin: widget.isRelogin,
                            enable: false);
                    }
                  });
            case LoginType.magiclink:
              return MagiclinkLogin(chatServer: _chatServerM!);
            default:
              return PasswordLogin(chatServer: _chatServerM!);
          }
        });
  }

  Widget _buildRegister() {
    return ValueListenableBuilder<_ServerInfoFetchingStatus>(
        valueListenable: serverInfoFetchingStatus,
        builder: (context, status, _) {
          switch (status) {
            case _ServerInfoFetchingStatus.done:
              if (_chatServerM?.properties.config == null) {
                return SizedBox.shrink();
              }

              if (_chatServerM!.properties.config?.whoCanSignUp != "EveryOne") {
                return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                        AppLocalizations.of(context)!.loginPageOnlyInvitedDes,
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
                      onTap: () => _onTapSignUp(_chatServerM!),
                      child: Text(AppLocalizations.of(context)!.loginPageSignUp,
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: AppColors.cyan500)),
                    )
                  ],
                ),
              );

            default:
              return SizedBox.shrink();
          }
        });
  }

  void _onTapSignUp(ChatServerM chatServerM) {
    Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) {
              return PasswordRegisterPage(chatServer: chatServerM);
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
      child: widget.disableBackButton
          ? SizedBox(height: 32, width: 32)
          : FittedBox(
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
    const double titleHeight = 40;
    return Builder(builder: (context) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ValueListenableBuilder<_ServerInfoFetchingStatus>(
            valueListenable: serverInfoFetchingStatus,
            builder: (context, status, _) {
              switch (status) {
                case _ServerInfoFetchingStatus.error:
                  return SizedBox(
                      height: titleHeight,
                      child: Text(
                          "${AppLocalizations.of(context)!.loginPageTitle} ",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cyan500)));
                case _ServerInfoFetchingStatus.done:
                  return SizedBox(
                    height: titleHeight,
                    child: RichText(
                        text: TextSpan(
                      children: [
                        TextSpan(
                            text:
                                "${AppLocalizations.of(context)!.loginPageTitle} ",
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cyan500)),
                        TextSpan(
                          text: _chatServerM!.properties.serverName,
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade700),
                        ),
                      ],
                    )),
                  );

                default:
                  return SizedBox(
                      height: titleHeight,
                      child: Row(
                        children: [
                          Text(
                              AppLocalizations.of(context)!.fetchingServerInfo),
                          SizedBox(width: 8),
                          CupertinoActivityIndicator()
                        ],
                      ));
              }
            }),
        ValueListenableBuilder<_ServerInfoFetchingStatus>(
            valueListenable: serverInfoFetchingStatus,
            builder: (context, status, _) {
              switch (status) {
                case _ServerInfoFetchingStatus.error:
                  return Text(
                      AppLocalizations.of(context)!.fetchingServerInfoError,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.grey500));

                default:
                  return Text(widget.baseUrl,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.grey500));
              }
            }),
      ]);
    });
  }

  Widget _buildBottomNavBar() {
    return SafeArea(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VoceButton(
              normal: Text(AppLocalizations.of(context)!.clearLocalData,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              action: () async {
                await SharedFuncs.clearLocalData();
                return true;
              },
            ),
            Text("  |  "),
            VoceButton(
              normal: Text(AppLocalizations.of(context)!.inputInvitationLink,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              action: () async {
                _onPasteInvitationLinkTapped(context);
                return true;
              },
            ),
          ],
        ),
        SizedBox(
          height: 30,
          child: FutureBuilder<String>(
              future: SharedFuncs.getAppVersion(),
              builder: ((context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    "${AppLocalizations.of(context)!.version}: ${snapshot.data}",
                    style: AppTextStyles.labelSmall,
                  );
                } else {
                  return SizedBox.shrink();
                }
              })),
        )
      ],
    ));
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

  Future<ChatServerM?> _getChatServerM() async {
    serverInfoFetchingStatus.value = _ServerInfoFetchingStatus.fetching;
    final chatServerM =
        await ChatServerHelper().prepareChatServerM(widget.baseUrl);
    if (chatServerM != null) {
      _chatServerM = chatServerM;
      serverInfoFetchingStatus.value = _ServerInfoFetchingStatus.done;

      return chatServerM;
    } else {
      _chatServerM = null;
      serverInfoFetchingStatus.value = _ServerInfoFetchingStatus.error;
    }
    return null;
  }

  void _onPasteInvitationLinkTapped(BuildContext context) async {
    final route = PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          InvitationLinkPastePage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.fastOutSlowIn;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
    Navigator.of(context).push(route);
  }
}

enum _ServerInfoFetchingStatus { fetching, done, error }
