// ignore_for_file: constant_identifier_names

import 'package:vocechat_client/api/models/user/contact_info.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/dao.dart';

enum ContactStatus { added, blocked, none }

enum ContactUpdateAction { add, block, remove, unblock }

class ContactM with M {
  int uid = -1;
  String status = ContactStatus.none.name;
  int updatedAt = 0;

  ContactM();

  ContactM.item(
      String id, this.uid, this.status, int createdAt, this.updatedAt) {
    super.id = id;
    super.createdAt = createdAt;
  }

  ContactM.fromContactInfo(
      this.uid, this.status, int createdAt, this.updatedAt) {
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

  Future<ContactM?> updateContact(int uid, ContactStatus status) async {
    ContactM? contactM = await getContact(uid);
    if (contactM != null) {
      switch (status) {
        case ContactStatus.added:
          contactM.status = ContactStatus.added.name;
          break;
        case ContactStatus.blocked:
          contactM.status = ContactStatus.blocked.name;
          break;
        case ContactStatus.none:
          contactM.status = ContactStatus.none.name;
          break;
      }
      contactM.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await update(contactM);

      return contactM;
    } else {
      contactM = ContactM();
      contactM.uid = uid;
      contactM.status = status.name;
      contactM.updatedAt = DateTime.now().millisecondsSinceEpoch;

      await add(contactM);

      return contactM;
    }
  }

  Future<ContactM?> updateContactInfo(int uid, ContactInfo contactInfo) async {
    ContactM? contactM = await getContact(uid);
    if (contactM != null) {
      contactM.status = contactInfo.status;
      contactM.createdAt = contactInfo.createdAt;
      contactM.updatedAt = contactInfo.updatedAt;

      await update(contactM);
    } else {
      contactM = ContactM.fromContactInfo(uid, contactInfo.status,
          contactInfo.createdAt, contactInfo.updatedAt);
      await add(contactM);
    }
    return contactM;
  }

  Future<ContactInfo?> getContactInfo(int uid) async {
    final contactM = await getContact(uid);
    if (contactM != null) {
      return ContactInfo(
          createdAt: contactM.createdAt,
          status: contactM.status,
          updatedAt: contactM.updatedAt);
    } else {
      return null;
    }
  }

  Future<bool> removeContact(int uid) async {
    try {
      await db.rawDelete(
          "DELETE FROM ${ContactM.F_tableName} WHERE ${ContactM.F_uid} = ?",
          [uid]);
      return true;
    } catch (e) {
      App.logger.severe("Error removing contact. $e");
    }
    return false;
  }
}
