// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:vocechat_client/api/models/admin/system/sys_common_info.dart';
import 'package:vocechat_client/dao/dao.dart';

class SystemCommonInfoM with M {
  String _value = "";

  SystemCommonInfoM();

  SystemCommonInfoM.fromCommonInfo(AdminSystemCommonInfo info) {
    _value = jsonEncode(info.toJson());
  }

  AdminSystemCommonInfo get value {
    final json = jsonDecode(_value);
    return AdminSystemCommonInfo.fromJson(json);
  }

  static SystemCommonInfoM fromMap(Map<String, dynamic> map) {
    SystemCommonInfoM m = SystemCommonInfoM();
    if (map.containsKey(M.ID)) {
      m.id = map[M.ID];
    }
    if (map.containsKey(F_value)) {
      m._value = map[F_value];
    }
    if (map.containsKey(F_createdAt)) {
      m.createdAt = map[F_createdAt];
    }

    return m;
  }

  static const F_tableName = 'system_common_info';
  static const F_value = 'value';
  static const F_createdAt = 'created_at';

  @override
  Map<String, Object> get values => {
        SystemCommonInfoM.F_value: _value,
        SystemCommonInfoM.F_createdAt: createdAt,
      };

  static MMeta meta =
      MMeta.fromType(SystemCommonInfoM, SystemCommonInfoM.fromMap)
        ..tableName = F_tableName;
}

class DmInfoDao extends Dao<SystemCommonInfoM> {
  DmInfoDao() {
    SystemCommonInfoM.meta;
  }

  Future<AdminSystemCommonInfo?> getSysCommonInfo() async {
    final info = await first();
    if (info == null) {
      return AdminSystemCommonInfo();
    }
    return info.value;
  }
}
