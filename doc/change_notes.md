#Recent change notes

###0.3.1

- Bugfix in WebSocket VM implementation.

###0.3.0

- Modelling API revamped. Classes in modelling designated by Type not by string names.
- Querying API revamped, more closely followed to mongo_db and mongo_dart patterns.

###0.2.2

- PersistentObject got getPersistentList method as preferred way to define List properties in models.  

###0.2.1

- match in QueryBuilder go named instead of positional parameters 
- where in QueryBuilder deprecated in favour of jsQuery
- range in QueryBuilder deprecated in favour of inRange
- test for match added
- test for jsQuery added

###0.2.0

- Client/Server communication moved from JsonExt to Bson (using new cross-platform version of bson)
- Bugfix on browser side - findOne still was using cache.

###0.1.9

- Change in dependencies - bson library separated from within mongo_dart 

###0.1.8

- Upgrade to Dart SDK version 0.5.0.1_r21823
- find() and findOne() always get objects from Db (If objects exists in cache they are replaced by fresh ones from Db) 

###0.1.7

- PersistentList inherit from ListBase. No more notimplemented methods and type warnings. 

###0.1.6

- Upgrade for Dart SDK version 0.4.7.5_r21658 (post M4)

###0.1.5

- Count() method implemented on all platforms

###0.1.4

- Upgrade for M4 changes
- Obectory server now does not log messages my default, verbosity switched by command line parameter --verbose

###0.1.3

- Bugfixes for PersistentObject methods: contains, indexIf, lastIndexOf
- save and remove methods returns Future (consistently with Objectory save and return)
- supported Dart SDK version 0.4.5.1_r21094

###0.1.0

- Support of dart:io version 2. (Stream-based).
- fetchLinks method of QueryBuilder (With it PersistentObjects in resultset of findOne and find prefetch linked objects)

###0.0.11

- Support for near and within geospatial queries in QueryBuilder (Thanks to Jesse https://github.com/FreakTheMighty)

###0.0.10

- Support for limit and skip operation in QueryBuilder.

###0.0.8

- Ready for M3, run in version 0.3.1_r17328

###0.0.7

- dart.js bootstrap file is moving to pub

###0.0.6

- Minor fixes
- Cleared all warnings from DartEditor
- Pubspec refers to dart_mongo from pub.dartlang.org
- Local_objectory_tests broken due to lawndart errors.

###0.0.5

- minor fixes
- sdk dependencies changed to pub.dartlang.org

###0.0.4

- Changes reflecting dart lib changes - methods to getters, such as Map.getKeys() and so on
