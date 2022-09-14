import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vocechat_client/app.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/utils/utils.dart';

const _orgDbName = 'org_chat.db';
var databaseFactory = databaseFactoryFfi;
late Database db;
late Database orgDb;
final _logger = SimpleLogger();

/// Initialize App DB
///
/// This method is called only once when main executes. It creates db if
/// it does not exist. No nothing if db has been created.
Future<void> initDb({String? dbFileName}) async {
  try {
    String databasesPath = await getDatabasesPath();
    {
      // org db
      String path = p.join(databasesPath, dbFileName ?? _orgDbName);
      await Directory(databasesPath)
          .create(recursive: true); // App will terminate if create fails.
      orgDb = await databaseFactory.openDatabase(path,
          options: OpenDatabaseOptions(version: 1));

      // Check if db table has been created.
      int? count = firstIntValue(await orgDb.query('sqlite_master',
          columns: ['COUNT(*)'], where: 'type = ?', whereArgs: ['table']));
      if (count == null || count < 3) {
        // Multiple sql strings are not supported in Android, thus change to single
        // sql string and execute one after another.
        List<String> sqlList = (await _initSql('assets/org_db.sql')).split(';');
        Batch batch = orgDb.batch();
        for (String sql in sqlList) {
          sql = sql.trim();
          if (sql.isNotEmpty) {
            batch.execute(sql);
          }
        }
        batch.commit();
      }
    }
  } catch (e) {
    _logger.severe(e);
  }
}

/// Initialize user related DB.
///
/// This method executes only once after login succeeds.
/// Create DB if it does not exists. Do nothing otherwise.
Future<void> initCurrentDb(String dbName) async {
  try {
    String databasesPath = await getDatabasesPath();
    String path = p.join(databasesPath, dbName);

    await Directory(databasesPath)
        .create(recursive: true); // App will terminate if create fails.
    db = await databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(version: 1));
    {
      // Multiple sql strings are not supported in Android, thus change to single
      // sql string and execute one after another.
      int? count = firstIntValue(await db.query('sqlite_master',
          columns: ['COUNT(*)'], where: 'type = ?', whereArgs: ['table']));
      if (count == null || count < 7) {
        _logger.info("Database [$dbName] not created");
        List<String> sqlList =
            (await _initSql('assets/init_db.sql')).split(';');
        Batch batch = db.batch();
        for (String sql in sqlList) {
          sql = sql.trim();
          if (sql.isNotEmpty) {
            batch.execute(sql);
          }
        }
        batch.commit();
      }
    }
  } catch (e) {
    _logger.severe(e);
  }
  // App.app.db = db;
  _logger.info("opened / reused [$dbName] database");
}

Future<void> closeAllDb() async {
  await db.close();
  await orgDb.close();
}

Future<void> closeUserDb() async {
  await db.close();
}

Future<void> removeDb() async {
  String databasesPath = await getDatabasesPath();
  Directory dir = Directory(databasesPath);
  for (var d in await dir.list().toList()) {
    try {
      d.deleteSync(recursive: true);
    } catch (e) {
      _logger.warning(e);
    }
  }
}

Future<String> _initSql(String sqlFile) async {
  String sql = await rootBundle.loadString(sqlFile);
  return sql;
}
