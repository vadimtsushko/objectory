library objectory_query;

import 'persistent_object.dart';
import 'field.dart';
import 'dart:convert';
import 'dart:collection';

QueryBuilder get where => new QueryBuilder();

class QueryBuilder {
//  static final RegExp objectIdRegexp =
//  new RegExp(".ObjectId...([0-9a-f]{24})....");
  Map map = {};
  bool paramFetchLinks = false;
  bool _isQuerySet = false;
  Map get _query {
    if (!_isQuerySet) {
      map['QUERY'] = {};
      _isQuerySet = true;
    }
    return map['QUERY'];
  }

  int paramSkip = 0;
  int paramLimit = 0;
  Map paramFields;

  Map get extParamsMap => {
        'skip': paramSkip,
        'limit': paramLimit,
        'fetchLinksMode': paramFetchLinks
      };

  String toString() => "SelectorBuilder($map)";

  _addExpression(String fieldName, value) {
    Map exprMap = {};
    exprMap[fieldName] = value;
    if (_query.isEmpty) {
      _query[fieldName] = value;
    } else {
      _addExpressionMap(exprMap);
    }
  }

  _addExpressionMap(Map expr) {
    if (_query.containsKey('AND')) {
      List expressions = _query['AND'];
      expressions.add(expr);
    } else {
      var expressions = [_query];
      expressions.add(expr);
      map['QUERY'] = {'AND': expressions};
    }
  }

  void _ensureParamFields() {
    if (paramFields == null) {
      paramFields = {};
    }
  }

  void _ensureOrderBy() {
    _query;
    if (!map.containsKey('ORDERBY')) {
      map['ORDERBY'] = new LinkedHashMap();
    }
  }

  QueryBuilder eq(Field field, value) {
    _addExpression(field.id, {"=": value});
    return this;
  }

  QueryBuilder id(int value) {
    return eq(Fields.id, value);
  }

  QueryBuilder ne(Field field, value) {
    _addExpression(field.id, {"<>": value});
    return this;
  }

  QueryBuilder gt(Field field, value) {
    _addExpression(field.id, {">": value});
    return this;
  }

  QueryBuilder lt(Field field, value) {
    _addExpression(field.id, {"<": value});
    return this;
  }

  QueryBuilder gte(Field field, value) {
    _addExpression(field.id, {">=": value});
    return this;
  }

  QueryBuilder lte(Field field, value) {
    _addExpression(field.id, {"<=": value});
    return this;
  }

  QueryBuilder like(Field field, String value, {bool caseInsensitive: false}) {
    _addExpression(field.id, {'LIKE': value, 'caseInsensitive': caseInsensitive});
    return this;
  }

//  QueryBuilder all(Field field, List values) {
//    _addExpression(field.id, {"\$all": values});
//    return this;
//  }

//  QueryBuilder notIn(Field field, List values) {
//    _addExpression(field.id, {"\$nin": values});
//    return this;
//  }

  QueryBuilder oneFrom(Field field, List values) {
    _addExpression(field.id, {"IN": values, "DUMMY": 0});
    return this;
  }

//  QueryBuilder exists(Field field) {
//    _addExpression(field.id, {"\$exists": true});
//    return this;
//  }
//
//  QueryBuilder notExists(Field field) {
//    _addExpression(field.id, {"\$exists": false});
//    return this;
//  }

//  QueryBuilder mod(Field field, int value) {
//    _addExpression(field.id, {
//      "\$mod": [value, 0]
//    });
//    return this;
//  }

//  SelectorBuilder match(Field field, String pattern,
//      {bool multiLine, bool caseInsensitive, bool dotAll, bool extended}) {
//    _addExpression(field.id, {
//      '\$regex': new BsonRegexp(pattern,
//          multiLine: multiLine,
//          caseInsensitive: caseInsensitive,
//          dotAll: dotAll,
//          extended: extended)
//    });
//    return this;
//  }

//  QueryBuilder inRange(Field field, min, max,
//      {bool minInclude: true, bool maxInclude: false}) {
//    Map rangeMap = {};
//    if (minInclude) {
//      rangeMap["\$gte"] = min;
//    } else {
//      rangeMap["\$gt"] = min;
//    }
//    if (maxInclude) {
//      rangeMap["\$lte"] = max;
//    } else {
//      rangeMap["\$lt"] = max;
//    }
//    _addExpression(field.id, rangeMap);
//    return this;
//  }

