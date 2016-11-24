class TableSchema {
  final Map<String, Field> fields;
  final String tableName;
  final Type tableType;
  final bool logChanges;
  final bool isView;
  final String queryString;
  final TableSchema superSchema;
  final bool cacheValues;
  final bool sessionIdsRole;
  final bool idField;
  final bool deletedField;
  final bool modifiedDateField;
  final bool modifiedTimeField;
  final bool modifiedByField;
  final String createScript;
  final int tableId;

  Set<String> _fieldsToLog;
  Set<String> get fieldsToLog {
    if (_fieldsToLog == null) {
      _fieldsToLog = fields.values
          .where((Field fld) => fld.logChanges)
          .map((Field fld) => fld.id)
          .toSet();
    }
    return _fieldsToLog;
  }

  Set<String> _allFields;
  Set<String> get allFields {
    if (_allFields == null) {
      _allFields = fields.values.map((Field fld) => fld.id).toSet();
      TableSchema parent = superSchema;
      while (parent != null) {
        _allFields.addAll(fields.values.map((Field fld) => fld.id));
        parent = parent.superSchema;
      }
    }
    return _allFields;
  }

  TableSchema(
      {this.fields,
      this.tableName,
      this.tableType,
      this.logChanges,
      this.isView,
      this.createScript,
      this.sessionIdsRole,
      this.idField,
      this.deletedField,
      this.modifiedDateField,
      this.modifiedByField,
      this.modifiedTimeField,
      this.queryString,
      this.tableId,
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
  final Iterable<T> values;
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
  FieldValues<T> values(Iterable<T> values) => new FieldValues<T>(id, values);
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
