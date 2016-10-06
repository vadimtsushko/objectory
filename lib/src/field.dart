class Fields {
  static const id = const Field(id: 'id', type: int);
}

class TableSchema {
  final Map<String,Field> fields;
  final String tableName;
  final bool logChanges;
  const TableSchema({this.fields, this.tableName, this.logChanges});
}

class Field {
  final String id;
  final String label;
  final String title;
  final Type type;
  final bool foreignKey;
  final bool logChanges;
  const Field({this.id: '', this.label: '', this.title: '', this.type: Object, this.logChanges: false, this.foreignKey: false});
}
