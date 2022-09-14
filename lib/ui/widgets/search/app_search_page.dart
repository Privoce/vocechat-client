import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import 'package:vocechat_client/ui/contact/contact_detail_page.dart';
import 'package:vocechat_client/ui/contact/contact_tile.dart';
import 'package:vocechat_client/ui/widgets/avatar/avatar_size.dart';
import 'package:vocechat_client/ui/widgets/search/app_search_field.dart';
import 'package:vocechat_client/ui/widgets/search/search_result.dart';

class AppSearchPage extends StatelessWidget {
  final String? hintText;

  final TextEditingController _controller = TextEditingController();

  final ValueNotifier<String> _keywordNotifier = ValueNotifier("");

  AppSearchPage({this.hintText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.barBg,
        // leading: SizedBox.shrink(),
        automaticallyImplyLeading: false,
        leadingWidth: 0,
        titleSpacing: 0,
        title: AppSearchField(
          hintText: hintText,
          controller: _controller,
          onChanged: (text) {
            _keywordNotifier.value = text.trim().toLowerCase();
          },
        ),
        actions: [
          CupertinoButton(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
              })
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ValueListenableBuilder<String>(
          valueListenable: _keywordNotifier,
          builder: (context, keyword, child) {
            if (keyword.isEmpty) return _buildEmptyKeyword(context);
            return FutureBuilder<SearchResult>(
              future: _search(keyword),
              builder: (context, snapshot) {
                List<Widget> resultList = [];
                if (snapshot.hasData && snapshot.data != null) {
                  final result = snapshot.data!;

                  if (result.users != null) {
                    final users = result.users!;
                    final userCol = Column(
                      children: List<Widget>.generate(users.length, (index) {
                        final userInfoM = users[index];
                        return ContactTile(
                          userInfoM,
                          App.app.isSelf(userInfoM.uid),
                          enableSubtitleEmail: true,
                          avatarSize: AvatarSize.s42,
                          onTap: () => Navigator.pushNamed(
                              context, ContactDetailPage.route,
                              arguments: userInfoM),
                        );
                      }),
                    );
                    resultList.add(userCol);
                  }

                  if (resultList.isEmpty) {
                    return _buildEmptyResult(context);
                  }

                  return ListView(children: resultList);
                } else {
                  return CupertinoActivityIndicator();
                }
              },
            );
          },
        ),
      ),
    );
  }

  Future<SearchResult> _search(String keyword) async {
    final users = await UserInfoDao().getUsersMatched(keyword);

    return SearchResult(users);
  }

  Widget _buildEmptyKeyword(BuildContext context) {
    return _buildTextBlock(
        AppLocalizations.of(context)!.contactsPageSearchHint);
  }

  Widget _buildEmptyResult(BuildContext context) {
    return _buildTextBlock("No Matching Results");
  }

  Widget _buildTextBlock(String text) {
    return Container(
      width: double.maxFinite,
      height: 96,
      padding: EdgeInsets.only(left: 16, right: 16, top: 48),
      child: Text(
        text,
        style: AppTextStyles.labelLarge(),
        textAlign: TextAlign.center,
      ),
    );
  }
}
