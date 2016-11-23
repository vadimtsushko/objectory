import 'schema.dart';
import 'persistent_object.dart';


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
      logChanges: false,
      foreignKey: false,
      externalKey: false);
  static Field<DateTime> get modifiedDate => const Field<DateTime>(
      id: 'modifiedDate',
      label: 'Дата изм.',
      title: 'Дата изменения строки',
      type: DateTime,
      logChanges: false,
      foreignKey: false,
      externalKey: false);
  static Field<DateTime> get modifiedTime => const Field<DateTime>(
      id: 'modifiedTime',
      label: 'Время изм.',
      title: 'Время изменения строки',
      type: DateTime,
      logChanges: false,
      foreignKey: false,
      externalKey: false);
  static Field<DateTime> get modifiedBy => const Field<DateTime>(
      id: 'modifiedBy',
      label: 'Автор изм.',
      title: 'Автор последнего изменения строки',
      type: String,
      logChanges: false,
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
//
//
//
//class $AuditLog {
//  static Field<int> get tableId => const Field<int>(
//      id: 'tableId',
//      label: 'Код.',
//      title: 'Код таблицы',
//      parentTable: null,
//      parentField: '',
//      staticValue: '',
//      defaultValue: 0,
//      type: int,
//      logChanges: true,
//      foreignKey: false,
//      externalKey: true,
//      width: 0,
//      tootltipsOnContent: false);
//  static Field<int> get originalId => const Field<int>(
//      id: 'originalId',
//      label: 'Ид.',
//      title: 'Идентификатор объекта',
//      parentTable: null,
//      parentField: '',
//      staticValue: '',
//      defaultValue: 0,
//      type: int,
//      logChanges: true,
//      foreignKey: false,
//      externalKey: true,
//      width: 0,
//      tootltipsOnContent: false);
//  static Field<String> get operationType => const Field<String>(
//      id: 'operationType',
//      label: 'Тип',
//      title: 'Тип операции',
//      parentTable: null,
//      parentField: '',
//      staticValue: '',
//      defaultValue: '',
//      type: String,
//      logChanges: true,
//      foreignKey: false,
//      externalKey: false,
//      width: 0,
//      tootltipsOnContent: false);
//  static Field<String> get tableName => const Field<String>(
//      id: 'tableName',
//      label: 'Таблица',
//      title: 'Наименование исходной таблицы/представления',
//      parentTable: null,
//      parentField: '',
//      staticValue: '',
//      defaultValue: '',
//      type: String,
//      logChanges: true,
//      foreignKey: false,
//      externalKey: false,
//      width: 0,
//      tootltipsOnContent: false);
//  static Field<Map> get content => const Field<Map>(
//      id: 'content',
//      label: '',
//      title: '',
//      parentTable: null,
//      parentField: '',
//      staticValue: '',
//      defaultValue: null,
//      type: Map,
//      logChanges: true,
//      foreignKey: false,
//      externalKey: false,
//      width: 0,
//      tootltipsOnContent: false);
//  static TableSchema schema = new TableSchema(
//      tableName: 'AuditLog',
//      tableType: AuditLog,
//      tableId: 0,
//      logChanges: true,
//      isView: false,
//      sessionIdsRole: false,
//      idField: false,
//      deletedField: false,
//      modifiedDateField: true,
//      modifiedTimeField: true,
//      modifiedByField: true,
//      cacheValues: false,
//      createScript: '''''',
//      queryString: '''''',
//      superSchema: $PersistentObject.schema,
//      fields: {
//        'tableId': tableId,
//        'originalId': originalId,
//        'operationType': operationType,
//        'tableName': tableName,
//        'content': content
//      });
//}
//
//class AuditLog extends PersistentObject {
//  TableSchema get $schema => $AuditLog.schema;
//  int get tableId => getProperty('tableId');
//  set tableId(int value) => setProperty('tableId', value);
//  int get originalId => getProperty('originalId');
//  set originalId(int value) => setProperty('originalId', value);
//  String get operationType => getProperty('operationType');
//  set operationType(String value) => setProperty('operationType', value);
//  String get tableName => getProperty('tableName');
//  set tableName(String value) => setProperty('tableName', value);
//  Map<String, dynamic> get content =>
//      getProperty('content') as Map<String, dynamic>;
//  set content(Map<String, dynamic> value) => setProperty('content', value);
//}
