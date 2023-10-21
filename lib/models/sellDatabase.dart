import 'database.dart';
import 'system.dart';

class SellDatabase {
  late DbProvider dbProvider;

  SellDatabase() {
    dbProvider = new DbProvider();
  }

  //add item to cart
  Future<int> store(value) async {
    final db = await dbProvider.database;
    var response = db.insert('sell_lines', value);
    return response;
  }

  //check presence of incomplete sellLine by variationId
  checkSellLine(int varId, {sellId}) async {
    var where;
    (sellId == null) ? where = 'is_completed = ?' : where = 'sell_id = ?';
    var arg = (sellId == null) ? 0 : sellId;
    final db = await dbProvider.database;
    var response = await db.query('sell_lines',
        where: "$where and variation_id = ?", whereArgs: [arg, varId]);
    return response;
  }

  //fetch sell_lines by sell_id
  Future<List> getSellLines(sellId) async {
    final db = await dbProvider.database;
    var response = await db.query('sell_lines',
        columns: [
          'product_id',
          'variation_id',
          'quantity',
          'unit_price',
          'tax_rate_id',
          'discount_amount',
          'discount_type',
          'note'
        ],
        where: "sell_id = ?",
        whereArgs: [sellId]);
    return response;
  }

  //fetch incomplete sellLine
  Future<List> getInCompleteLines(locationId, {sellId}) async {
    String where = 'is_completed = 0';
    if (sellId != null) where = 'sell_id = $sellId';

    //get product last sync datetime
    String productLastSync = await System().getProductLastSync();

    final db = await dbProvider.database;
    List res = await db.rawQuery(
        'SELECT DISTINCT SL.*, V.display_name AS name, V.sell_price_inc_tax,'
        ' CASE WHEN (qty_available IS NULL AND enable_stock = 0) THEN 9999 '
        ' WHEN (qty_available IS NULL AND enable_stock = 1) THEN 0 '
        ' ELSE (qty_available - COALESCE('
        ' (SELECT SUM(SL2.quantity) FROM sell_lines AS SL2 JOIN sell AS S on SL2.sell_id = S.id'
        ' WHERE (SL2.is_completed = 0 OR S.transaction_date > "$productLastSync") AND S.location_id = $locationId AND SL2.variation_id=V.variation_id)'
        ', 0))'
        ' END as "stock_available" '
        ' FROM "sell_lines" AS SL JOIN "variations" AS V on (SL.variation_id = V.variation_id) '
        ' LEFT JOIN "variations_location_details" as VLD '
        'ON SL.variation_id = VLD.variation_id AND SL.product_id = VLD.product_id AND VLD.location_id = $locationId '
        'where $where');
    return res;
  }

  //fetch incomplete sellLine
  Future<List> get({isCompleted, sellId}) async {
    String where;
    if (sellId != null) {
      where = 'sell_id = $sellId';
    } else {
      where = 'is_completed = $isCompleted';
    }
    final db = await dbProvider.database;
    List res = await db.rawQuery(
        'SELECT DISTINCT SL.*,V.display_name as name,V.sell_price_inc_tax,V.sub_sku,'
        'V.default_sell_price FROM "sell_lines" as SL JOIN "variations" as V '
        'on (SL.variation_id = V.variation_id) '
        'where $where');
    return res;
  }

  //update sell_lines by variationId
  Future<int> update(sellLineId, value) async {
    final db = await dbProvider.database;
    var response = await db
        .update('sell_lines', value, where: 'id = ?', whereArgs: [sellLineId]);
    return response;
  }

  //update sell_lines after creating a sell
  Future<int> updateSellLine(value) async {
    final db = await dbProvider.database;
    var response = await db
        .update('sell_lines', value, where: 'is_completed = ?', whereArgs: [0]);
    return response;
  }

  //delete sell_line
  Future<int> delete(int varId, int prodId, {sellId}) async {
    String where;
    var args;
    if (sellId == null) {
      where = 'is_completed = ? and variation_id = ? and product_id = ?';
      args = [0, varId, prodId];
    } else {
      where = 'sell_id = ? and variation_id = ? and product_id = ?';
      args = [sellId, varId, prodId];
    }
    final db = await dbProvider.database;
    var response = await db.delete('sell_lines', where: where, whereArgs: args);
    return response;
  }

  //delete sell_line by sellId
  Future<int> deleteSellLineBySellId(sellId) async {
    final db = await dbProvider.database;
    var response = await db
        .delete('sell_lines', where: 'sell_id = ?', whereArgs: [sellId]);
    return response;
  }

  //create sell
  Future<int> storeSell(Map<String, dynamic> value) async {
    final db = await dbProvider.database;
    var response = await db.insert('sell', value);
    return response;
  }

  //empty sells and sell details
  deleteSellTables() async {
    final db = await dbProvider.database;
    await db.delete('sell');
    await db.delete('sell_lines');
    await db.delete('sell_payments');
  }

  //fetch current sales from database
  Future<List> getSells({bool? all}) async {
    final db = await dbProvider.database;
    var response = (all == true)
        ? await db.query('sell', orderBy: 'id DESC')
        : await db.query('sell',
            orderBy: 'id DESC', where: 'is_quotation = ?', whereArgs: [0]);
    return response;
  }

  //fetch transactionIds of synced sales from sell table
  Future<List> getTransactionIds() async {
    final db = await dbProvider.database;
    var response = await db.query('sell',
        columns: ['transaction_id'],
        where: 'transaction_id != ?',
        whereArgs: ['null']);
    var ids = [];
    response.forEach((element) {
      ids.add(element['transaction_id']);
    });
    return ids;
  }

  //fetch sales by sellId
  Future<List> getSellBySellId(sellId) async {
    final db = await dbProvider.database;
    var response = await db.query('sell', where: 'id = ?', whereArgs: [sellId]);
    return response;
  }

  //fetch sales by TransactionId
  Future<List> getSellByTransactionId(transactionId) async {
    final db = await dbProvider.database;
    var response = await db
        .query('sell', where: 'transaction_id = ?', whereArgs: [transactionId]);
    return response;
  }

  //fetch not synced sales
  Future<List> getNotSyncedSells() async {
    final db = await dbProvider.database;
    var response = await db.query('sell', where: 'is_synced = 0');
    return response;
  }

  //update sale
  Future<int> updateSells(sellId, value) async {
    final db = await dbProvider.database;
    var response =
        await db.update('sell', value, where: 'id = ?', whereArgs: [sellId]);
    return response;
  }

  //Delete all lines where is_completed = 0
  Future<int> deleteInComplete() async {
    final db = await dbProvider.database;
    var response = await db
        .delete('sell_lines', where: 'is_completed = ?', whereArgs: [0]);
    return response;
  }

  Future<String> countSellLines({isCompleted, sellId}) async {
    String where;

    if (sellId != null) {
      where = 'sell_id = $sellId';
    } else {
      where = 'is_completed = 0';
    }

    final db = await dbProvider.database;
    var response = await db
        .rawQuery('SELECT COUNT(*) AS counts FROM sell_lines WHERE $where');
    return response[0]['counts'].toString();
  }

  //delete a sell and corresponding sellLines from database
  deleteSell(int sellId) async {
    final db = await dbProvider.database;
    await db.delete('sell', where: 'id = ?', whereArgs: [sellId]);
    await db.delete('sell_lines', where: 'sell_id = ?', whereArgs: [sellId]);
    await db.delete('sell_payments', where: 'sell_id = ?', whereArgs: [sellId]);
  }
}
