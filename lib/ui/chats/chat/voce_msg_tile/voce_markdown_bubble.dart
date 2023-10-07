import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_colors.dart';

class VoceMdBubble extends StatelessWidget {
  final ChatMsgM chatMsgM;

  late final String? _mdText;

  late final bool _edited;

  VoceMdBubble({Key? key, required this.chatMsgM}) : super(key: key) {
    _mdText = chatMsgM.msgNormal?.content ?? chatMsgM.msgReply?.content;

    _edited = chatMsgM.reactionData?.hasEditedText ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(children: [
      MarkdownBody(
        data: _mdText ?? AppLocalizations.of(context)!.noContent,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
            a: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: AppColors.coolGrey700)),
        onTapLink: (text, url, title) {
          if (url != null) {
            SharedFuncs.appLaunchUrl(Uri.parse(url));
          }
        },
      ),
      if (_edited)
        Text(" (${AppLocalizations.of(context)!.edited})",
            style: TextStyle(
                fontSize: 14,
                color: AppColors.navLink,
                fontWeight: FontWeight.w400))
    ]);
  }
}
