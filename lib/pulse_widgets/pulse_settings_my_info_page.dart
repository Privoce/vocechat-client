import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vocechat_client/api/models/user/user_info.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/helpers/time_helper.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_user_avatar.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile.dart';
import 'package:vocechat_client/ui/widgets/banner_tile/banner_tile_group.dart';

class PulseSettingsMyInfoPage extends StatelessWidget {
  final ValueNotifier<UserInfoM?> userInfoNotifier;
  const PulseSettingsMyInfoPage({required this.userInfoNotifier, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: barHeight,
        elevation: 0,
        // backgroundColor: AppColors.barBg,
        leading: CupertinoButton(
            child: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
            onPressed: () => Navigator.pop(context)),
        title: Text(AppLocalizations.of(context)!.settingsPageMyInfo),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BannerTileGroup(bannerTileList: [
      BannerTile(
        title: AppLocalizations.of(context)!.avatar,
        height: 56,
        trailing: ValueListenableBuilder<UserInfoM?>(
            valueListenable: userInfoNotifier,
            builder: (context, userInfoM, child) {
              return VoceUserAvatar.user(
                  userInfoM: userInfoM!,
                  size: VoceAvatarSize.s36,
                  enableOnlineStatus: false);
            }),
      ),
      BannerTile(
          title: AppLocalizations.of(context)!.nickname,
          trailing: ValueListenableBuilder<UserInfoM?>(
              valueListenable: userInfoNotifier,
              builder: (context, userInfoM, child) {
                return Text(userInfoM!.userInfo.name);
              })),
      BannerTile(
          title: AppLocalizations.of(context)!.gender,
          trailing: ValueListenableBuilder<UserInfoM?>(
              valueListenable: userInfoNotifier,
              builder: (context, userInfoM, child) {
                String genderStr;
                switch (userInfoM!.userInfo.genderType) {
                  case Gender.male:
                    genderStr = AppLocalizations.of(context)!.male;
                    break;
                  case Gender.female:
                    genderStr = AppLocalizations.of(context)!.female;
                    break;
                  default:
                    genderStr = AppLocalizations.of(context)!.other;
                }

                return Text(genderStr);
              })),
      BannerTile(
          title: AppLocalizations.of(context)!.birthday,
          trailing: ValueListenableBuilder<UserInfoM?>(
              valueListenable: userInfoNotifier,
              builder: (context, userInfoM, child) {
                if (userInfoM!.userInfo.birthday == null ||
                    userInfoM.userInfo.birthday == 0) {
                  return Text('-');
                } else {
                  final dateTime = DateTime.fromMillisecondsSinceEpoch(
                      userInfoM.userInfo.birthday ?? 0);
                  final dateStr = DateFormat('yyyy/MM/dd').format(dateTime);
                  return Text(dateStr);
                }
              })),
      BannerTile(
          title: AppLocalizations.of(context)!.qrCode,
          trailing: Icon(CupertinoIcons.qrcode)),
      BannerTile(
          title: AppLocalizations.of(context)!.idNumber,
          keepTrailingArrow: false,
          trailing: ValueListenableBuilder<UserInfoM?>(
              valueListenable: userInfoNotifier,
              builder: (context, userInfoM, child) {
                return Text("${userInfoM?.uid ?? '-'}");
              })),
    ]);
  }
}
