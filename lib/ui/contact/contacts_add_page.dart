import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/ui/contact/contact_detail_page.dart';
import 'package:vocechat_client/ui/contact/contacts_add_segmented_control.dart';

enum SearchStatus { searching, noResult, notSearching }

class ContactsAddPage extends StatefulWidget {
  const ContactsAddPage({Key? key}) : super(key: key);

  @override
  State<ContactsAddPage> createState() => _ContactsAddPageState();
}

class _ContactsAddPageState extends State<ContactsAddPage> {
  final ValueNotifier<ContactSearchType> type =
      ValueNotifier(ContactSearchType.id);
  final ValueNotifier<bool> _showClearBtn = ValueNotifier(false);

  final ValueNotifier<SearchStatus> _searchingStatus =
      ValueNotifier(SearchStatus.notSearching);

  final FocusNode _fieldFocus = FocusNode();

  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    controller.addListener(() {
      _showClearBtn.value = controller.text.isNotEmpty;
    });

    _fieldFocus.addListener(() {
      if (_fieldFocus.hasFocus) {
        _searchingStatus.value = SearchStatus.notSearching;
      }
    });
  }

  @override
  void dispose() {
    controller.removeListener(() {
      _showClearBtn.value = controller.text.isNotEmpty;
    });

    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: _buildBar(context),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  AppBar _buildBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.barBg,
      leading: CupertinoButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.close, color: AppColors.grey97)),
      title: Text(
        AppLocalizations.of(context)!.addContacts,
        style: AppTextStyles.titleLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ContactsAddSegmentedControl(typeNotifier: type),
          ValueListenableBuilder<ContactSearchType>(
              valueListenable: type,
              builder: (context, value, child) {
                return _buildSearchField(value);
              }),
          _buildSearchResult(),
        ],
      ),
    );
  }

  Widget _buildSearchField(ContactSearchType type) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      height: 36,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(4)),
      child: ValueListenableBuilder<bool>(
          valueListenable: _showClearBtn,
          builder: (context, showClearBtn, _) {
            return TextField(
              maxLines: 1,
              autofocus: true,
              focusNode: _fieldFocus,
              controller: controller,
              textInputAction: TextInputAction.search,
              keyboardType: TextInputType.emailAddress,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                  icon: const Icon(Icons.search, size: 24),
                  suffixIcon: showClearBtn
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            controller.clear();
                          },
                          child: Container(
                              padding: const EdgeInsets.all(4.0),
                              decoration: BoxDecoration(
                                  color: AppColors.grey97,
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.clear,
                                  size: 12, color: Colors.white)))
                      : null,
                  isDense: true,
                  hintText:
                      AppLocalizations.of(context)!.contactsPageSearchHint,
                  hintMaxLines: 1,
                  hintStyle: const TextStyle(
                      overflow: TextOverflow.ellipsis,
                      color: Color.fromRGBO(60, 60, 67, 0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.4),
                  contentPadding: const EdgeInsets.only(left: 0, right: 10),
                  border: InputBorder.none),
              onSubmitted: (value) {
                _search(value);
              },
            );
          }),
    );
  }

  Widget _buildSearchResult() {
    Widget resultWidget;

    return ValueListenableBuilder<SearchStatus>(
      valueListenable: _searchingStatus,
      builder: (context, status, child) {
        switch (status) {
          case SearchStatus.noResult:
            resultWidget = Center(
                child: Text(AppLocalizations.of(context)!.userSearchNoResult,
                    style: AppTextStyles.labelLarge));
            break;
          case SearchStatus.searching:
            resultWidget = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CupertinoActivityIndicator(radius: 8),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.searching,
                    style: AppTextStyles.labelLarge)
              ],
            );
            break;
          case SearchStatus.notSearching:
            resultWidget = const SizedBox.shrink();
            break;

          default:
            resultWidget = const SizedBox.shrink();
        }
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: resultWidget);
      },
    );
  }

  Future<void> _search(String keyword) async {
    _searchingStatus.value = SearchStatus.searching;

    await UserApi().search(type.value, keyword).then((response) {
      if (response.statusCode == 200 && response.data != null) {
        UserInfoDao().getUserByUid(response.data!.uid).then((localUserInfoM) {
          UserInfoM resultUserInfoM =
              localUserInfoM ?? UserInfoM.fromUserInfo(response.data!, "");

          _searchingStatus.value = SearchStatus.notSearching;

          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) {
              return ContactDetailPage(userInfoM: resultUserInfoM);
            },
          ));
        });
      } else {
        _searchingStatus.value = SearchStatus.noResult;
      }
    });
  }
}
