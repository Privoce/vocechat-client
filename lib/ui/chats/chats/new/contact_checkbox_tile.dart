import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/app_colors.dart';

class ContactCheckBoxTile extends StatefulWidget {
  final String name;
  final bool isSelf;
  final Uint8List avatarBytes;
  final bool initSelectValue;
  final Function(bool?) onChange;

  late final Widget _avatar;

  ContactCheckBoxTile(this.name, this.isSelf, this.avatarBytes,
      this.initSelectValue, this.onChange,
      {Key? key})
      : super(key: key) {
    if (avatarBytes.isEmpty) {
      _avatar = CircleAvatar(child: Text(name.substring(0, 1)));
    } else {
      _avatar = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
                fit: BoxFit.fill, image: MemoryImage(avatarBytes))),
      );
    }
  }

  @override
  State<ContactCheckBoxTile> createState() => _ContactCheckBoxTileState();
}

class _ContactCheckBoxTileState extends State<ContactCheckBoxTile> {
  late bool isSelected;

  @override
  void initState() {
    super.initState();
    isSelected = widget.initSelectValue;
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.isSelf ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: () {
          if (widget.isSelf) {
            return;
          } else {
            setState(() {
              isSelected = !isSelected;
              widget.onChange(isSelected);
            });
          }
        },
        child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                isSelected
                    ? Icon(Icons.check_box_outlined,
                        color: Colors.cyan, size: 30)
                    : Icon(Icons.check_box_outline_blank_rounded,
                        color: Colors.cyan, size: 30),
                SizedBox(width: 10),
                widget._avatar,
              ],
            ),
            title: RichText(
                text: TextSpan(
              style: TextStyle(
                  color: AppColors.grey600,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
              children: [
                TextSpan(text: widget.name),
                if (widget.isSelf)
                  TextSpan(
                      text: " (you)",
                      style: TextStyle(
                          color: AppColors.grey97,
                          fontSize: 14,
                          fontWeight: FontWeight.w600))
              ],
            ))),
      ),
    );
  }
}
