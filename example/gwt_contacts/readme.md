That is a port of Dart Polymer example GWT Contacts

In this sample Rikulo Stream web server used to run Objectory server process and also to serve all static files.

1. If you intend to use any non locally installed mongodb instance change MongoDb URI in webapp/main.dart and webapp/populate_db.dart accordingly
2. Run webapp/populate_db.dart. That shoud populate contact list with sample records
3. Run webapp/main.dart. That will start Stream web server on 127.0.0.1:8080.
4. Now you may run index.html from DartEditor or open http://127.0.0.1:8080/ in Dartium 