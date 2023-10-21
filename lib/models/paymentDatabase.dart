import 'database.dart';

class PaymentDatabase {
  late DbProvider dbProvider;

  PaymentDatabase() {
    dbProvider = new DbProvider();
  }

  //add payment line
  Future<int> store(value) async {
    final db = await dbProvider.database;
    var response = db.insert('sell_payments', value);
    return response;
  }

  //delete payment line with its corresponding sellId
  Future<int> delete(sellId) async {
    final db = await dbProvider.database;
    var response = await db
        .delete('sell_payments', where: 'sell_id = ?', whereArgs: [sellId]);
    return response;
  }

  //update payment line
  Future<int> updateEditedPaymentLine(id, value) async {
    final db = await dbProvider.database;
    var response = await db
        .update('sell_payments', value, where: 'id = ?', whereArgs: [id]);
    return response;
  }

  //fetch payment line by sellId
  Future<List> get(sellId, {bool? allColumns}) async {
    final db = await dbProvider.database;
    List<String> columns;
    if (allColumns == true)
      columns = [
        'id',
        'payment_id',
        'amount',
        'method',
        'note',
        'is_return',
        'account_id'
      ];
    else
      columns = ['amount', 'method', 'note', 'account_id'];
    var response = db.query('sell_payments',
        columns: columns,
        where: 'sell_id = ? ORDER BY is_return',
        whereArgs: [sellId]);
    return response;
  }

  //fetch sell_payments according to is_return value
  Future<List> getPaymentLineByReturnValue(sellId, isReturn) async {
    final db = await dbProvider.database;
    var response = db.query('sell_payments',
        where: 'sell_id = ? AND is_return = ?', whereArgs: [sellId, isReturn]);
    return response;
  }

  //fetch payment line by id
  Future<Map> getPaymentLineById(id) async {
    final db = await dbProvider.database;
    List response =
        await db.query('sell_payments', where: 'id = ?', whereArgs: [id]);
    return response[0];
  }

  //delete payment line by List of id
  deletePaymentLineByIds(List<int> id) async {
    final db = await dbProvider.database;
    String ids = id.join(",");
    var response = await db.rawQuery('DELETE FROM "sell_payments" '
        'WHERE "id" in ($ids)');
    return response;
  }
}
