part of gateway;

typedef Future Transaction(Gateway gateway);

class Migrator {
  final Gateway _gateway;
  Query _table;

  Migrator(Gateway this._gateway) {
    _table = _gateway.table('__migrations');
  }

  Future run(Set<Type> migrations) async {
    try {
      await _createTable();
    } catch (e) {}
    final runMigrations = await _getRunMigrations().toList();
    final chargedMigrations = await _chargeMigrations(migrations);
    if (!_startsWith(chargedMigrations.keys, runMigrations))
      throw new MigrationException(
          'New migrations list is not compatible with the old one. '
              'Please roll back first.');

    for (final old in runMigrations)
      chargedMigrations.remove(old);

    await _migrate(chargedMigrations);
  }

  Future _migrate(Map<String, Transaction> transactions) async {
    for (final name in transactions.keys) {
      await _table.add({'name': name});
      await transactions[name](_gateway);
    }
  }

  bool _startsWith(Iterable<String> newIterable, Iterable<String> old) {
    final theNew = newIterable.toList();
    final theOld = old.toList();
    for (final oldItem in theOld)
      if (theNew.removeAt(0) != oldItem)
        return false;
    return true;
  }

  Map<String, Transaction> _chargeMigrations(Set<Type> migrations) {
    return new Map.fromIterables(
        _nameMigrations(migrations),
        _getTransactions(migrations, #run));
  }

  Map<String, Transaction> _chargeRollbacks(Set<Type> migrations) {
    return new Map.fromIterables(
        _nameMigrations(migrations),
        _getTransactions(migrations, #rollback));
  }

  Iterable<String> _nameMigrations(Set<Type> migrations) {
    return migrations
        .map(reflectType)
        .map((TypeMirror m) => m.simpleName)
        .map(MirrorSystem.getName);
  }

  Iterable<Transaction> _getTransactions(Set<Type> migrations,
      Symbol transaction) {
    return migrations
        .map(reflectType)
        .map((ClassMirror m) => m.newInstance(const Symbol(''), []))
        .map((InstanceMirror i) => i
        .getField(transaction)
        .reflectee);
  }

  Future _createTable() {
    return _gateway.create('__migrations', (Schema schema) {
      schema.id();
      schema.string('name').unique();
    });
  }

  Stream<String> _getRunMigrations() {
    return _table.get().map((row) => row['name']);
  }

  Future rollback(Set<Type> migrations) async {
    final runMigrations = await _getRunMigrations().toList();
    final chargedRollbacks = _chargeRollbacks(migrations);
    for (final old in runMigrations.reversed)
      await chargedRollbacks[old](_gateway);
    await _gateway.drop('__migrations');
  }
}

class MigrationException implements Exception {
  final String message;

  MigrationException(String this.message);

  toString() => 'MigrationException: $message';
}
