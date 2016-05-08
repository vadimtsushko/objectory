part of drivers;

abstract class SqlStandards {
  String wrapSystemIdentifier(String systemId) {
    return '"$systemId"';
  }
}