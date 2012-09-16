#library("json_encoder");
#import("dart:json");
#import("dart:math");
class JsonEncoder {
  static const int OBJECT_START = 123; // {
  static const int ARRAY_START  = 91;  // [
  static const int ZERO         = 48;  // 0
  static const int NINE         = 57;  // 9
  static const int SIGN         = 45;  // -

  static const String DATE_PREFIX = "/Date(";
  static const String DATE_SUFFIX = ")/";
  static const String TRUE  = "true";
  static const String FALSE = "false";

  List<int> toBytes(Object obj) => stringify(obj).charCodes();

  String stringify(Object obj) =>
      obj == null ?
      ""
    : obj is String ?
      obj
    : obj is Date ?
      "/Date(${(obj as Date).toUtc().millisecondsSinceEpoch})/"
    : obj is bool || obj is num ?
      obj.toString() :
      JSON.stringify(obj);

  Object toObject(List<int> bytes) =>
      bytes == null || bytes.length == 0 ?
      null
    : _isJson(bytes[0]) ?
      JSON.parse(new String.fromCharCodes(bytes)) :
      _fromBytes(bytes);

  bool _isJson(int firstByte) =>
      firstByte == OBJECT_START || firstByte == ARRAY_START || firstByte == SIGN
   || (firstByte >= ZERO && firstByte <= NINE);

  Object _fromBytes(List<int> bytes){    
      String str = new String.fromCharCodes(bytes);
      if (str.startsWith(DATE_PREFIX)) {
        int epoch = parseInt(str.substring(DATE_PREFIX.length, str.length - DATE_SUFFIX.length));
        return new Date.fromMillisecondsSinceEpoch(epoch, isUtc: true);
      }
      if (str == TRUE)  return true;
      if (str == FALSE) return false;
      return str;  
    return bytes;
  }
}