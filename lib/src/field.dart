class Fields {
  static const id = const Field(id: 'id', type: int);
  static const deleted = const Field(id: 'deleted', type: bool);
  static const modifiedDate = const Field(id: 'modifiedDate', type: DateTime);
  static const modifiedTime = const Field(id: 'modifiedTime', type: DateTime);
}

class TableSchema {
  final Map<String, Field> fields;
  final String tableName;
  final bool logChanges;
  final bool isView;
  final TableSchema superSchema;
  final bool cacheValues;
  final String createScript;
  const TableSchema(
      {this.fields,
      this.tableName,
      this.logChanges,
      this.isView,
      this.createScript,
      this.cacheValues,
      this.superSchema});
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
  final bool externalKey;
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
      this.externalKey: false,
      this.foreignKey: false});
}

class $PersistentObject {
  static Field<int> get id => const Field<int>(
      id: 'id',
      label: '',
      title: '',
      type: int,
      logChanges: true,
      foreignKey: false,
      externalKey: false);
  static Field<bool> get deleted => const Field<bool>(
      id: 'deleted',
      label: '',
      title: '',
      type: bool,
      logChanges: true,
      foreignKey: false,
      externalKey: false);
  static Field<DateTime> get modifiedDate => const Field<DateTime>(
      id: 'modifiedDate',
      label: '',
      title: '',
      type: DateTime,
      logChanges: true,
      foreignKey: false,
      externalKey: false);
  static Field<DateTime> get modifiedTime => const Field<DateTime>(
      id: 'modifiedTime',
      label: '',
      title: '',
      type: DateTime,
      logChanges: true,
      foreignKey: false,
      externalKey: false);
  static TableSchema schema = new TableSchema(
      tableName: null,
      logChanges: false,
      isView: true,
      superSchema: null,
      fields: {
        'id': id,
        'deleted': deleted,
        'modifiedDate': modifiedDate,
        'modifiedTime': modifiedTime,
      });
}
