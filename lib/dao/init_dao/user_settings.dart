// // ignore_for_file: constant_identifier_names

// import 'package:vocechat_client/app.dart';
// import 'package:vocechat_client/dao/dao.dart';

// class UserSettingsM with M {
//   String pinnedChats = "";
//   String mutedChats = "";

//   UserSettingsM();

//   UserSettingsM.item(this.pinnedChats, this.mutedChats);

//   static UserSettingsM fromMap(Map<String, dynamic> map) {
//     UserSettingsM m = UserSettingsM();
//     if (map.containsKey(M.ID)) {
//       m.id = map[M.ID];
//     }
//     if (map.containsKey(F_pinnedChats)) {
//       m.pinnedChats = map[F_pinnedChats];
//     }
//     if (map.containsKey(F_mutedChats)) {
//       m.mutedChats = map[F_mutedChats];
//     }
//     if (map.containsKey(F_createdAt)) {
//       m.createdAt = map[F_createdAt];
//     }

//     return m;
//   }

//   static const F_tableName = 'user_settings';
//   static const F_pinnedChats = 'pinned_chats';
//   static const F_mutedChats = 'muted_chats';
//   static const F_createdAt = 'created_at';

//   @override
//   Map<String, Object> get values => {
//         UserSettingsM.F_pinnedChats: pinnedChats,
//         UserSettingsM.F_mutedChats: mutedChats,
//         UserSettingsM.F_createdAt: createdAt
//       };

//   static MMeta meta = MMeta.fromType(UserSettingsM, UserSettingsM.fromMap)
//     ..tableName = F_tableName;
// }

// class UserSettingsDao extends Dao<UserSettingsM> {
//   UserSettingsDao() {
//     UserSettingsM.meta;
//   }

//   Future<UserSettingsM> addOrUpdate(UserSettingsM m) async {
//     UserSettingsM old;
//     final list = await super.list();
//     if (list.isNotEmpty) {
//       old = list.first;

//       m.id = old.id;
//       await super.update(m);
//       App.logger.info("DmInfo updated. ${m.values}");
//     } else {
//       await super.add(m);
//       App.logger.info("DmInfo added. ${m.values}");
//     }
//     return m;
//   }

//   Future<UserSettingsM> updatePinnedChats() async {}
// }
