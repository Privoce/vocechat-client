import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/contact/contact_detail_page.dart';
import 'package:vocechat_client/ui/contact/contact_list.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/ui/widgets/avatar/avatar_size.dart';

class ChannelMembersPage extends StatelessWidget {
  final GroupInfoM groupInfoM;

  ChannelMembersPage(this.groupInfoM);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: barHeight,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.members,
            style: AppTextStyles.titleLarge()),
        centerTitle: true,
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios_new, color: AppColors.grey97)),
      ),
      body: SafeArea(
        child: FutureBuilder<List<UserInfoM>?>(
          future: GroupInfoDao().getUserListByGid(groupInfoM.gid,
              groupInfoM.isPublic == 1, groupInfoM.groupInfo.members ?? []),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ContactList(
                  userList: snapshot.data!,
                  avatarSize: AvatarSize.s36,
                  ownerUid: groupInfoM.groupInfo.owner,
                  onTap: (user) {
                    Navigator.of(context)
                        .pushNamed(ContactDetailPage.route, arguments: user);
                  });
            }
            return SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
