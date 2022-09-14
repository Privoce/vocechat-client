import 'package:vocechat_client/models/local_kits.dart';
import 'package:vocechat_client/services/db.dart' as _db;
import 'package:simple_logger/simple_logger.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite/utils/utils.dart';
// ignore: implementation_imports
import 'package:sqflite_common/src/exception.dart';

typedef MFactory = Object Function(Map<String, dynamic> map);

String orderLast(String orderBy) {
  String r = orderBy.replaceAllMapped(RegExp('\\s(ASC|asc|DESC|desc)\\b'), (m) {
    String? m1 = m[1];
    if (m1 != null) {
      String m = m1;
      if (m == 'asc' || m == 'ASC') {
        return ' DESC';
      } else if (m == 'DESC' || m == 'desc') {
        return ' ASC';
      }
    }
    return '';
  });
  return r;
}

class MMeta {
  String tableName = '';
  final Type type;
  final MFactory creater;

  MMeta._p(this.type, this.creater);

  factory MMeta.fromType(Type t, MFactory c) {
    {
      MMeta? meta = mMetas[t];
      if (meta != null) {
        return meta;
      }
    }
    MMeta meta = MMeta._p(t, c);
    mMetas[t] = meta;
    return meta;
  }
}

final mMetas = <Type, MMeta>{};

mixin M {
  String id = '';
  int createdAt = 0;

  // ignore: non_constant_identifier_names
  static String get ID => 'id';

  // without ID
  Map<String, Object> get values;

// static const T empty<T extends M>(){
//   new T();
// }
}

abstract class Dao<T extends M> {
  Database get db => _db.db;
  final _logger = SimpleLogger();

  void beforeAdd(T m) {
    if (m.createdAt < 1) {
      m.createdAt = DateTime.now().millisecondsSinceEpoch;
    }
    if (m.id.isEmpty) {
      m.id = uuid();
    }
  }

  Future<T> add(T m) async {
    MMeta meta = mMetas[T]!;
    beforeAdd(m);
    Map<String, Object> values = {M.ID: m.id, ...m.values};

    await db.insert(meta.tableName, values);
    return m;
  }

