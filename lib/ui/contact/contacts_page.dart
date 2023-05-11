import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/event_bus_objects/user_change_event.dart';
import 'package:vocechat_client/globals.dart';
import 'package:vocechat_client/ui/contact/contact_detail_page.dart';
import 'package:vocechat_client/ui/contact/contact_list.dart';
import 'package:vocechat_client/ui/contact/contacts_bar.dart';

class ContactsPage extends StatefulWidget {
  static const route = "/contacts";

  const ContactsPage({Key? key}) : super(key: key);

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage>
    with AutomaticKeepAliveClientMixin {
  bool keepAlive = true;

  @override
  bool get wantKeepAlive => keepAlive;

  @override
  void initState() {
    super.initState();

    eventBus.on<UserChangeEvent>().listen((event) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: const ContactsBar(),
        body: SafeArea(
          child: FutureBuilder<List<UserInfoM>?>(
            // future: enableContact ? getContactList() : getUserList(),
            future: getUserList(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return ContactList(
                    key: Key(App.app.userDb!.dbName),
                    userList: snapshot.data!,
                    onTap: (userInfoM) => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ContactDetailPage(userInfoM: userInfoM),
                          ),
                        ));
              }
              return const Center(child: CupertinoActivityIndicator());
            },
          ),
        ));
  }

  Future<List<UserInfoM>?> getUserList() async {
    final userList = await UserInfoDao().getUserList();
    return userList;
  }

  // Future<List<UserInfoM>?> getContactList() async {
  //   final contactList = await UserInfoDao().getContactList();
  //   return contactList;
  // }
}
