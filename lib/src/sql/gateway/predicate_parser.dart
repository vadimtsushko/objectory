part of gateway;

class PredicateExpression {
  final List<String> _arguments;
  final String _expression;
  final List _variables;

  int get argumentsCount => _arguments.length;

  const PredicateExpression(List this._variables, List<String> this._arguments,
      String this._expression);

  Iterable get variables => _variables;

  String expression(List<String> arguments) {
    var e = _expression;
    for (var i = 0; i < argumentsCount; i++)
      e = e.replaceAll('${_arguments[i]}.', '${arguments[i]}.');
    return e;
  }
}

class PredicateParser {
  final ClosureMirror _mirror;
  final Function _predicate;
  Iterable<String> _arguments;
  String _expression;
  final List _variables = [];
  final Queue<bool> _comparisonResponses = new Queue();

  PredicateParser(Function predicate)
      :
        _predicate = predicate,
        _mirror = reflect(predicate);

  static PredicateExpression parse(Function predicate) {
    try {
      return new PredicateParser(predicate)._parse();
    } on PredicateParserException {
      rethrow;
    } catch (e) {
      throw const PredicateParserException('The predicate is not valid!');
    }
  }

  PredicateExpression _parse() {
    final match = new RegExp(r'\((.+?)\)\s*=>\s*(.*)').firstMatch(_source);
    _arguments = match[1].split(new RegExp(r'\s*,\s*'));
    _expression = match[2];
    _collectComparisonResponses();
    _resolveVariables();
    return new PredicateExpression(_variables, _arguments, _expression);
  }

  void _collectComparisonResponses() {
    _comparisonResponses.addAll(
        new RegExp(r'(&&|\|\|)').allMatches(_source).map((m) {
          return m[1] == '&&';
        }));
  }

  void _resolveVariables() {
    final rows = _arguments.map((row) => new _PredicateRowMock(
        row, _comparisonResponses)).toList();
    _mirror.apply(rows);
    for (_PredicateRowMock row in rows) {
      for (var field in row._fields.values) {
        for (var operation in field.operations) {
          final regExp = '${row._name}(?:\\.${field.name}|\\[[^\\]]*?\\])'r'\s*'
          '${operation[0]}'r'((?:\(.*\)|.)*?)(?=[&|=<>)]|$)';
          final value = operation[1];
          final replaceWith = (Match m) {
            return '${row._name}.${field
                .name} %PARSED_OPERATION%${operation[0]} ${_formatInjectedValue(
                value, m[1])} ';
          };
//          print(regExp);
//          print(_expression);
//          print(_expression
//              .replaceFirstMapped(new RegExp(regExp), replaceWith)
//              .replaceAll(' )', ')')
//              .trim());
          _expression = _expression
              .replaceFirstMapped(new RegExp(regExp), replaceWith)
              .replaceAll(' )', ')')
              .trim();
        }
      }
    }
    _expression = _expression.replaceAll('%PARSED_OPERATION%', '');
  }

  String _formatInjectedValue(Object value, String code) {
    if (value is _PredicateFieldMock) {
      final prefix = code.split(new RegExp(r'[.\[]')).first.trim();
      return '$prefix.${value.name}';
    }
    if (value is String) {
      _variables.add(value);
      return '?';
    }
    if (value is DateTime)
      return 'date(${value.toIso8601String()})';
    return '$value';
  }

  String get _source {
    return __source ?? (__source = _mirror.function.source);
  }

  String __source;
}

class _PredicateRowMock {
  final String _name;
  final Map<Symbol, _PredicateFieldMock> _fields = {};
  final Queue<bool> _comparisonResponses;

  _PredicateRowMock(String this._name, Queue<bool> this._comparisonResponses);

  noSuchMethod(Invocation invocation) {
    if (invocation.isGetter)
      return _field(invocation.memberName);
    return super.noSuchMethod(invocation);
  }

  operator [](String field) {
    return _field(new Symbol(field));
  }

  _PredicateFieldMock _field(Symbol name) {
    if (!_fields.containsKey(name))
      _fields[name] = (
          new _PredicateFieldMock(MirrorSystem.getName(name),
              _comparisonResponses));
    return _fields[name];
  }

  toString() => '$_name: [${_fields.values.join(', ')}]';
}

class _PredicateFieldMock {
  final String name;
  final List<List> operations = [];
  final Queue<bool> comparisonResponses;

  _PredicateFieldMock(String this.name, Queue<bool> this.comparisonResponses);

  operator ==(v) => _registerComparison('==', v);

  operator >=(v) => _registerComparison('>=', v);

  operator <=(v) => _registerComparison('<=', v);

  operator >(v) => _registerComparison('>', v);

  operator <(v) => _registerComparison('<', v);

  operator %(v) => _registerComparison('%', v);

  operator ^(v) => _registerComparison('^', v);

  operator ~/(v) => _registerComparison('~/', v);

  _registerComparison(String operator, value) {
    operations.add([operator, value]);
    return _getResponse();
  }

  bool _getResponse() {
    if (comparisonResponses.length == 0)
      return true;
    return comparisonResponses.removeFirst();
  }

  toString() => '$name: [${operations.join(', ')}]';
}

class PredicateParserException implements Exception {
  final String message;

  const PredicateParserException(String this.message);

  toString() => 'PredicateParserException: $message';
}
