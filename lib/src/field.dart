class TableSchema {
  final Map<String, Field> fields;
  final String tableName;
  final Type tableType;
  final bool logChanges;
  final bool isView;
  final TableSchema superSchema;
  final bool cacheValues;
  final String createScript;
  const TableSchema(
      {this.fields,
      this.tableName,
      this.tableType,
      this.logChanges,
      this.isView,
      this.createScript,
      this.cacheValues,
      this.superSchema});
  Field findField(String fieldName) {
    Field result = fields[fieldName];
    if (result != null) {
      return result;
    }
    if (superSchema == null) {
      return null;
    }
    return (superSchema.findField(fieldName));
  }
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
  final int width;
  final bool tootltipsOnContent;
  final bool logChanges;
  final Type parentTable;
  final String parentField;
  final String staticValue;
  final defaultValue;
  FieldValue<T> value(T value) => new FieldValue<T>(id, value);
  FieldValues<T> values(List<T> values) => new FieldValues<T>(id, values);
  const Field({
    this.id: '',
    this.label: '',
    this.title: '',
    this.staticValue: '',
    this.type: Object,
    this.defaultValue: null,
    this.logChanges: false,
    this.tootltipsOnContent: false,
    this.width: 0,
    this.externalKey: false,
    this.foreignKey: false,
    this.parentTable: null,
    this.parentField: '',
  });
}

class $PersistentObject {
  static Field<int> get id => const Field<int>(
      id: 'id',
      label: 'Ид.',
      title: 'Внутренний идентификатор строки',
      type: int,
      logChanges: true,
      foreignKey: false,
      externalKey: false);
  static Field<bool> get deleted => const Field<bool>(
      id: 'deleted',
      label: 'Уд.',
      title: 'Пометка на удаление',
      type: bool,
      logChanges: true,
      foreignKey: false,
      externalKey: false);
  static Field<DateTime> get modifiedDate => const Field<DateTime>(
      id: 'modifiedDate',
      label: 'Дата изм.',
      title: 'Дата изменения строки',
      type: DateTime,
      logChanges: true,
      foreignKey: false,
      externalKey: false);
  static Field<DateTime> get modifiedTime => const Field<DateTime>(
      id: 'modifiedTime',
      label: 'Время изм.',
      title: 'Время изменения строки',
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
