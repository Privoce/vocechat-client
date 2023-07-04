import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_colors.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VoceTextBubble extends StatelessWidget {
  final ChatMsgM chatMsgM;

  late final String _content;

  late final bool _edited;
  late final bool _hasMention;
  late final TextStyle _normalStyle;
  late final TextStyle _mentionStyle;

  final int? maxLines;

  VoceTextBubble({Key? key, required this.chatMsgM, this.maxLines})
      : super(key: key) {
    _edited = chatMsgM.reactionData?.hasEditedText ?? false;
    _hasMention = chatMsgM.hasMention;

    if (chatMsgM.reactionData?.hasEditedText == true) {
      _content = chatMsgM.reactionData!.editedText!;
    } else {
      switch (chatMsgM.detailType) {
        case MsgDetailType.normal:
          _content = chatMsgM.msgNormal!.content;
          break;
        case MsgDetailType.reply:
          _content = chatMsgM.msgReply!.content;
          break;
        default:
          _content = chatMsgM.msgNormal!.content;
      }
    }

    _normalStyle = TextStyle(
        fontSize: 16,
        color: AppColors.coolGrey700,
        fontWeight: FontWeight.w400);
    _mentionStyle = TextStyle(
        fontSize: 16, color: AppColors.cyan500, fontWeight: FontWeight.w400);
  }

  @override
  Widget build(BuildContext context) {
    var children = <InlineSpan>[];

    _content.splitMapJoin(
      RegExp(urlRegEx, caseSensitive: false, dotAll: true),
      onMatch: (Match match) {
        String? url = match[0];

        if (url != null && url.isNotEmpty) {
          children.add(TextSpan(
              text: url,
              style: TextStyle(color: AppColors.primaryBlue),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  String url0 = url;
                  if (url0.substring(0, 4) != 'http') {
                    url0 = 'http://$url';
                  }

                  try {
                    await SharedFuncs.appLaunchUrl(Uri.parse(url0));
                  } catch (e) {
                    App.logger.severe(e);
                    throw "error: $url0";
                  }
                }));
        }
        return "";
      },
      onNonMatch: (String text) {
        if (_hasMention) {
          text.splitMapJoin(
            RegExp(r'\s@[0-9]+\s'),
            onMatch: (Match match) {
              final uidStr = match[0]?.substring(2);
              if (uidStr != null && uidStr.isNotEmpty) {
                final uid = int.parse(uidStr);
                children.add(WidgetSpan(
                    child: FutureBuilder<UserInfoM?>(
                  future: UserInfoDao().getUserByUid(uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final mentionStr = snapshot.data!.userInfo.name;
                      return Text(' @$mentionStr ', style: _mentionStyle);
                    }
                    return Text(" @$uid ", style: _mentionStyle);
                  },
                )));
              }
              return '';
            },
            onNonMatch: (String text) {
              children.add(TextSpan(text: text, style: _normalStyle));
              return '';
            },
          );
        } else {
          children.add(TextSpan(text: text, style: _normalStyle));
        }
        return "";
      },
    );

    TextSpan textSpan = TextSpan(children: [
      TextSpan(
        children: children,
        style: TextStyle(
            fontSize: 16,
            color: AppColors.coolGrey700,
            fontWeight: FontWeight.w400),
      ),
      if (_edited)
        TextSpan(
            text: " (${AppLocalizations.of(context)!.edited})",
            style: TextStyle(
                fontSize: 14,
                color: AppColors.navLink,
                fontWeight: FontWeight.w400))
    ]);

    return RichText(
      maxLines: maxLines,
      text: textSpan,
    );
  }
}
