import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../apis/api.dart';
import '../apis/variations.dart';
import '../models/system.dart';
import 'database.dart';

class Variations {
  late DbProvider dbProvider;

  Variations() {
    dbProvider = new DbProvider();
  }

  //save variations and variations_locations
  store() async {
    String? link = Api().apiUrl + "variation?per_page=3000&not_for_selling=0";
    do {
      Map response = await VariationsApi().get("$link");
      List products = await response['products'];
      final db = await dbProvider.database;
      Batch batch = db.batch();
      List processedProductIds = [];

      //save variations
      products.forEach((variation) {
        Map<String, dynamic> tempProduct = {};
        tempProduct['product_id'] = variation['product_id'];
        tempProduct['variation_id'] = variation['variation_id'];
        tempProduct['product_name'] = variation['product_name'];
        tempProduct['product_variation_name'] =
            variation['product_variation_name'];
        tempProduct['variation_name'] = variation['variation_name'];
        tempProduct['display_name'] = variation['product_name'] +
            " " +
            variation['product_variation_name'] +
            " " +
            variation['variation_name'];
        tempProduct['sku'] = variation['sku'];
        tempProduct['sub_sku'] = variation['sub_sku'];
        tempProduct['type'] = variation['type'];
        tempProduct['enable_stock'] = variation['enable_stock'];
        tempProduct['brand_id'] = variation['brand_id'];
        tempProduct['unit_id'] = variation['unit_id'];
        tempProduct['category_id'] = variation['category_id'];
        tempProduct['sub_category_id'] = variation['sub_category_id'];
        tempProduct['tax_id'] = variation['tax_id'];
        tempProduct['default_sell_price'] = variation['default_sell_price'];
        tempProduct['sell_price_inc_tax'] = variation['sell_price_inc_tax'];
        tempProduct['product_image_url'] = variation['product_image_url'];
        tempProduct['product_description'] = variation['product_description'];
        List<Map<String, dynamic>> groupId = [];
        if (variation['selling_price_group'].length > 0) {
          variation['selling_price_group'].forEach((group) {
            groupId.add({
              'key': group['price_group_id'],
              'value': group['price_inc_tax']
            });
          });
          tempProduct['selling_price_group'] = jsonEncode(groupId);
        }
        //save product available in different locations
        variation['product_locations'].forEach((value) {
          if (!processedProductIds.contains(variation['product_id'])) {
            var tempProductLocation = {
              'product_id': variation['product_id'],
              'location_id': value['id']
            };
            batch.insert('product_locations', tempProductLocation);
          }
        });
        processedProductIds.add(variation['product_id']);

        if (variation['variation_location_details'].length > 0) {
          //save variation details
          variation['variation_location_details'].forEach((variationDetail) {
            Map<String, dynamic> tempProductDetail = {};
            tempProductDetail['product_id'] = variationDetail['product_id'];
            tempProductDetail['variation_id'] = variationDetail['variation_id'];
            tempProductDetail['location_id'] = variationDetail['location_id'];
            tempProductDetail['qty_available'] =
                double.parse(variationDetail['qty_available']);
            batch.insert('variations_location_details', tempProductDetail);
          });
        }
        batch.insert('variations', tempProduct);
      });
      link = response['nextLink'];
      await batch.commit(noResult: true);
    } while (link != null);
  }

  //get all variations
  get(
      {brandId,
      categoryId,
      subCategoryId,
      searchTerm,
      locationId,
      inStock,
      barcode,
      offset,
      byAlphabets,
      byPrice}) async {
    final db = await dbProvider.database;
    inStock = (inStock == null) ? false : inStock;

    var where = 'WHERE 1=1';
    var order = '';

    if (byAlphabets == 0) {
      order += 'product_name,';
    } else if (byAlphabets == 1) {
      order += 'product_name DESC,';
    }

    if (byPrice == 0) {
      order += 'sell_price_inc_tax,';
    } else if (byPrice == 1) {
      order += 'sell_price_inc_tax DESC,';
    }

    if (brandId != 0 && brandId != null) {
      where += ' AND V.brand_id = $brandId';
    }

    if (categoryId != 0 && categoryId != null) {
      where += ' AND V.category_id = $categoryId';
    }

    if (subCategoryId != 0 && subCategoryId != null) {
      where += ' AND V.sub_category_id = $subCategoryId';
    }

    if (searchTerm.length > 0) {
      where +=
          ' AND (V.display_name LIKE "%$searchTerm%" OR V.sub_sku LIKE "%$searchTerm%")';
    }

    if (inStock) {
      where += ' AND stock_available > 0';
    }

    if (barcode != null) {
      where += ' AND V.sub_sku LIKE "$barcode"';
    }

    //get product last sync datetime
    String productLastSync = await System().getProductLastSync();
    var result = db.rawQuery('SELECT DISTINCT V.* ,'
        'CASE WHEN (qty_available IS NULL AND enable_stock = 0) THEN 9999 '
        'WHEN (qty_available IS NULL AND enable_stock = 1) THEN 0 '
        'ELSE (qty_available - COALESCE('
        ' (SELECT SUM(SL.quantity) FROM sell_lines AS SL JOIN sell AS S on SL.sell_id = S.id'
        ' WHERE (SL.is_completed = 0 OR S.transaction_date > "$productLastSync") AND'
        ' S.location_id = $locationId AND SL.variation_id=V.variation_id AND S.is_quotation = 0), 0))'
        'END as "stock_available" '
        'FROM "variations" as V '
        'JOIN "product_locations" as PL '
        'on (V.product_id = PL.product_id AND PL.location_id = $locationId )'
        ' LEFT JOIN "variations_location_details" as VLD '
        'ON V.variation_id = VLD.variation_id AND VLD.location_id = $locationId '
        '$where ORDER BY ${order}id LIMIT 10 OFFSET ($offset-1)*10');
    return result;
  }

  //total no. of rows in variations table
  checkProductTable({var locationId}) async {
    final db = await dbProvider.database;
    var res = (locationId != null)
        ? await db.rawQuery('SELECT count(*)'
            'FROM "variations" as V '
            'JOIN "product_locations" as PL '
            'on (V.product_id = PL.product_id AND PL.location_id = $locationId )'
            ' LEFT JOIN "variations_location_details" as VLD '
            'ON V.variation_id = VLD.variation_id AND VLD.location_id = $locationId ')
        : await db.rawQuery("SELECT count(*) FROM variations", null);
    return res[0]['count(*)'];
  }

//  refresh variations and variations_locations
  refresh() async {
    var count = await checkProductTable();
    if (count > 0) {
      deleteVariationDetails().then((value) async {
        await store();
      });
    } else {
      await store();
    }
  }

  //empty variations
  deleteVariationDetails() async {
    final db = await dbProvider.database;
    await db.rawQuery("DELETE FROM variations");
    await db.rawQuery("DELETE FROM variations_location_details");
    await db.rawQuery("DELETE FROM product_locations");
  }
}
