import 'query_builder.dart';

class SqlQueryBuilder {
  QueryBuilder parent;
  String tableName;
  String whereClause = '';
  String orderByClause = '';
  String limitClause = '';
  String skipClause = '';
  String joinClause = '';
  String rawQuery;
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
    rawQuery = sourceQuery['RAW_QUERY'];
    if (rawQuery != null) {
      return;
    }
    whereClause = ' WHERE ' + _processQueryNode(sourceQuery, tableName);
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

  String _processQueryNode(Map query, String nodeTableName) {
    if (nodeTableName == null) {
      nodeTableName = tableName;
    }
    if (query.length != 1) {
      throw new Exception(
          'Unexpected query structure at $query. Whole query: ${parent.map}');
    }
    var key = query.keys.first;
    if (key == 'AND') {
      List<Map> subComponents = query[key] as List<Map>;
      return '(' +
          subComponents
              .map((Map subQuery) => _processQueryNode(subQuery, nodeTableName))
              .join(' AND ') +
          ')';
    } else if (key == 'OR') {
      List<Map> subComponents = query[key] as List<Map>;
      return '(' +
          subComponents
              .map((Map subQuery) => _processQueryNode(subQuery, nodeTableName))
              .join(' OR ') +
          ')';
    } else {
      Map<String, dynamic> expressionMap = query[key] as Map<String, dynamic>;
      paramCounter++;
      if (expressionMap.length == 1) {
        params.add(expressionMap.values.first);
        return '"$nodeTableName"."$key" ${expressionMap.keys.first} @$paramCounter';
      } else if (expressionMap.length == 2) {
        String like = expressionMap['LIKE'];
        if (like != null) {
          if (expressionMap['caseInsensitive'] == true) {
            params.add(like);
            return 'UPPER("$nodeTableName"."$key") LIKE UPPER(@$paramCounter)';
          } else {
            params.add(like);
            return '"$nodeTableName"."$key" LIKE @$paramCounter';
          }
        }
        List oneFromList = expressionMap['IN'];
        if (oneFromList != null) {
          if (oneFromList.isEmpty) {
            paramCounter--;
            return '(false)';
          }
          List<String> subQuery = [];
          for (var each in oneFromList) {
            params.add(each);
            subQuery.add('@$paramCounter');
            paramCounter++;
          }
          paramCounter--;
          return '( "$nodeTableName"."$key" IN (${subQuery.join(', ')}))';
        }
      } else if (expressionMap.length == 3) {
        String joinTable = expressionMap['INNER_JOIN'];
        if (joinTable != null) {
          String joinField = expressionMap['JOIN_FIELD'];
          paramCounter--;
          Map filter = expressionMap['FILTER'];
          joinClause =
              'INNER JOIN "$joinTable" ON "$joinTable"."$joinField" = "${tableName}"."$key" \n';
          return _processQueryNode(filter['QUERY'], joinTable);
        }
      }
    }
    throw new Exception(
        'Unexpected branch in _processQueryNode expression = ${query}');
  }

  String getQuerySql() {
    processQueryPart();
    if (rawQuery != null) {
      return rawQuery;
    }
    if (parent != null) {
      if (parent.paramLimit != 0) {
        limitClause = ' LIMIT  ${parent.paramLimit}';
      }
      if (parent.paramSkip != 0) {
        skipClause = ' OFFSET  ${parent.paramSkip}';
      }
    }
    orderByClause = getOrderBy();
    return 'SELECT "$tableName".* FROM "$tableName" \n $joinClause $whereClause $orderByClause $limitClause  $skipClause';
  }

  String getDeleteSql() {
    processQueryPart();
    return 'DELETE FROM "$tableName" $whereClause';
  }

  String getQueryCountSql() {
    processQueryPart();
    return 'SELECT Count(*) FROM "$tableName" $joinClause $whereClause';
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

  static String getInsertCommand(
      String tableName, Map<String, dynamic> content) {
    int id = content['id'];
    List<String> fieldNames = content.keys.toList();
    fieldNames.remove('id');
    List<String> paramNames = fieldNames.map((el) => '@$el').toList();
    fieldNames.add('id');
    paramNames.add(id?.toString() ?? 'DEFAULT');
    return '''
    INSERT INTO "${tableName}"
      (${fieldNames.map((el)=>'"$el"').join(',')})
      VALUES (${paramNames.join(',')})
        RETURNING "id"
   ''';
  }
}
