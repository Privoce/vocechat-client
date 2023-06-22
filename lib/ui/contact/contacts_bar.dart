import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/globals.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/ui/contact/contacts_add_page.dart';
import 'package:vocechat_client/ui/fade_page_route.dart';
import 'package:vocechat_client/ui/widgets/search/app_search_page.dart';
import 'package:vocechat_client/ui/widgets/search/search_field_button.dart';

class ContactsBar extends StatefulWidget implements PreferredSizeWidget {
  const ContactsBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size(double.maxFinite, 84.0);

  @override
  State<ContactsBar> createState() => _ContactsBarState();
}

class _ContactsBarState extends State<ContactsBar> {
  ValueNotifier<bool> enableContact = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    enableContact.value =
        App.app.chatServerM.properties.commonInfo?.contactVerificationEnable ==
            true;

    App.app.chatService.subscribeChatServer(_onChatServerChange);
  }

  @override
  void dispose() {
    App.app.chatService.unsubscribeChatServer(_onChatServerChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.barBg,
      title: Text(
        AppLocalizations.of(context)!.titleContacts,
        style: AppTextStyles.titleLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      actions: [
        ValueListenableBuilder<bool>(
            valueListenable: enableContact,
            builder: (context, enableContact, _) {
              if (enableContact) {
                return _buildAddContactsBtn(context);
              } else {
                return SizedBox.shrink();
              }
            })
      ],
      bottom: SearchFieldButton(
        hintText: AppLocalizations.of(context)!.contactsPageSearchHint,
        onTap: () {
          Navigator.of(context).push(FadePageRoute(
              duration: const Duration(milliseconds: 100),
              reverseDuration: const Duration(milliseconds: 100),
              child: AppSearchPage(
                hintText: AppLocalizations.of(context)!.contactsPageSearchHint,
              )));
        },
      ),
    );
  }

  Widget _buildAddContactsBtn(BuildContext context) {
    return CupertinoButton(
        padding: const EdgeInsets.only(right: 8),
        child: Icon(AppIcons.add, color: AppColors.grey97),
        onPressed: () => _pushAddContactsPage(context));
  }

  void _pushAddContactsPage(BuildContext context) async {
    final route = PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ContactsAddPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.fastOutSlowIn;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );

    Navigator.of(context).push(route);
  }

  Future<void> _onChatServerChange(ChatServerM chatServerM) async {
    enableContact.value =
        chatServerM.properties.commonInfo?.contactVerificationEnable == true;
  }
}
