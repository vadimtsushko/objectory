class Fields {
  static const id = const Field(id: 'id', type: int);
}

class TableSchema {
  final Map<String, Field> fields;
  final String tableName;
  final bool logChanges;
  const TableSchema({this.fields, this.tableName, this.logChanges});
}

class FieldValue<T> {
  final String fieldName;
  final value;
  FieldValue(this.fieldName, this.value);

  @override
  String toString() {
    return 'FieldValue{fieldName: $fieldName, value: $value}';
  }
}

class FieldValues<T> {
  final String fieldName;
  final List<T> values;
  FieldValues(this.fieldName, this.values);

  @override
  String toString() {
    return 'FieldValue{fieldName: $fieldName, value: $values}';
  }
}

class Field<T> {
  final String id;
  final String label;
  final String title;
  final Type type;
  final bool foreignKey;
  final bool logChanges;
  FieldValue<T> value(T value) => new FieldValue<T>(id, value);
  FieldValues<T> values(List<T> values) => new FieldValues<T>(id, values);
  const Field(
      {this.id: '',
      this.label: '',
      this.title: '',
      this.type: Object,
      this.logChanges: false,
      this.foreignKey: false});
}
