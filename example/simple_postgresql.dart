import 'package:objectory/src/sql/gateway/gateway.dart';
import 'package:objectory/src/sql/drivers/drivers.dart';
main() async{
  var driver = new PostgresqlDriver(username: 'testdb', database: 'testdb');
  var gateway = new Gateway(driver);
  await gateway.connect();
  //var res = await gateway.table('User').add({'name': 'Daniil'});
  var res = await gateway.table('User').add({'name': 'Вадим'});
  print(res);
  await gateway.disconnect();
}