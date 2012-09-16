#library("json_encoder_test");
#import("package:objectory/src/json_encoder.dart");
#import('package:unittest/unittest.dart');

main(){
  JsonEncoder enc = new JsonEncoder();

  test("Encoder: serialize", (){
    expect(enc.stringify(null), "", "can encode nulls");
    expect(enc.stringify(1), "1", "can encode ints");
    expect(enc.stringify(-1), "-1", "can encode negative ints");
    expect(enc.stringify(1.1), "1.1", "can encode doubles");
    expect(enc.stringify(-1.1), "-1.1", "can encode negative doubles");
    expect(enc.stringify(''), "", "can encode empty strings");
    expect(enc.stringify('A'), "A", "can encode strings");
    expect(enc.stringify(true), "true", "can encode bools");
    expect(enc.stringify({}), "{}", "can encode empty Map");
    expect(enc.stringify([]), "[]", "can encode empty List");
    expect(enc.stringify({'A':1}), '{"A":1}', "can encode Map");
    expect(enc.stringify(['A']), '["A"]', "can encode List");
    expect(enc.stringify(new Date(2012,05,09,0,0,0,0)), "/Date(1336536000000)/", "can encode Date");
  });

  test("Encoder: deserialize", (){
    expect(enc.toObject(enc.toBytes(null)), null, "can decode nulls");
    expect(enc.toObject(enc.toBytes(1)), 1, "can decode ints");
    expect(enc.toObject(enc.toBytes(-1)), -1, "can decode negative ints");
    expect(enc.toObject(enc.toBytes(1.1)), 1.1, "can decode doubles");
    expect(enc.toObject(enc.toBytes(-1.1)), -1.1, "can decode negative doubles");
    expect(enc.toObject(enc.toBytes('')), null, "can decode empty strings");
    expect(enc.toObject(enc.toBytes('A')), "A", "can decode strings");
    expect(enc.toObject(enc.toBytes(true)), true, "can decode true");
    expect(enc.toObject(enc.toBytes(false)), false, "can decode false");
    expect(enc.toObject(enc.toBytes({})), {}, "can decode empty Map");
    expect(enc.toObject(enc.toBytes([])), [], "can decode empty List");
//    deepexpect(enc.toObject(enc.toBytes({'A':1})), {"A":1}, "can decode Map");
//    deepexpect(enc.toObject(enc.toBytes(['A'])), ["A"], "can decode List");
    Date utcDate = new Date(2012,05,09,0,0,0,0, isUtc: true);
    expect(enc.toObject(enc.toBytes(utcDate)), utcDate, "can decode UTC Date");


  });

}

