import 'package:uuid/uuid.dart';

const defaultPageSize = 20;

String uuid() {
  return Uuid().v4();
}

class PageMeta {
  /// The number of records in one page.
  ///
  /// Default value is [defaultPageSize], or 16 if set to -1.
  int pageSize = -1;

  /// The current page number, start from 1.
  int pageNumber = -1;

  /// The total number of records.
  int recordCount = -1;

  /// The total number of pages.
  int get pages =>
      (pageSize < 0 || recordCount < 1) ? -1 : (recordCount / pageSize).ceil();

  /// starting index
  int get offset => (pageNumber - 1) * pageSize;

  /// page size
  int get limit => pageSize;

  /// If has next page.
  ///
  /// If reaches the last page, return false.
  bool get hasNextPage {
    return pageNumber < pages;
  }
}

/// A generic class containing page meta and records.
class PageData<T> {
  PageMeta meta = PageMeta();
  List<T> records = [];
}
