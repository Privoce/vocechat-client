import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:voce_widgets/voce_widgets.dart';
import 'package:vocechat_client/api/lib/admin_login_api.dart';
import 'package:vocechat_client/api/lib/admin_system_api.dart';
import 'package:vocechat_client/api/lib/resource_api.dart';
import 'package:vocechat_client/app_alert_dialog.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/dao/org_dao/properties_models/chat_server_properties.dart';
import 'package:vocechat_client/services/db.dart';
import 'package:vocechat_client/ui/auth/login_page.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ServerPage extends StatefulWidget {
  // static const route = '/auth/server';

  late final BoxDecoration _bgDeco;

  final bool showClose;

  final _centerColor = const Color.fromRGBO(0, 113, 236, 1);
  final _midColor = const Color.fromRGBO(162, 201, 243, 1);
  final _edgeColor = const Color.fromRGBO(233, 235, 237, 1);

  ServerPage({Key? key, this.showClose = false}) : super(key: key) {
    _bgDeco = BoxDecoration(
        gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 0.9,
            colors: [_centerColor, _midColor, _edgeColor],
            stops: const [0, 0.6, 1]));
  }

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  // textField params
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();

  // data
  final ValueNotifier<List<ChatServerM>> _serverListNotifier =
      ValueNotifier([]);

  // as a server might be added multiple times, use set to avoid.
  Set<String> _serverIdSet = {};

  // UI params
  final double _outerRadius = 10;

  final ValueNotifier<bool> _isUrlValid = ValueNotifier(false);
  final ValueNotifier<bool> _showUrlWarning = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _getServerList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: widget._edgeColor,
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
                        widget.showClose
                            ? _buildTopBtn(context)
                            : SizedBox(height: 60),
                        _buildTitle(),
                        const SizedBox(height: 50),
                        _buildUrlTextField(),
                        const SizedBox(height: 20),
                        _buildHistoryList(),
                      ]),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VoceButton(
              normal: Text(AppLocalizations.of(context)!.serverPageClearData),
              action: () async {
                _onResetDb(context);
                return true;
              },
            ),
            SizedBox(
              height: 30,
              child: FutureBuilder<String>(
                  future: _getVersion(),
                  builder: ((context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        "Version: ${snapshot.data}",
                        style: AppTextStyles.labelSmall(),
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  })),
            )
          ],
        )));
  }

  Future<String> _getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;
    return version + "($buildNumber)";
  }

  void _onResetDb(BuildContext context) async {
    showAppAlert(
        context: context,
        title: "Clear Local Data",
        content:
            "VoceChat will be terminated. All your data will be deleted locally.",
        primaryAction: AppAlertDialogAction(
            text: "OK", isDangerAction: true, action: _onReset),
        actions: [
          AppAlertDialogAction(
              text: "Cancel", action: () => Navigator.pop(context, 'Cancel'))
        ]);
  }

  void _onReset() async {
    try {
      await closeAllDb();
    } catch (e) {
      App.logger.severe(e);
    }

    try {
      await removeDb();
    } catch (e) {
      App.logger.severe(e);
    }

    exit(0);
  }

  Widget _buildTopBtn(BuildContext context) {
    return FittedBox(
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: SizedBox(
          height: 60,
          child: Center(
            child: Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.all(3),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                )),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        AppLocalizations.of(context)!.serverPageWelcomeFirstLine,
        style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color.fromRGBO(5, 100, 242, 0.6)),
      ),
      Text(AppLocalizations.of(context)!.serverPageWelcomeSecondLine,
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color.fromRGBO(5, 100, 242, 1))),
    ]);
  }

  Widget _buildUrlTextField() {
    const double textFieldHeight = 16 + 12 + 12;

    _urlController.selection = TextSelection.fromPosition(
        TextPosition(offset: _urlController.text.length));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.serverPageHostServer,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: VoceTextField.filled(
                _urlController,
                focusNode: _urlFocusNode,
                height: 40,
                borderRadius: _outerRadius,
                maxLength: 32,
                onSubmitted: (_) => _onUrlSubmit(),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                scrollPadding: EdgeInsets.only(bottom: 100),
                onChanged: (url) {
                  _isUrlValid.value = isUrlValid(url);
                  _showUrlWarning.value = shouldShowUrlAlert(url);
                },
              ),
            ),
            const SizedBox(width: 10),
            _buildSubmitBtn(textFieldHeight),
          ],
        ),
        SizedBox(
            height: 28.0,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ValueListenableBuilder<bool>(
                valueListenable: _showUrlWarning,
                builder: (context, showUrlWarning, child) {
                  if (showUrlWarning) {
                    return Text(
                      "Invalid Url Format",
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

  Widget _buildSubmitBtn(double textFieldHeight) {
    final double radius = textFieldHeight / 2;
    final iconSize = radius * 1.414;
    return VoceButton(
      height: textFieldHeight,
      width: textFieldHeight,
      contentPadding: EdgeInsets.all(4),
      enabled: _isUrlValid,
      decoration: BoxDecoration(
          color: Colors.blue, borderRadius: BorderRadius.circular(radius)),
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
        return await _onUrlSubmit();
      },
    );
  }

  Widget _buildHistoryList() {
    return ValueListenableBuilder<List<ChatServerM>>(
      valueListenable: _serverListNotifier,
      builder: (_, serverList, __) {
        if (serverList.isEmpty) {
          return SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.serverPageHistory,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Container(
              // constraints: BoxConstraints(maxHeight: 300),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_outerRadius)),
              child: ListView.separated(
                  separatorBuilder: (context, index) {
                    return const Divider();
                  },
                  shrinkWrap: true,
                  itemCount: serverList.length,
                  itemBuilder: (context, index) {
                    final item = serverList[index];
                    String tls = 'http://';
                    if (item.tls == 1) {
                      tls = 'https://';
                    }
                    return Slidable(
                      endActionPane: ActionPane(
                        extentRatio: 0.3,
                        motion: DrawerMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) {
                              _onDeleteHistory(context, index);
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                        ],
                      ),
                      child: ListTile(
                        dense: true,
                        leading: item.logo.isNotEmpty
                            ? SizedBox(
                                height: 36,
                                child: Image.memory(item.logo,
                                    fit: BoxFit.contain))
                            : Icon(Icons.desktop_mac),
                        onTap: () async {
                          await ChatServerDao.dao.updateUpdatedAt(
                              item, DateTime.now().millisecondsSinceEpoch);
                          _urlController.text = item.fullUrl;
                        },
                        title: Text(
                          prepareServerTitle(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16),
                        ),
                        subtitle: Text(
                          "$tls${item.url}:${item.port}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  }),
            ),
          ],
        );
      },
    );
  }

  String prepareServerTitle(ChatServerM chatServerM) {
    try {
      final serverName = chatServerM.properties.serverName;
      return serverName;
    } catch (e) {
      App.logger.warning(e);
      return chatServerM.url;
    }
  }

  bool shouldShowUrlAlert(String url) {
    return url.isNotEmpty && !url.isUrl;
  }

  bool isUrlValid(String url) {
    return url.isNotEmpty && url.isUrl;
  }

  void _getServerList() async {
    try {
      final serverList = await ChatServerDao.dao.getServerList();
      if (serverList != null && serverList.isNotEmpty) {
        final latest = serverList.first;
        String u = latest.url;
        if (latest.tls == 0) {
          u = 'http://' + u;
        } else {
          u = 'https://' + u;
        }

        for (var server in serverList) {
          if (_serverIdSet.contains(server.id)) {
            continue;
          }
          _serverIdSet.add(server.id);
        }
        _serverListNotifier.value.addAll(serverList);
      }

      _serverListNotifier.value
          .sort((s1, s2) => s2.updatedAt.compareTo(s1.updatedAt));
      _urlController.text = _serverListNotifier.value.first.fullUrl;

      _isUrlValid.value = isUrlValid(_urlController.text);
      _showUrlWarning.value = shouldShowUrlAlert(_urlController.text);

      setState(() {});

      return;
    } catch (e) {
      App.logger.severe(e);
    }
  }

  /// Called when forward (->) button is pressed.
  ///
  /// Server information will be saved into App object.
  /// Only successful server visits will be saved.
  Future<bool> _onUrlSubmit() async {
    final url = _urlController.text + "/api";

    // Update server record in database
    ChatServerM chatServerM = ChatServerM();

    if (!chatServerM.setByUrl(url)) {
      App.logger.severe("ChatServer setup failed.");
      return false;
    }

    // try {
    final adminSystemApi = AdminSystemApi(chatServerM.fullUrl);

    // Check if server has been initialized
    final initializedRes = await adminSystemApi.getInitialized();
    if (initializedRes.statusCode != 200 || initializedRes.data != true) {
      await showAppAlert(
          context: context,
          title: "Server Not Initialized",
          content: "Please user web client for initialization.",
          actions: [
            AppAlertDialogAction(
                text: "Cancel", action: () => Navigator.of(context).pop()),
            AppAlertDialogAction(
                text: "Copy Url",
                action: () {
                  Navigator.of(context).pop();

                  final url = "${chatServerM.fullUrl}/#/onboarding";
                  Clipboard.setData(ClipboardData(text: url));
                })
          ]);
      return false;
    }

    final orgInfoRes = await adminSystemApi.getOrgInfo();
    if (orgInfoRes.statusCode == 200 && orgInfoRes.data != null) {
      App.logger.info(orgInfoRes.data!.toJson().toString());
      final orgInfo = orgInfoRes.data!;
      chatServerM.properties = ChatServerProperties(
          serverName: orgInfo.name, description: orgInfo.description ?? "");

      final resourceApi = ResourceApi(chatServerM.fullUrl);
      final logoRes = await resourceApi.getOrgLogo();
      if (logoRes.statusCode == 200 && logoRes.data != null) {
        chatServerM.logo = logoRes.data!;
      }

      final AdminLoginApi adminLoginApi = AdminLoginApi(chatServerM.fullUrl);
      final adminLoginRes = await adminLoginApi.getConfig();
      if (adminLoginRes.statusCode == 200 && adminLoginRes.data != null) {
        chatServerM.properties = ChatServerProperties(
            serverName: orgInfo.name,
            description: orgInfo.description ?? "",
            config: adminLoginRes.data);
      }

      chatServerM.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await ChatServerDao.dao.addOrUpdate(chatServerM);
    } else {
      await showAppAlert(
          context: context,
          title: "Server Connection Error",
          content:
              "VoceChat can't retrieve server info. Please contact server owner for help.",
          actions: [
            AppAlertDialogAction(
              text: "OK",
              action: () {
                Navigator.of(context).pop();
              },
            )
          ]);
      return false;
    }
    // } catch (e) {
    //   App.logger.severe(e);

    //   await showAppAlert(
    //       context: context,
    //       title: "Server Connection Error",
    //       content:
    //           "VoceChat can't retrieve server info. Please contact server owner for help.",
    //       actions: [
    //         AppAlertDialogAction(
    //           text: "OK",
    //           action: () {
    //             Navigator.of(context).pop();
    //           },
    //         )
    //       ]);

    //   return false;
    // }

    // Set server in App singleton.
    App.app.chatServerM = chatServerM;

    _urlFocusNode.requestFocus();

    // Navigator.pushNamed(context, LoginPage.route, arguments: chatServerM)
    //     .then((_) {
    //   _resetServerList();
    // });
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => LoginPage(chatServerM: chatServerM)));

    return true;
  }

  void _resetServerList() {
    _serverListNotifier.value = [];
    _serverIdSet = {};

    _getServerList();
  }

  void _onDeleteHistory(BuildContext context, int index) async {
    try {
      final id = _serverListNotifier.value[index].id;
      _serverListNotifier.value.removeAt(index);
      _serverIdSet.remove(id);
      await ChatServerDao.dao.remove(id);
      setState(() {});
    } catch (e) {
      App.logger.severe(e);
    }
  }

  // void _onPinHistory(BuildContext context, int index) async {
  //   try {
  //     ChatServerM server = _serverListNotifier.value[index];
  //     server.pin = 1;
  //     _serverListNotifier.value.sort((a, b) => (a.pin - b.pin));
  //     await ChatServerDao.dao.addOrReplace(server);
  //     setState(() {});
  //   } catch (e) {
  //     App.logger.severe(e);
  //   }
  // }
}
