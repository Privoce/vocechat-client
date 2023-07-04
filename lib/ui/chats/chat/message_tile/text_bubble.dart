import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/extensions.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/tile_pages/full_text_page.dart';

// ignore: must_be_immutable
class TextBubble extends StatefulWidget {
  final String content;
  final bool edited;
  final bool hasMention;
  final bool enableCopy;
  final bool enableOg;
  final int? maxLines;
  final ChatMsgM? chatMsgM;
  final bool enableShowMoreBtn;

  late TextStyle _normalStyle;
  late TextStyle _mentionStyle;

  Map<String, dynamic>? openGraphicThumbnail;
  TextBubble(
      {Key? key,
      required this.content,
      this.edited = false,
      required this.hasMention,
      this.openGraphicThumbnail,
      this.enableCopy = false,
      this.enableOg = false,
      this.chatMsgM,
      this.maxLines,
      this.enableShowMoreBtn = false})
      : super(key: key) {
    _normalStyle = TextStyle(
        fontSize: 16,
        color: AppColors.coolGrey700,
        fontWeight: FontWeight.w400);
    _mentionStyle = TextStyle(
        fontSize: 16,
        color: AppColors.primaryBlue,
        fontWeight: FontWeight.w400);
  }

  @override
  State<TextBubble> createState() => _TextBubbleState();
}

class _TextBubbleState extends State<TextBubble> {
  @override
  Widget build(BuildContext context) {
    var children = <InlineSpan>[];

    widget.content.splitMapJoin(
      RegExp(urlRegEx),
      onMatch: (Match match) {
        String url = match[0]!;

        if (url.isNotEmpty) {
          // App.app.chatService.createOpenGraphicThumbnail(
          //     widget.content, widget.chatMsgM!.localMid, widget.chatMsgM);
          children.add(TextSpan(
              text: url,
              style: TextStyle(color: AppColors.primaryBlue),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  String _url = url;
                  if (_url.substring(0, 4) != 'http') {
                    _url = 'http://' + url;
                  }

                  try {
                    await SharedFuncs.appLaunchUrl(Uri.parse(_url));
                  } catch (e) {
                    App.logger.severe(e);
                    throw "error: $_url";
                  }
                }));
          if (widget.chatMsgM != null) {
            children.add(WidgetSpan(
                child: FutureBuilder<List<Map<String, dynamic>>?>(
              future:
                  App.app.chatService.getOpenGraphicThumbnail(widget.chatMsgM!),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  for (var item in snapshot.data!) {
                    final thumbnail = item['thumbnail'];
                    final url = item['url'];
                    final title = item['title'];
                    return Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          border:
                              Border.all(width: 1, color: Color(0xFFd4d4d4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(color: AppColors.primaryBlue),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Container(
                                clipBehavior: Clip.hardEdge,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(1),
                                ),
                                child: GestureDetector(
                                  onTap: () async {
                                    String url0 = url;
                                    try {
                                      await SharedFuncs.appLaunchUrl(
                                          Uri.parse(url0));
                                    } catch (e) {
                                      App.logger.severe(e);
                                      throw "error: $url0";
                                    }
                                  },
                                  child: Image.memory(thumbnail,
                                      fit: BoxFit.cover),
                                )),
                          ],
                        ));
                  }
                }
                return SizedBox.shrink();
              },
            )));
          }
          if (url.isYoutube) {
            if (url.substring(0, 4) != 'http') {
              url = 'https://' + url;
            }
            children.add(WidgetSpan(
              child: AnyLinkPreview(
                link: url,
                displayDirection: UIDirection.uiDirectionHorizontal,
                showMultimedia: true,
                bodyMaxLines: 5,
                bodyTextOverflow: TextOverflow.ellipsis,
                titleStyle: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                bodyStyle: TextStyle(color: Colors.black54, fontSize: 12),
                errorWidget: SizedBox.shrink(),
                cache: Duration(days: 7),
                backgroundColor: Color(0xFFF3F4F6),
                borderRadius: 1,
                removeElevation: false,
                // boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.grey)],
                onTap: () async {
                  try {
                    await SharedFuncs.appLaunchUrl(Uri.parse(url));
                  } catch (e) {
                    App.logger.severe(e);
                    throw "error: $url";
                  }
                }, // This disables tap event
              ),
            ));
          }
        }
        return '';
      },
      onNonMatch: (String text) {
        if (widget.hasMention) {
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
                      return Text(' @$mentionStr ',
                          style: widget._mentionStyle);
                    }
                    return Text(" @$uid ", style: widget._mentionStyle);
                  },
                )));
              }
              return '';
            },
            onNonMatch: (String text) {
              children.add(TextSpan(text: text, style: widget._normalStyle));
              return '';
            },
          );
          return '';
        } else {
          children.add(TextSpan(text: text, style: widget._normalStyle));
          return '';
        }
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
      if (widget.edited && !widget.enableCopy)
        TextSpan(
            text: " (${AppLocalizations.of(context)!.edited})",
            style: TextStyle(
                fontSize: 14,
                color: AppColors.navLink,
                fontWeight: FontWeight.w400))
    ]);

    Widget child = RichText(
        maxLines: widget.maxLines,
        text: textSpan,
        overflow: TextOverflow.ellipsis);
    if (widget.enableCopy) {
      child = SelectableText.rich(textSpan,
          maxLines: widget.maxLines,
          style: TextStyle(overflow: TextOverflow.ellipsis));
    }

    // Calculate placeholder size for widget spans.
    List<PlaceholderDimensions> values = [];
    for (final each in children) {
      if (each is WidgetSpan) {
        final size = each.toPlainText().isEmpty
            ? Size(40, 19)
            : _textSize(each.toPlainText(), widget._mentionStyle);
        final pd = PlaceholderDimensions(
            size: size, alignment: PlaceholderAlignment.baseline);
        values.add(pd);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = textSpan;
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
        tp.setPlaceholderDimensions(values);
        tp.layout(maxWidth: constraints.maxWidth);
        final numLines = tp.computeLineMetrics().length;

        if (widget.enableShowMoreBtn &&
            widget.maxLines != null &&
            numLines > widget.maxLines!) {
          return CupertinoButton(
              padding: EdgeInsets.zero,
              child: Wrap(
                children: [
                  child,
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("${AppLocalizations.of(context)!.tapForMore}...",
                            style: TextStyle(fontSize: 14))
                      ],
                    ),
                  )
                ],
              ),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => FullTextPage(
                        content: widget.content,
                        hasMention: widget.hasMention,
                        edited: widget.edited,
                        openGraphicThumbnail: widget.openGraphicThumbnail,
                        enableOg: widget.enableOg),
                  )));
        }
        return child;
      },
    );
  }

  Size _textSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }
}
