import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/app_colors.dart';

// ignore: must_be_immutable
class ChatTileSimplified extends StatefulWidget {
  final Widget? avatar;
  late final Widget _avatar;
  final String name;
  ValueNotifier<int> unreadCount = ValueNotifier(0);

  ChatTileSimplified({required this.name, this.avatar}) {
    if (avatar == null) {
      _avatar = CircleAvatar(child: Text(name.substring(0, 1)), radius: 24);
    } else {
      _avatar = avatar!;
    }
  }

  @override
  State<ChatTileSimplified> createState() => _ChatTileSimplifiedState();
}

class _ChatTileSimplifiedState extends State<ChatTileSimplified> {
  late Widget avatar;

  @override
  void initState() {
    super.initState();
    avatar = widget._avatar;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 40,
      padding: EdgeInsets.only(left: 10, right: 11, top: 8, bottom: 5),
      child: Row(
        children: [
          widget._avatar,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 17,
                            color: AppColors.grey700,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.41),
                      )),
                      if (widget.unreadCount.value > 0)
                        ValueListenableBuilder<int>(
                            valueListenable: widget.unreadCount,
                            builder: (context, value, _) {
                              return Container(
                                  constraints: BoxConstraints(minWidth: 16),
                                  height: 16,
                                  decoration: BoxDecoration(
                                      color: AppColors.primary400,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: Text(
                                        "$value",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10),
                                      ),
                                    ),
                                  ));
                            })
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
