import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/ui/app_colors.dart';

class ConnectionStatusPage extends StatefulWidget {
  @override
  State<ConnectionStatusPage> createState() => _ConnectionStatusPageState();
}

class _ConnectionStatusPageState extends State<ConnectionStatusPage> {
  final ValueNotifier<SseStatus> sseNotifier = ValueNotifier(SseStatus.init);

  final ValueNotifier<TokenStatus> tokenNotifier =
      ValueNotifier(TokenStatus.init);

  @override
  void initState() {
    super.initState();

    App.app.statusService.subscribeSseLoading(_onSseStatus);
    App.app.statusService.subscribeTokenLoading(_onTokenStatus);
  }

  @override
  void dispose() {
    App.app.statusService.unsubscribeSseLoading(_onSseStatus);
    App.app.statusService.unsubscribeTokenLoading(_onTokenStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: Text("Connection Status",
            style: AppTextStyles.titleLarge,
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
        toolbarHeight: barHeight,
        elevation: 0,
        backgroundColor: AppColors.barBg,
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.close, color: AppColors.grey97)),
      ),
      body: SafeArea(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("SSE Status:"),
              ValueListenableBuilder<SseStatus>(
                  valueListenable: sseNotifier,
                  builder: (context, status, _) {
                    return Text(status.name);
                  }),
              CupertinoButton(onPressed: () {}, child: Text("Reconnect"))
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Token Status:"),
              ValueListenableBuilder<TokenStatus>(
                  valueListenable: tokenNotifier,
                  builder: (context, status, _) {
                    return Text(status.name);
                  }),
              CupertinoButton(onPressed: () {}, child: Text("Reconnect"))
            ],
          ),
        ],
      )),
    );
  }

  Future<void> _onSseStatus(SseStatus status) async {
    sseNotifier.value = status;
  }

  Future<void> _onTokenStatus(TokenStatus status) async {
    tokenNotifier.value = status;
  }
}
