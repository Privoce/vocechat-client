import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_alert_dialog.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:voce_widgets/voce_widgets.dart';
import 'package:vocechat_client/ui/auth/chat_server_helper.dart';
import 'package:vocechat_client/ui/auth/password_register_page.dart';

enum _InvitationLinkTextFieldButtonType { clear, paste }

class InvitationLinkPastePage extends StatelessWidget {
  late final BoxDecoration _bgDeco;

  final _centerColor = const Color.fromRGBO(0, 113, 236, 1);
  final _midColor = const Color.fromRGBO(162, 201, 243, 1);
  final _edgeColor = const Color.fromRGBO(233, 235, 237, 1);

  final TextEditingController _controller = TextEditingController();

  final ValueNotifier<_InvitationLinkTextFieldButtonType> buttonType =
      ValueNotifier(_InvitationLinkTextFieldButtonType.paste);

  InvitationLinkPastePage() {
    _bgDeco = BoxDecoration(
        gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 0.9,
            colors: [_centerColor, _midColor, _edgeColor],
            stops: const [0, 0.6, 1]));
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
                      _buildTitle(),
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
                  height: height,
                  onChanged: (_) {
                    final text = _controller.text;
                    if (text.trim().isNotEmpty) {
                      buttonType.value =
                          _InvitationLinkTextFieldButtonType.clear;
                    } else {
                      buttonType.value =
                          _InvitationLinkTextFieldButtonType.paste;
                    }
                  },
                )),
                // Flexible(child: TextField()),
                ValueListenableBuilder<_InvitationLinkTextFieldButtonType>(
                    valueListenable: buttonType,
                    builder: (context, type, _) {
                      return _buildTextFieldButton(type);
                    }),
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
            if (!(await _onLinkSubmitted(context))) {
              _showInvalidLinkWarning(context);
            }
            return true;
          },
        )
      ],
    );
  }

  Future<bool> _onLinkSubmitted(BuildContext context) async {
    final link = _controller.text.trim();

    try {
      Uri uri = Uri.parse(link);
      String host = uri.host;
      if (host == "privoce.voce.chat") {
        host = "dev.voce.chat";
      }
      final apiPath = uri.scheme + "://" + host;
      final userApi = UserApi(apiPath);
      final magicToken = uri.queryParameters["magic_token"] as String;

      final res = await userApi.checkMagicToken(magicToken);
      if (res.statusCode == 200 && res.data == true) {
        final chatServerM = await ChatServerHelper(context: context)
            .prepareChatServerM(apiPath);
        if (chatServerM != null) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => PasswordRegisterPage(
                    chatServer: chatServerM,
                  )));
        }
      } else {
        App.logger.warning("Link not valid.");
        return false;
      }
    } catch (e) {
      App.logger.severe(e);
      return false;
    }

    return true;
  }

  void _showInvalidLinkWarning(BuildContext context) {
    showAppAlert(
        context: context,
        title: "Invalid Invitation Link",
        content: "Please contact server admin for a new link or help.",
        actions: [
          AppAlertDialogAction(
              text: "OK", action: (() => Navigator.of(context).pop()))
        ]);
  }

  Widget _buildTextFieldButton(_InvitationLinkTextFieldButtonType type) {
    Widget child;
    void Function()? onPressed;

    switch (type) {
      case _InvitationLinkTextFieldButtonType.clear:
        child = Icon(CupertinoIcons.clear_circled_solid);
        onPressed = (() {
          _controller.clear();
          buttonType.value = _InvitationLinkTextFieldButtonType.paste;
        });

        break;
      case _InvitationLinkTextFieldButtonType.paste:
        child = Text("Paste");
        onPressed = () async {
          ClipboardData? data = await Clipboard.getData('text/plain');
          if (data != null) {
            _controller.text = data.text ?? "";
            _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length));
            if (_controller.text.trim().isNotEmpty) {
              buttonType.value = _InvitationLinkTextFieldButtonType.clear;
            } else {
              buttonType.value = _InvitationLinkTextFieldButtonType.paste;
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

  Widget _buildTitle() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(
          text: TextSpan(
        children: [
          TextSpan(
              text: "Input ",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyan500)),
          TextSpan(
            text: "Invitation Link",
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade700),
          ),
        ],
      )),
      // Text(widget.chatServerM.fullUrlWithoutPort,
      //     style: TextStyle(
      //         fontSize: 14,
      //         fontWeight: FontWeight.w400,
      //         color: AppColors.grey500)),
    ]);
  }
}