  // Old entry will be deleted if conflict occurs.
  Future<T> addOrReplace(T m) async {
    MMeta meta = mMetas[T]!;
    if (m.createdAt < 1) {
      m.createdAt = DateTime.now().millisecondsSinceEpoch;
    }
    if (m.id.isEmpty) {
      m.id = uuid();
    }
    Map<String, Object> values = {M.ID: m.id, ...m.values};
    await db.insert(meta.tableName, values,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return m;
  }

  Future<int> remove(String id) async {
    MMeta meta = mMetas[T]!;
    int count =
        await db.delete(meta.tableName, where: '${M.ID} = ?', whereArgs: [id]);
    return count;
  }

  Future<int> removeAll() async {
    MMeta meta = mMetas[T]!;
    int count = await db.delete(meta.tableName);
    return count;
  }

  Future<int> update(T m) async {
    MMeta meta = mMetas[T]!;
    int count = await db.update(meta.tableName, m.values,
        where: '${M.ID} = ?', whereArgs: [m.id]);
    return count;
  }

  Future<T?> get(String id) async {
    var m = await first(where: '${M.ID} = ?', whereArgs: [id]);
    return m;
  }

  Future<List<T>> list({String? orderBy}) async {
    MMeta meta = mMetas[T]!;
    Iterable<T> ms = (await db.query(meta.tableName, orderBy: orderBy))
        .map((it) => meta.creater(it) as T);
    return ms.toList();
  }

  Future<List<T>> query(
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) async {
    MMeta meta = mMetas[T]!;
    Iterable<T> ms = (await db.query(meta.tableName,
            distinct: distinct,
            where: where,
            whereArgs: whereArgs,
            groupBy: groupBy,
            having: having,
            orderBy: orderBy,
            limit: limit,
            offset: offset))
        .map((it) => meta.creater(it) as T);
    return ms.toList();
  }

  Future<T?> first(
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) async {
    MMeta meta = mMetas[T]!;
    List<Map<String, Object?>> ms = (await db.query(
      meta.tableName,
      distinct: distinct,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit ?? 1,
      offset: offset ?? 0,
    ));
    if (ms.isNotEmpty) {
      Map<String, dynamic> firstRow = ms.first;
      if (firstRow.isNotEmpty) {
        return meta.creater(firstRow) as T;
      }
    }
    return null;
  }

  Future<PageData<T>> paginate(PageMeta pageMeta,
      {String? where, List<Object?>? whereArgs, String? orderBy}) async {
    MMeta meta = mMetas[T]!;
    PageData<T> page = PageData();
    if (pageMeta.pageSize < 1) {
      pageMeta.pageSize = 16;
    }
    if (pageMeta.pageNumber < 1) {
      pageMeta.pageNumber = 1;
    }
    Iterable<T> ms = (await db.query(meta.tableName,
            where: where,
            whereArgs: whereArgs,
            orderBy: orderBy,
            limit: pageMeta.limit,
            offset: pageMeta.offset))
        .map((it) => meta.creater(it) as T);
    page.records.addAll(ms);

    // If number of records is not enough to fill one page, an additional
    // request is needed to fetch the entry count.
    {
      int? count = firstIntValue(await db.query(meta.tableName,
          columns: ['COUNT(*)'], where: where, whereArgs: whereArgs));
      if (count == null) {
        _logger.severe('COUNT(*) = null in paginate, table: ${meta.tableName}');

        throw SqfliteDatabaseException(
            'COUNT(*) = null in paginate, table: ${meta.tableName}', null);
      } else {
        pageMeta.recordCount = count;
      }
    }
    page.meta = pageMeta;
    return page;
  }

  /// Paginate backwards: [pageNumber] = 1 means the first page from the back.
  /// [orderBy] can't be null.
  ///
  /// This function will return the last full page of entries.
  Future<PageData<T>> paginateLast(PageMeta pageMeta, String orderBy,
      {String? where, List<Object?>? whereArgs}) async {
    if (orderBy.isEmpty) {
      _logger.warning("orderBy is empty in paginateReversed()");
    }
    String last = orderLast(orderBy);
    PageData<T> page = await paginate(pageMeta,
        where: where, whereArgs: whereArgs, orderBy: last);
    page.records = page.records.reversed.toList();
    return page;
  }

  Future<bool> batchAdd(Iterable<T> ms, {int maxBatch = 200}) async {
    MMeta meta = mMetas[T]!;
    Batch batch = db.batch();
    try {
      // Max 200 entries at a time to avoid handling too much data.
      int batchCount = 0;
      for (T m in ms) {
        beforeAdd(m);
        batch.insert(meta.tableName, {M.ID: m.id, ...m.values});
        batchCount++;
        if (batchCount >= maxBatch) {
          await batch.commit();
          batch =
              db.batch(); // Use a new batch after submitting an existing one.
          batchCount = 0;
        }
      }
      if (batchCount > 0) {
        await batch.commit();
      }
      return true;
    } catch (e) {
      _logger.severe(e);
      return false;
    }
  }

  Future<bool> batchRemove(List<String> ms, {int maxBatch = 200}) async {
    MMeta meta = mMetas[T]!;
    Batch batch = db.batch();
    const oneMaxRemoved = 50;
    int startIndex = 0;
    try {
      // Max 200 entries at a time to avoid handling too much data.
      int batchCount = 0;

      int count = (ms.length / oneMaxRemoved).ceil();
      for (int i = 0; i < count; i++) {
        startIndex = i * oneMaxRemoved;
        int removes = oneMaxRemoved < ms.length - startIndex
            ? oneMaxRemoved
            : ms.length - startIndex;
        var one =
            ms.getRange(startIndex, startIndex + removes).map((e) => "'$e'");
        String w = "${M.ID} in (${one.join(",")})";

        batch.delete(meta.tableName, where: w);
        batchCount++;
        if (batchCount >= maxBatch) {
          await batch.commit();
          batch =
              db.batch(); // Use a new batch after submitting an existing one.
          batchCount = 0;
        }
      }
      if (batchCount > 0) {
        await batch.commit();
      }
      return true;
    } catch (e) {
      _logger.severe(e);
      return false;
    }
  }

  //ms中的数据，已经与数据库中的合并，这里只是作batch操作
  Future<bool> batchUpdate(Iterable<T> ms, {int maxBatch = 200}) async {
    MMeta meta = mMetas[T]!;
    Batch batch = db.batch();
    try {
      // Max 200 entries at a time to avoid handling too much data.
      int batchCount = 0;
      for (T m in ms) {
        batch.update(meta.tableName, m.values,
            where: '${M.ID} = ?', whereArgs: [m.id]);
        batchCount++;
        if (batchCount >= maxBatch) {
          await batch.commit();
          batch =
              db.batch(); // Use a new batch after submitting an existing one.
          batchCount = 0;
        }
      }
      if (batchCount > 0) {
        await batch.commit();
      }
      return true;
    } catch (e) {
      _logger.severe(e);
      return false;
    }
  }
}

abstract class OrgDao<T extends M> extends Dao<T> {
  @override
  Database get db => _db.orgDb;
}
