import 'package:flutter/material.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/fade_page_route.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/widgets/search/app_search_field.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:vocechat_client/ui/widgets/search/app_search_page.dart';
import 'package:vocechat_client/ui/widgets/search/search_field_button.dart';

class ContactsBar extends StatelessWidget implements PreferredSizeWidget {
  const ContactsBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => Size(double.maxFinite, 84.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.barBg,
      title: Text(
        AppLocalizations.of(context)!.titleContacts,
        style: AppTextStyles.titleLarge(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      bottom: SearchFieldButton(
        hintText: AppLocalizations.of(context)!.contactsPageSearchHint,
        onTap: () {
          Navigator.of(context).push(FadePageRoute(
              duration: Duration(milliseconds: 100),
              reverseDuration: Duration(milliseconds: 100),
              child: AppSearchPage(
                hintText: AppLocalizations.of(context)!.contactsPageSearchHint,
              )));
        },
      ),
    );
  }
}
