import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VoceMdBubble extends StatelessWidget {
  final ChatMsgM chatMsgM;

  late final String? _mdText;
  // TODO: reaction refactor
  // late final bool _edited;

  VoceMdBubble({Key? key, required this.chatMsgM}) : super(key: key) {
    _mdText = chatMsgM.msgNormal?.content;
    // TODO: reaction refactor
    // _edited = chatMsgM.edited;
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
            launchUrlString(url);
          }
        },
      ),
      // TODO: reaction refactor
      // if (_edited)
      //   Text(" (${AppLocalizations.of(context)!.edited})",
      //       style: TextStyle(
      //           fontSize: 14,
      //           color: AppColors.navLink,
      //           fontWeight: FontWeight.w400))
    ]);
  }
}