  QueryBuilder sortBy(Field field, {bool descending: false}) {
    _ensureOrderBy();
    int order = 1;
    if (descending) {
      order = -1;
    }
    map['ORDERBY'][field.id] = order;
    return this;
  }


  QueryBuilder fields(List<String> fields) {
    _ensureParamFields();
    for (var field in fields) {
      paramFields[field] = 1;
    }
    return this;
  }

  QueryBuilder excludeFields(List<String> fields) {
    _ensureParamFields();
    for (var field in fields) {
      paramFields[field] = 0;
    }
    return this;
  }

  QueryBuilder limit(int limit) {
    paramLimit = limit;
    return this;
  }

  QueryBuilder skip(int skip) {
    paramSkip = skip;
    return this;
  }

  QueryBuilder raw(Map rawSelector) {
    map = rawSelector;
    return this;
  }

//  QueryBuilder within(Field field, value) {
//    _addExpression(field.id, {
//      "\$within": {"\$box": value}
//    });
//    return this;
//  }
//
//  QueryBuilder near(Field field, var value, [double maxDistance]) {
//    if (maxDistance == null) {
//      _addExpression(field.id, {"\$near": value});
//    } else {
//      _addExpression(
//          field.id, {"\$near": value, "\$maxDistance": maxDistance});
//    }
//    return this;
//  }

  /// Combine current expression with expression in parameter.
  /// [See MongoDB doc](http://docs.mongodb.org/manual/reference/operator/and/#op._S_and)
  /// [QueryBuilder] provides implicit `and` operator for chained queries so these two expression will produce
  /// identical MongoDB queries
  ///
  ///     where.eq('price', 1.99).lt('qty', 20).eq('sale', true);
  ///     where.eq('price', 1.99).and(where.lt('qty',20)).and(where.eq('sale', true))
  ///
  /// Both these queries would produce json map:
  ///
  ///     {'QUERY': {'AND': [{'price':1.99},{'qty': {'\$lt': 20 }}, {'sale': true }]}}
  QueryBuilder and(QueryBuilder other) {
    if (_query.isEmpty) {
      throw new StateError('`And` opertion is not supported on empty query');
    }
    _addExpressionMap(other._query);
    return this;
  }

  /// Combine current expression with expression in parameter by logical operator **OR**.
  /// [See MongoDB doc](http://docs.mongodb.org/manual/reference/operator/and/#op._S_or)
  /// For example
  ///    inventory.find(where.eq('price', 1.99).and(where.lt('qty',20).or(where.eq('sale', true))));
  ///
  /// This query will select all documents in the inventory collection where:
  /// * the **price** field value equals 1.99 and
  /// * either the **qty** field value is less than 20 or the **sale** field value is true
  /// MongoDB json query from this expression would be
  ///      {'QUERY': {'AND': [{'price':1.99}, {'OR': [{'qty': {'\$lt': 20 }}, {'sale': true }]}]}}
  QueryBuilder or(QueryBuilder other) {
    if (_query.isEmpty) {
      throw new StateError('`And` opertion is not supported on empty query');
    }
    if (_query.containsKey('OR')) {
      List expressions = _query['OR'];
      expressions.add(other._query);
    } else {
      var expressions = [_query];
      expressions.add(other._query);
      map['QUERY'] = {'OR': expressions};
    }
    return this;
  }

  String getQueryString() {
    var result = JSON.encode(map);
    return result;
  }

  QueryBuilder fetchLinks() {
    paramFetchLinks = true;
    return this;
  }


  QueryBuilder clone() {
    var copy = where;
    copy.map = new Map.from(map);
    return copy;
  }
}

