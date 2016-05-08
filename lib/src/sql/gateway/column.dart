part of gateway;

enum ColumnType {
  character,
  varchar,
  binary,
  boolean,
  varbinary,
  integer,
  smallint,
  bigint,
  decimal,
  numeric,
  float,
  real,
  double,
  date,
  time,
  timestamp,
  interval,
  array,
  multiset,
  xml,
}

class Column {
  final String name;
  final ColumnType type;
  final int length;
  bool isNullable = true;
  ForeignKey foreignKey;
  bool isPrimaryKey = false;
  bool shouldBeUnique = false;
  bool shouldIncrement = false;

  Column(String this.name, ColumnType this.type, int this.length);

  Column nullable(bool canBeNull) {
    isNullable = canBeNull;
    return this;
  }

  ForeignKey references(String foreignTable, {String column: 'id'}) {
    return foreignKey = new ForeignKey(foreignTable, column);
  }

  Column primaryKey() {
    isPrimaryKey = true;
    return this;
  }

  Column increments() {
    shouldIncrement = true;
    return this;
  }

  Column incrementingPrimaryKey() {
    return nullable(false).primaryKey().increments();
  }

  Column unique() {
    shouldBeUnique = true;
    return this;
  }
}
