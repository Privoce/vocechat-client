import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/text_bubble.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FullTextPage extends StatelessWidget {
  final String content;
  final bool edited;
  final bool hasMention;
  final bool enableOg;
  Map<String, dynamic>? openGraphicThumbnail;

  FullTextPage(
      {required this.content,
      this.edited = false,
      required this.hasMention,
      this.openGraphicThumbnail,
      this.enableOg = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.barBg,
        title: Text(
          "Message Detail",
          style: AppTextStyles.titleLarge(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextBubble(
              content: content,
              hasMention: hasMention,
              edited: edited,
              openGraphicThumbnail: openGraphicThumbnail,
              enableCopy: true,
              enableOg: enableOg,
              maxLines: null,
              // enableExpand: false,
            ),
          ),
        ),
      ),
    );
  }
}
