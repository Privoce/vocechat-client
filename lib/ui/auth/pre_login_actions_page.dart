import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_alert_dialog.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/services/db.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/auth/invitation_link_page.dart';
import 'package:vocechat_client/ui/widgets/sheet_app_bar.dart';
import 'package:voce_widgets/voce_widgets.dart';

class PreLoginActionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          SheetAppBar(
            title: Text(
              "Actions",
              style: AppTextStyles.titleLarge,
            ),
            leading: CupertinoButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Icon(Icons.close, color: AppColors.grey97)),
            // actions: [_buildAddBtn()],
          ),
          Flexible(child: _buildActions(context))
          // Flexible(child: _buildMembersTab())
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          VoceButton(
            width: double.maxFinite,
            contentColor: Colors.white,
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8)),
            normal: Text(
              "Paste Invitation Link",
              style: TextStyle(color: Colors.white),
            ),
            action: () async {
              Navigator.of(context).pop();
              _onPasteInvitationLinkTapped(context);
              return true;
            },
          ),
          SizedBox(height: 16),
          VoceButton(
            width: double.maxFinite,
            contentColor: Colors.white,
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8)),
            normal: Text(
              "Clear Local Data",
              style: TextStyle(color: Colors.white),
            ),
            action: () async {
              Navigator.of(context).pop();
              _onResetDb();
              return true;
            },
          ),
        ],
      ),
    );
  }

  void _onPasteInvitationLinkTapped(BuildContext context) async {
    final route = PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          InvitationLinkPage(),
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

  void _onResetDb() async {
    if (navigatorKey.currentState?.context == null) return;

    final context = navigatorKey.currentState!.context;

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
}
