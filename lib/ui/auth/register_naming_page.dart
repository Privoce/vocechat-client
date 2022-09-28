import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/api/models/user/register_request.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_alert_dialog.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/services/auth_service.dart';
import 'package:vocechat_client/services/status_service.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chats/chats_main_page.dart';
import 'package:voce_widgets/voce_widgets.dart';

class RegisterNamingPage extends StatefulWidget {
  late final BoxDecoration _bgDeco;
  late ChatServerM _chatServer;

  RegisterRequest req;

  RegisterNamingPage(this.req, {Key? key}) : super(key: key) {
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
    _chatServer = App.app.chatServerM;
  }

  @override
  State<RegisterNamingPage> createState() => _RegisterNamingPageState();
}

class _RegisterNamingPageState extends State<RegisterNamingPage> {
  final double cornerRadius = 10.0;

  final TextEditingController nameController = TextEditingController();

  ValueNotifier<bool> showNameWarning = ValueNotifier(false);
  ValueNotifier<bool> enableContinue = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    // showNameWarning.value = _showNameWarning(nameController.text);
    enableContinue.value = _enableContinueButton(nameController.text);
  }

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
                      _buildNaming(),
                      SizedBox(height: 10.0),
                      _buildContinueBtn()
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
              color: Colors.blue, borderRadius: BorderRadius.circular(16)),
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
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
        children: [
          Text(
            'Sign up to ',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.cyan500),
          ),
          Text(
            widget._chatServer.properties.serverName,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade700),
          ),
        ],
      ),
      Text(widget._chatServer.fullUrl,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.grey500)),
    ]);
  }

  Widget _buildNaming() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s your name',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.grey800),
        ),
        SizedBox(height: 8),
        Text(
          "Enter a name so people know how you'd like to be called. Your name will only be visible to others in spaces you joined.",
          style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: AppColors.grey500),
        ),
        SizedBox(height: 16),
        VoceTextField.filled(
          nameController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          scrollPadding: EdgeInsets.only(bottom: 100),
          maxLength: 32,
          onChanged: ((name) {
            showNameWarning.value = _showNameWarning(name);
            enableContinue.value = _enableContinueButton(name);
          }),
        ),
        SizedBox(
            height: 28.0,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ValueListenableBuilder<bool>(
                valueListenable: showNameWarning,
                builder: (context, showNameWarning, child) {
                  if (showNameWarning) {
                    return Text(
                      "Invalid Name Format",
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            )),
      ],
    );
  }

  Widget _buildContinueBtn() {
    return VoceButton(
        width: double.maxFinite,
        contentColor: Colors.white,
        enabled: enableContinue,
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(8)),
        normal: Text("Continue", style: TextStyle(color: Colors.white)),
        action: _onTapContinue);
  }

  bool _showNameWarning(String name) {
    return name.trim().isEmpty;
  }

  bool _enableContinueButton(String name) {
    return name.trim().isNotEmpty;
  }

  Future<bool> _onTapContinue() async {
    final username = nameController.text.trim();

    if (username.isEmpty) {
      return false;
    }

    widget.req.name = username;

    try {
      String deviceToken = "";
      String device;
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

      widget.req.device = device;
      widget.req.deviceToken = deviceToken;

      App.app.statusService = StatusService();
      App.app.authService = AuthService(chatServerM: App.app.chatServerM);

      UserApi userApi = UserApi(App.app.chatServerM.fullUrl);
      final res = await userApi.register(widget.req);
      if (res.statusCode == 200 && res.data != null) {
        final registerResponse = res.data!;
        await App.app.authService?.initServices(registerResponse);
        Navigator.of(context)
            .pushNamedAndRemoveUntil(ChatsMainPage.route, (route) => false);
        App.app.chatService.initSse();
        return true;
      }
    } catch (e) {
      App.logger.severe(e);

      showAppAlert(
          context: context,
          title: "Sign Up Failed",
          content:
              "Something wrong happened. Please try again later or contact us for help.",
          actions: [
            AppAlertDialogAction(
              text: "OK",
              action: () {
                Navigator.pop(context);
              },
            )
          ]);

      return false;
    }
    return false;
  }
}
