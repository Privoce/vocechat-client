import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MarkdownBubble extends StatelessWidget {
  final String markdownText;
  final bool edited;

  MarkdownBubble({required this.markdownText, this.edited = false});

  @override
  Widget build(BuildContext context) {
    return Wrap(children: [
      MarkdownBody(
        data: markdownText,
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
      if (edited)
        Text(" (${AppLocalizations.of(context)!.edited})",
            style: TextStyle(
                fontSize: 14,
                color: AppColors.navLink,
                fontWeight: FontWeight.w400))
    ]);
  }
}
