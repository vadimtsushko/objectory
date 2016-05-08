import 'package:objectory/src/sql/gateway/gateway.dart';
import 'package:objectory/src/sql/drivers/drivers.dart';
main() async{
  var driver = new PostgresqlDriver(username: 'testdb', database: 'testdb');
  var gateway = new Gateway(driver);
  await gateway.connect();
  var query = gateway.table('User');
  var res = await query.add({'name': 'Vadim'});
  await gateway.disconnect();
}