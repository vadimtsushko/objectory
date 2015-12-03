##Objectory - object document mapper for server-side and client side Dart applications
##Update: Please consider that library as unsuppoprted and not in active developement. Current updates (>0.3.22 published to pub) are mostly suited for usage in concrete scenario of internal project.


Objectory provides typed, checked environment to model, save and query data persisted on MongoDb.

Objectory provides identical API for server side and browser applications (both Dartium and dart2js supported).

[![Build Status](https://drone.io/github.com/vadimtsushko/objectory/status.png)](https://drone.io/github.com/vadimtsushko/objectory/latest)
###Getting started

- Clone Objectory from [github repository](https://github.com/vadimtsushko/objectory)
- Run **pub install** in the root of Objectory.

Now you may run server-side blog example: */example/console/blog_console.dart*. This example uses connection to free MongoLab account 

- Install MongoDb locally. Ensure that MongoDB is running  with default parameters (host 127.0.0.7, port 27017, authentication disabled)

Now you may run server side objectory tests: *test/base_objectory_tests.dart* and *test/vm_implementation_tests.dart*

- While running local MongoDB process, start websocket objectory server: *bin/objectory_server.dart*
 
- Configure Dartium launches for *test/objectory_test.html* and */example/blog.html* In group Dartium settings uncheck *Run in checked mode* and *Enable debugging*.  

Now you may run browser tests and blog example (port of server-side example to browser) both in Dartium and as JavaScript. JavaScript launches do not require any special setup.

See [Quick tour](https://github.com/vadimtsushko/objectory/blob/master/doc/quick_tour.md) and [API documentation](http://vadimtsushko.github.io/objectory/) for futher information

See also [Sample full stack application](https://github.com/vadimtsushko/angular_objectory_demo) with

- Angular.dart as primary framework
- MongoDb as backend DB
- Objectory as object/document mapper
- Rikulo Stream Web server to serve static content and as a container for Objectory WebSocket handler. 

