import 'package:flutter/material.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chat/input_field/mentions/models.dart';

/// A custom implementation of [TextEditingController] to support @ mention or other
/// trigger based mentions.
class AnnotationEditingController extends TextEditingController {
  // String? _pattern = "@";
  final TextStyle _mentionStyle = TextStyle(
      fontSize: 16, color: AppColors.primaryHover, fontWeight: FontWeight.w400);

  // Generate the Regex pattern for matching all the suggestions in one.
  AnnotationEditingController();

  @override
  TextSpan buildTextSpan(
      {BuildContext? context, TextStyle? style, bool? withComposing}) {
    var children = <InlineSpan>[];
    // print('mention [$text]');

    text.splitMapJoin(
      RegExp(r'\s@[0-9]+\s'),
      onMatch: (Match match) {
        final uidStr = match[0]?.substring(2);
        if (uidStr != null && uidStr.isNotEmpty) {
          final uid = int.parse(uidStr);
          children.add(WidgetSpan(
              alignment: PlaceholderAlignment.middle,
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
        children.add(TextSpan(text: text, style: style));
        return '';
      },
    );

    return TextSpan(children: children, style: style);
  }
}
