import 'query_builder.dart';
import 'persistent_object.dart';

class SqlQueryBuilder {
  QueryBuilder parent;
  String tableName;
  String whereClause = '';
  String orderByClause = '';
  String limitClause = '';
  String skipClause = '';
  List params = [];
  List paramPlaceholders = [];
  int paramCounter = -1;
  SqlQueryBuilder(this.tableName, this.parent);

  processQueryPart() {
    if (parent == null) {
      return;
    }
    Map sourceQuery = parent.map['QUERY'];
    if (sourceQuery == null) {
      return;
    }
    if (sourceQuery.isEmpty) {
      return;
    }
    whereClause = ' WHERE ' + _processQueryNode(sourceQuery);
  }

  String getOrderBy() {
    if (parent?.map == null) {
      return '';
    }
    Map orderByMap = parent.map['ORDERBY'];
    if (orderByMap == null) {
      return '';
    }
    List<String> fields = [];
    for (var each in orderByMap.keys) {
      String desc = orderByMap[each] == -1 ? ' DESC' : '';
      fields.add('"$each"$desc');
    }
    return ' ORDER BY ${fields.join(',')}';
  }

  String _processQueryNode(Map query) {
    if (query.length != 1) {
      throw new Exception(
          'Unexpected query structure at $query. Whole query: ${parent.map}');
    }
    var key = query.keys.first;
    if (key == 'AND') {
      List<Map> subComponents = query[key];
      return '(' +
          subComponents
              .map((Map subQuery) => _processQueryNode(subQuery))
              .join(' AND ') +
          ')';
    } else if (key == 'OR') {
      List<Map> subComponents = query[key];
      return '(' +
          subComponents
              .map((Map subQuery) => _processQueryNode(subQuery))
              .join(' OR ') +
          ')';
    } else {
      Map<String, dynamic> expressionMap = query[key];
      paramCounter++;
      if (expressionMap.length == 1) {
        params.add(expressionMap.values.first);
        return '"$key" ${expressionMap.keys.first} @$paramCounter';
      } else if (expressionMap.length == 2) {
        String like = expressionMap['LIKE'];
        if (like != null) {
          if (expressionMap['caseInsensitive'] == true) {
            params.add(like);
            return 'UPPER("$key") LIKE UPPER(@$paramCounter)';
          } else {
            params.add(like);
            return '"$key" LIKE @$paramCounter';
          }
        }
        List oneFromList = expressionMap['IN'];
        if (oneFromList != null) {
          List<String> subQuery = [];
          for (var each in oneFromList) {
            params.add(each);
            subQuery.add('"$key" = (@$paramCounter)');
            paramCounter++;
          }

          return '(${subQuery.join(' OR ')})';
        }
      }
    }
    throw new Exception(
        'Unexpected branch in _processQueryNode expression = ${query}');
  }

  String getQuerySql() {
    processQueryPart();
    if (parent != null) {
      if (parent.paramLimit != 0) {
        limitClause = ' LIMIT  ${parent.paramLimit}';
      }
      if (parent.paramSkip != 0) {
        skipClause = ' OFFSET  ${parent.paramSkip}';
      }
    }
    orderByClause = getOrderBy();
    return 'SELECT * FROM "$tableName" $whereClause $orderByClause $limitClause  $skipClause';
  }

  String getDeleteSql() {
    processQueryPart();
    return 'DELETE FROM "$tableName" $whereClause';
  }

  String getQueryCountSql() {
    processQueryPart();
    return 'SELECT Count(*) FROM "$tableName" $whereClause';
  }

  String getUpdateSql(Map<String, dynamic> toUpdate) {
    processQueryPart();
    List<String> setOperations = [];
    for (var key in toUpdate.keys) {
      paramCounter++;
      setOperations.add('"$key" = @$paramCounter');
      params.add(toUpdate[key]);
    }
    return 'UPDATE "$tableName" SET ${setOperations.join(', ')} $whereClause';
  }

  static String getInsertCommand(String tableName, Map content) {
    List<String> fieldNames = content.keys.toList();
    fieldNames.remove('id');
    List<String> paramNames = fieldNames.map((el) => '@$el').toList();
    return '''
    INSERT INTO "${tableName}"
      (${fieldNames.map((el)=>'"$el"').join(',')})
      VALUES (${paramNames.join(',')})
        RETURNING "id"
   ''';
  }
}
