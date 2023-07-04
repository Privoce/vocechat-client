import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AvatarInfoTile extends StatelessWidget {
  final Widget avatar;
  // final Widget title;
  // final Widget sub
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? subtitleWidget;
  final VoidCallback? onTap;
  final bool enableEdit;

  AvatarInfoTile(
      {required this.avatar,
      this.title,
      this.titleWidget,
      this.subtitle,
      this.subtitleWidget,
      this.onTap,
      this.enableEdit = false}) {
    if (enableEdit) {
      assert(onTap != null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // return ListTile(
    //   leading: avatar,
    //   title: title,
    // );
    // return SizedBox(
    //   width: double.maxFinite,
    //   child: Padding(
    //     padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    //     child: Row(children: [
    //       avatar,
    //       Padding(
    //         padding: const EdgeInsets.only(left: 16.0),
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           mainAxisAlignment: MainAxisAlignment.start,
    //           children: [Text(title), if (subtitle != null) Text(subtitle!)],
    //         ),
    //       )
    //     ]),
    //   ),
    // );
    return Stack(
      children: [
        Container(
          color: Colors.white,
          width: double.maxFinite,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatar,
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: titleWidget != null
                      ? titleWidget!
                      : title != null
                          ? Text(title!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.titleLarge)
                          : SizedBox.shrink(),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(subtitle!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelMedium),
                  ),
                if (subtitleWidget != null) subtitleWidget!
              ],
            ),
          ),
        ),
        if (enableEdit)
          Positioned(
              top: 20,
              right: 16,
              child: CupertinoButton(
                  child: Text(
                    AppLocalizations.of(context)!.edit,
                    style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 17,
                        color: AppColors.primaryBlue),
                  ),
                  onPressed: () {
                    if (enableEdit && onTap != null) {
                      return onTap!();
                    }
                  }))
      ],
    );
  }
}
