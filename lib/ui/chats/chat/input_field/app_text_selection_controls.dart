import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_alert_dialog.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/models/local_kits.dart';
import 'package:vocechat_client/services/send_service.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble.dart';

class AppTextSelectionControls extends CupertinoTextSelectionControls {
  static const channelName = 'clipboard/image';
  final methodChannel = MethodChannel(channelName);
  int? uid;
  int? gid;

  // Function(ImageProvider) callback;
  AppTextSelectionControls();

  @override
  Future<void> handlePaste(TextSelectionDelegate delegate) async {
    try {
      final image = await _getClipboardImage();
      if (image != null) {
        _pasteImage(image);
      } else {
        final TextEditingValue value = delegate
            .textEditingValue; // Snapshot the input before using `await`.
        final ClipboardData? data =
            await Clipboard.getData(Clipboard.kTextPlain);

        if (data != null) {
          final updatedValue = TextEditingValue(
              text: value.selection.textBefore(value.text) + (data.text ?? ""),
              selection: TextSelection.collapsed(
                  offset: value.selection.start + (data.text?.length ?? 0)));
          delegate.userUpdateTextEditingValue(
              updatedValue, SelectionChangedCause.tap);
        }
      }
      delegate.bringIntoView(delegate.textEditingValue.selection.extent);
      delegate.hideToolbar();
    } catch (e) {
      App.logger.severe(e);
    }
  }

  void setChatInfo([int? uid, int? gid]) {
    this.uid = uid;
    this.gid = gid;
  }

  void _pasteImage(Uint8List imageBytes) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final imageWidget = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.memory(imageBytes),
    );
    showAppAlert(
        context: context,
        title: "Paste and Send Image",
        contentWidget: imageWidget,
        actions: [
          AppAlertDialogAction(
              text: "Cancel", action: (() => Navigator.of(context).pop()))
        ],
        primaryAction: AppAlertDialogAction(
            text: "Send",
            action: () {
              // return _send(path, type, uuid());
              SendService.singleton.sendMessage(uuid(), "", SendType.file,
                  blob: imageBytes, gid: gid, uid: uid);
              Navigator.of(context).pop();
            }));
  }

  Future<Uint8List?> _getClipboardImage() async {
    try {
      final result = await methodChannel.invokeMethod('getClipboardImage');
      if (result != null) return result as Uint8List;
    } on PlatformException catch (e) {
      App.logger.severe(e);
    }

    return null;
  }
}
