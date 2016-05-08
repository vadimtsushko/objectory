part of gateway;

class Schema {
  final List<Column> columns = [];
  final List<String> columnsToDrop = [];

  Column _column(ColumnType type, String name, [core.int length]) {
    final column = new Column(name, type, length);
    columns.add(column);
    return column;
  }

  // Directly converted from the column types

  Column character(String name, [core.int length]) =>
      _column(ColumnType.character, name, length);

  Column varchar(String name, [core.int length]) =>
      _column(ColumnType.varchar, name, length);

  Column binary(String name, [core.int length]) =>
      _column(ColumnType.binary, name, length);

  Column boolean(String name, [core.int length]) =>
      _column(ColumnType.boolean, name, length);

  Column varbinary(String name, [core.int length]) =>
      _column(ColumnType.varbinary, name, length);

  Column integer(String name, [core.int length]) =>
      _column(ColumnType.integer, name, length);

  Column smallint(String name, [core.int length]) =>
      _column(ColumnType.smallint, name, length);

  Column bigint(String name, [core.int length]) =>
      _column(ColumnType.bigint, name, length);

  Column decimal(String name, [core.int length]) =>
      _column(ColumnType.decimal, name, length);

  Column numeric(String name, [core.int length]) =>
      _column(ColumnType.numeric, name, length);

  Column float(String name, [core.int length]) =>
      _column(ColumnType.float, name, length);

  Column real(String name, [core.int length]) =>
      _column(ColumnType.real, name, length);

  Column double(String name, [core.int length]) =>
      _column(ColumnType.double, name, length);

  Column date(String name, [core.int length]) =>
      _column(ColumnType.date, name, length);

  Column time(String name, [core.int length]) =>
      _column(ColumnType.time, name, length);

  Column timestamp(String name, [core.int length]) =>
      _column(ColumnType.timestamp, name, length);

  Column interval(String name, [core.int length]) =>
      _column(ColumnType.interval, name, length);

  Column array(String name, [core.int length]) =>
      _column(ColumnType.array, name, length);

  Column multiset(String name, [core.int length]) =>
      _column(ColumnType.multiset, name, length);

  Column xml(String name, [core.int length]) =>
      _column(ColumnType.xml, name, length);

  // Column aliases

  Column int(String name, [core.int length]) => integer(name, length);

  Column string(String name, [core.int length = 255]) => varchar(name, length);

  Column id() => integer('id').incrementingPrimaryKey();

  void timestamps() {
    timestamp('created_at').nullable(false);
    timestamp('updated_at').nullable(false);
  }

  // Other operation

  void drop(String name) {
    columnsToDrop.add(name);
  }

  void delete(String name) => drop(name);
}