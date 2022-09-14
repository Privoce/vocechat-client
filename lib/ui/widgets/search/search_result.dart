import 'package:vocechat_client/dao/init_dao/user_info.dart';

class SearchResult {
  bool get empty => users == null || users!.isEmpty;

  List<UserInfoM>? users;

  SearchResult(this.users);
}
