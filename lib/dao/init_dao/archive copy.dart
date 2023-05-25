// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:vocechat_client/api/models/msg/msg_archive/archive.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/dao.dart';

enum ContactStatus { added, blocked }

class ContactM with M {
  int uid = -1;
  String status = ContactStatus.blocked.toString();
  int createdAt = 0;
  int updatedAt = 0;

  ContactM();

  ContactM.item(
      String id, this.uid, this.status, int createdAt, this.updatedAt) {
    super.id = id;
    super.createdAt = createdAt;
  }

  static ContactM fromMap(Map<String, dynamic> map) {
    ContactM m = ContactM();
    if (map.containsKey(F_id)) {
      m.id = map[F_id];
    }
    if (map.containsKey(F_uid)) {
      m.uid = map[F_uid];
    }
    if (map.containsKey(F_status)) {
      m.status = map[F_status];
    }
    if (map.containsKey(F_createdAt)) {
      m.createdAt = map[F_createdAt];
    }
    if (map.containsKey(F_updatedAt)) {
      m.updatedAt = map[F_updatedAt];
    }
    return m;
  }

  static const F_tableName = "contacts";
  static const F_id = "id";
  static const F_uid = "uid";
  static const F_status = "status";
  static const F_createdAt = "created_at";
  static const F_updatedAt = "updated_at";

  @override
  Map<String, Object> get values => {
        ContactM.F_id: id,
        ContactM.F_uid: uid,
        ContactM.F_status: status,
        ContactM.F_createdAt: createdAt,
        ContactM.F_updatedAt: updatedAt
      };

  static MMeta meta = MMeta.fromType(ContactM, ContactM.fromMap)
    ..tableName = F_tableName;
}

class ContactDao extends Dao<ContactM> {
  ContactDao() {
    ContactM.meta;
  }

  Future<ContactM> addOrUpdate(ContactM m) async {
    ContactM? old =
        await first(where: '${ContactM.F_uid} = ?', whereArgs: [m.uid]);
    if (old != null) {
      m.id = old.id;
      m.createdAt = old.createdAt;
      await super.update(m);
    } else {
      await super.add(m);
    }
    App.logger.info("Contact saved. Id: ${m.id}");
    return m;
  }

  Future<ContactM?> getContact(int uid) async {
    return super.first(where: "${ContactM.F_uid} = ?", whereArgs: [uid]);
  }
}
