import 'package:flutter/material.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_user_avatar.dart';

class ContactTile extends StatefulWidget {
  final UserInfoM userInfoM;
  final bool isSelf;
  final bool disabled;
  final Widget? mark;
  final double avatarSize;
  final bool? selected;
  final bool enableSubtitleEmail;
  final void Function()? onTap;

  late final Widget _avatar;

  ContactTile(this.userInfoM, this.isSelf,
      {this.avatarSize = VoceAvatarSize.s36,
      this.disabled = false,
      this.mark,
      this.onTap,
      this.selected,
      this.enableSubtitleEmail = false,
      Key? key})
      : super(key: key) {
    _avatar = VoceUserAvatar.user(
        key: ObjectKey(userInfoM),
        userInfoM: userInfoM,
        size: avatarSize,
        enableOnlineStatus: true);
  }

  @override
  State<ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<ContactTile> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
        tileColor: Colors.white,
        onTap: widget.onTap,
        enabled: !widget.disabled,
        leading: widget._avatar,
        title: Row(
          children: [
            Expanded(
              child: RichText(
                  text: TextSpan(
                style: AppTextStyles.listTileTitle,
                children: [
                  TextSpan(text: widget.userInfoM.userInfo.name),
                  // TextSpan(text: "ashdgoasdghsadgsdsdjkasdghsadgsdsdjkgaods"),
                  if (widget.isSelf)
                    TextSpan(
                        text: " (you)",
                        style: TextStyle(
                            color: AppColors.grey700,
                            fontSize: 14,
                            fontWeight: FontWeight.w400))
                ],
              )),
            ),
            if (widget.mark != null) SizedBox(width: 8),
            if (widget.mark != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: widget.mark!,
              ),
            if (widget.selected != null) SizedBox(width: 8),
            if (widget.selected != null)
              widget.selected!
                  ? Icon(AppIcons.select, color: Colors.cyan, size: 24)
                  : SizedBox(width: 24),
            SizedBox(width: 24)
          ],
        ),
        subtitle: widget.enableSubtitleEmail
            ? (widget.userInfoM.userInfo.email != null &&
                    widget.userInfoM.userInfo.email!.isNotEmpty)
                ? Text(
                    widget.userInfoM.userInfo.email!,
                    style: AppTextStyles.labelMedium,
                  )
                : null
            : null);
  }
}
