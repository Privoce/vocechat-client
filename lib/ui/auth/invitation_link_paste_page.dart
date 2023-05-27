import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/event_bus_objects/private_channel_link_event.dart';
import 'package:vocechat_client/globals.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:voce_widgets/voce_widgets.dart';
import 'package:vocechat_client/ui/auth/chat_server_helper.dart';
import 'package:vocechat_client/ui/auth/password_register_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/ui/widgets/app_qr_scan_page.dart';

enum InvitationLinkTextFieldButtonType { clear, paste }

class InvitationLinkPastePage extends StatelessWidget {
  static const String route = "/invitation_link_paste_page";

  late final BoxDecoration _bgDeco;

  final _centerColor = const Color.fromRGBO(0, 113, 236, 1);
  final _midColor = const Color.fromRGBO(162, 201, 243, 1);
  final _edgeColor = const Color.fromRGBO(233, 235, 237, 1);

  final TextEditingController _controller = TextEditingController();

  final ValueNotifier<InvitationLinkTextFieldButtonType> buttonType =
      ValueNotifier(InvitationLinkTextFieldButtonType.paste);

  InvitationLinkPastePage({super.key, String? initialLink}) {
    _bgDeco = BoxDecoration(
        gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 0.9,
            colors: [_centerColor, _midColor, _edgeColor],
            stops: const [0, 0.6, 1]));
    _controller.text = initialLink ?? "";
    if (_controller.text.trim().isNotEmpty) {
      buttonType.value = InvitationLinkTextFieldButtonType.clear;
    } else {
      buttonType.value = InvitationLinkTextFieldButtonType.paste;
    }
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
          decoration: _bgDeco,
          child: SafeArea(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildBackButton(context),
                      _buildTitle(context),
                      const SizedBox(height: 50),
                      _buildTextField(context),
                      const SizedBox(height: 8),

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

  Widget _buildTextField(BuildContext context) {
    const double height = 44;
    const double btnRadius = height / 2;
    const double iconSize = btnRadius * 1.414;

    return Row(
      children: [
        Flexible(
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Flexible(
                    child: VoceTextField(
                  _controller,
                  autofocus: true,
                  height: height,
                  onChanged: (_) {
                    final text = _controller.text;
                    if (text.trim().isNotEmpty) {
                      buttonType.value =
                          InvitationLinkTextFieldButtonType.clear;
                    } else {
                      buttonType.value =
                          InvitationLinkTextFieldButtonType.paste;
                    }
                  },
                )),
                // Flexible(child: TextField()),
                ValueListenableBuilder<InvitationLinkTextFieldButtonType>(
                    valueListenable: buttonType,
                    builder: (context, type, _) {
                      return _buildTextFieldPasteButton(context, type);
                    }),
                IconButton(
                    icon: Icon(Icons.qr_code_scanner_rounded,
                        color: Colors.blue, size: 30),
                    onPressed: () async {
                      final route = PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            AppQrScanPage(
                          onQrCodeDetected: (link) async {
                            final uri = Uri.parse(link);
                            if (uri.host == "voce.chat" && uri.path == "/url") {
                              if (uri.queryParameters.containsKey("i")) {
                                _controller.text =
                                    uri.queryParameters["i"] ?? "";
                                if (_controller.text.trim().isNotEmpty) {
                                  buttonType.value =
                                      InvitationLinkTextFieldButtonType.clear;
                                } else {
                                  buttonType.value =
                                      InvitationLinkTextFieldButtonType.paste;
                                }
                                return;
                              } else if (uri.queryParameters.containsKey("s")) {
                                await SharedFuncs.handleServerLink(uri);
                                return;
                              }
                            }
                            if (!await launchUrl(uri)) {
                              throw Exception('Could not launch $uri');
                            }
                          },
                        ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.fastOutSlowIn;

                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));

                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      );
                      Navigator.push(context, route);
                    })
              ],
            ),
          ),
        ),
        SizedBox(width: 8),
        VoceButton(
          height: height,
          width: height,
          contentPadding: EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(btnRadius)),
          normal: Icon(
            Icons.arrow_forward,
            color: Colors.white,
            size: iconSize,
          ),
          busy: CupertinoActivityIndicator(
            color: Colors.white,
            radius: iconSize / 2,
          ),
          keepNormalWhenBusy: false,
          action: () async {
            // return await _onUrlSubmit(_urlController.text + "/api");
            await _onLinkSubmitted(context);

            return true;
          },
        )
      ],
    );
  }

  Future<bool> _onLinkSubmitted(BuildContext context) async {
    final link = _controller.text.trim();

    try {
      final modifiedLink = link.replaceFirst("/#", "");
      Uri uri = Uri.parse(modifiedLink).replace(fragment: '');

      String host = uri.host;
      if (host == "privoce.voce.chat") {
        host = "dev.voce.chat";
      }

      // Check if host is the same when a pre-set server url is available
      if (SharedFuncs.hasPreSetServerUrl() &&
          Uri.parse(App.app.customConfig!.configs.serverUrl).host != host) {
        _showUrlUnmatchAlert();
        _controller.clear();
        return false;
      }

      final apiPath =
          "${uri.scheme}://$host${uri.hasPort ? ":${uri.port}" : ""}";
      final userApi = UserApi(serverUrl: apiPath);
      final magicToken = uri.queryParameters["magic_token"] as String;

      await userApi.checkMagicToken(magicToken).then((res) async {
        if (res.statusCode == 200 && res.data == true) {
          await ChatServerHelper()
              .prepareChatServerM(apiPath)
              .then((chatServerM) {
            if (chatServerM?.fullUrl == App.app.chatServerM.fullUrl &&
                App.app.userDb?.loggedIn != 0) {
              // Current chat server is the same as the invitation link,
              // and is logged in.
              if (uri.pathSegments.length == 2 &&
                  uri.pathSegments[0] == "invite_private") {
                Navigator.of(context).pop();
                eventBus.fire(PrivateChannelInvitationLinkEvent(uri));
              } else {
                Navigator.of(context).pop();
              }
            } else if (chatServerM != null) {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => PasswordRegisterPage(
                      chatServer: chatServerM,
                      magicToken: magicToken,
                      invitationLink: uri)));
            }
          });
        } else {
          App.logger.warning("Link not valid.");
          _showInvalidLinkWarning(context);
          return false;
        }
      });
    } catch (e) {
      App.logger.severe(e);
      _showInvalidLinkWarning(context);
      return false;
    }

    return true;
  }

  void _showUrlUnmatchAlert() {
    final context = navigatorKey.currentContext!;
    showAppAlert(
        context: context,
        title: AppLocalizations.of(context)!.invitationLinkError,
        content: AppLocalizations.of(context)!.invitationLinkUrlNotMatch,
        actions: [
          AppAlertDialogAction(
              text: AppLocalizations.of(context)!.ok,
              action: () => Navigator.of(context).pop())
        ]);
  }

  void _showInvalidLinkWarning(BuildContext context) {
    showAppAlert(
        context: context,
        title: AppLocalizations.of(context)!.invalidInvitationLinkWarning,
        content:
            AppLocalizations.of(context)!.invalidInvitationLinkWarningContent,
        actions: [
          AppAlertDialogAction(
              text: AppLocalizations.of(context)!.ok,
              action: (() => Navigator.of(context).pop()))
        ]);
  }

  Widget _buildTextFieldPasteButton(
      BuildContext context, InvitationLinkTextFieldButtonType type) {
    Widget child;
    void Function()? onPressed;

    switch (type) {
      case InvitationLinkTextFieldButtonType.clear:
        child = Icon(CupertinoIcons.clear_circled_solid);
        onPressed = (() {
          _controller.clear();
          buttonType.value = InvitationLinkTextFieldButtonType.paste;
        });

        break;
      case InvitationLinkTextFieldButtonType.paste:
        child = Text(AppLocalizations.of(context)!.paste);
        onPressed = () async {
          ClipboardData? data = await Clipboard.getData('text/plain');
          if (data != null) {
            _controller.text = data.text ?? "";
            _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length));
            if (_controller.text.trim().isNotEmpty) {
              buttonType.value = InvitationLinkTextFieldButtonType.clear;
            } else {
              buttonType.value = InvitationLinkTextFieldButtonType.paste;
            }
          }
        };
        break;
      default:
        child = Icon(CupertinoIcons.clear_circled_solid);
        onPressed = (() {
          _controller.clear();
        });
    }
    return CupertinoButton(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: child,
        onPressed: onPressed);
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: FittedBox(
          child: VoceButton(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
            color: Colors.blue, borderRadius: BorderRadius.circular(16)),
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

  Widget _buildTitle(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(
          text: TextSpan(
        children: [
          TextSpan(
              text: AppLocalizations.of(context)!.inputInvitationLinkPageInput +
                  " ",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyan500)),
          TextSpan(
            text: AppLocalizations.of(context)!
                .inputInvitationLinkPageInvitationLink,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade700),
          ),
        ],
      )),
    ]);
  }
}
