cd ..\packages\
rmdir mongo_dart
mklink /J mongo_dart c:\projects\mongo_dart\lib
rmdir lawndart
mklink /J lawndart c:\projects\lawndart\lib
rmdir unittest
mklink /J unittest c:\dart\dart-sdk\pkg\unittest\lib
cd ..\tool