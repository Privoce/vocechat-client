import 'package:azlistview/azlistview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/services/voce_chat_service.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/ui/contact/contact_list.dart';

class NewDmPage extends StatefulWidget {
  const NewDmPage({Key? key}) : super(key: key);

  @override
  State<NewDmPage> createState() => _NewDmPageState();
}

class _NewDmPageState extends State<NewDmPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: barHeight,
        elevation: 0,
        backgroundColor: AppColors.coolGrey200,
        title: Text(AppLocalizations.of(context)!.newDmPageTitle,
            style: AppTextStyles.titleLarge,
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context, null);
            },
            child: Icon(Icons.close, color: AppColors.grey97)),
      ),
      body: FutureBuilder<List<UserInfoM>?>(
          future: UserInfoDao().getUserList(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CupertinoActivityIndicator());
            }

            final userList = snapshot.data ?? [];

            return ContactList(
                userList: userList,
                onTap: (user) {
                  Navigator.of(context).pop(user);
                });
          }),
    );
  }
}
