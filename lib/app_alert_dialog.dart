import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/app_colors.dart';

class AppAlertDialogAction {
  String text;

  /// Font will be red and bold if set true.
  bool isDangerAction;
  VoidCallback action;

  AppAlertDialogAction(
      {required this.text, required this.action, this.isDangerAction = false});
}

Future<T?> showAppAlert<T>(
    {required BuildContext context,
    required String title,
    required String content,
    AppAlertDialogAction? primaryAction,
    required List<AppAlertDialogAction> actions}) {
  List<Widget> _actions = [];

  for (final action in actions) {
    if (Platform.isIOS) {
      _actions.add(
          CupertinoButton(child: Text(action.text), onPressed: action.action));
    } else {
      _actions
          .add(TextButton(child: Text(action.text), onPressed: action.action));
    }
  }

  if (primaryAction != null) {
    Widget pa;
    if (Platform.isIOS) {
      pa = CupertinoButton(
          child: Text(primaryAction.text,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: primaryAction.isDangerAction
                      ? AppColors.errorRed
                      : null)),
          onPressed: primaryAction.action);
    } else {
      pa = TextButton(
          onPressed: primaryAction.action,
          child: Text(primaryAction.text,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: primaryAction.isDangerAction
                      ? AppColors.errorRed
                      : null)));
    }
    _actions.add(pa);
  }

  return showDialog(
      context: context,
      builder: (context) {
        if (Platform.isIOS) {
          return CupertinoAlertDialog(
            title: Text(title),
            content: Text(content),
            actions: _actions,
          );
        } else {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: _actions,
          );
        }
      });
}
