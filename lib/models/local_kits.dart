import 'package:uuid/uuid.dart';

const defaultPageSize = 20;

String uuid() {
  return Uuid().v4();
}

String makeDbName(String userName) {
  return '${userName}_${Uuid().v4().replaceAll('-', '')}.db';
}

class PageMeta {
  //一页的记录数量
  int pageSize = -1;

  //页号，从1开始编号
  int pageNumber = -1;

  //总的记录数据
  int recordCount = -1;

  //分页数量
  int get pages =>
      (pageSize < 0 || recordCount < 1) ? -1 : (pageSize / recordCount).ceil();

  //starting index
  int get offset => (pageNumber - 1) * pageSize;

  //page size
  int get limit => pageSize;

  //如果已经达到最后一后，则返回false
  bool nextPage() {
    if (pageNumber < pages) {
      pageNumber++;
      return true;
    }
    return false;
  }
}

//由于名字Page在flutter中已有命名，所以增加Data以区别不同
class PageData<T> {
  PageMeta meta = PageMeta();
  List<T> records = [];
}
