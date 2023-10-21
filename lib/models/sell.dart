import 'dart:convert';

import '../apis/sell.dart';
import '../models/paymentDatabase.dart';
import '../models/sellDatabase.dart';
import '../models/system.dart';

class Sell {
  //sync sell
  Future<bool> createApiSell({sellId, bool? syncAll}) async {
    List sales;
    (syncAll != null)
        ? sales = await SellDatabase().getNotSyncedSells()
        : sales = await SellDatabase().getSellBySellId(sellId);
    sales.forEach((element) async {
      List products = await SellDatabase().getSellLines(element['id']);
      //model map for creating new sell
      List<Map<String, dynamic>> sale = [
        {
          'location_id': element['location_id'],
          'contact_id': element['contact_id'],
          'transaction_date': element['transaction_date'],
          'invoice_no': element['invoice_no'],
          'status': element['status'],
          'sub_status':
              (element['is_quotation'].toString() == '1') ? 'quotation' : null,
          'tax_rate_id':
              (element['tax_rate_id'] == 0) ? null : element['tax_rate_id'],
          'discount_amount': element['discount_amount'],
          'discount_type': element['discount_type'],
          'change_return': element['change_return'],
          'products': products,
          'sale_note': element['sale_note'],
          'staff_note': element['staff_note'],
          'shipping_charges': element['shipping_charges'],
          'shipping_details': element['shipping_details'],
          'is_quotation': element['is_quotation'],
          'payments': await PaymentDatabase().get(element['id']),
        }
      ];

      //fetch paymentLine where is_return = 1
      List paymentDetail =
          await PaymentDatabase().getPaymentLineByReturnValue(element['id'], 1);
      //set change returnId for updating a sell in API
      var returnId =
          (paymentDetail.length > 0) ? paymentDetail[0]['payment_id'] : null;

      //model map for updating an existing sell
      Map<String, dynamic> editedSale = {
        'contact_id': element['contact_id'],
        'transaction_date': element['transaction_date'],
        'status': element['status'],
        'tax_rate_id':
            (element['tax_rate_id'] == 0) ? null : element['tax_rate_id'],
        'discount_amount': element['discount_amount'],
        'discount_type': element['discount_type'],
        'sale_note': element['sale_note'],
        'staff_note': element['staff_note'],
        'shipping_charges': element['shipping_charges'],
        'shipping_details': element['shipping_details'],
        'is_quotation': element['is_quotation'],
        'change_return': element['change_return'],
        'change_return_id': returnId,
        'products': products,
        'payments': await PaymentDatabase()
            .getPaymentLineByReturnValue(element['id'], 0),
      };
      if (element['is_synced'] == 0) {
        if (element['transaction_id'] != null) {
          var sell = jsonEncode(editedSale);
          Map<String, dynamic> updatedResult =
              await SellApi().update(element['transaction_id'], sell);
          var result = updatedResult['payment_lines'];
          if (result != null) {
            await SellDatabase().updateSells(element['id'],
                {'is_synced': 1, 'invoice_url': updatedResult['invoice_url']});
            //delete existing payment lines
            await PaymentDatabase().delete(element['id']);
            result.forEach((paymentLine) async {
              //store payment lines from response
              await PaymentDatabase().store({
                'sell_id': element['id'],
                'method': paymentLine['method'],
                'amount': paymentLine['amount'],
                'note': paymentLine['note'],
                'payment_id': paymentLine['id'],
                'is_return': paymentLine['is_return'],
                'account_id': paymentLine['account_id']
              });
            });
          }
        } else {
          var sell = jsonEncode({'sells': sale});
          var result = await SellApi().create(sell);
          if (result != null) {
            await SellDatabase().updateSells(element['id'], {
              'is_synced': 1,
              'transaction_id': result['transaction_id'],
              'invoice_url': result['invoice_url']
            });
            if (result['payment_lines'] != null) {
              //delete existing paymentLines with reference to sellId
              await PaymentDatabase().delete(element['id']);
              //update paymentId and isReturn for each sellPayment
              result['payment_lines'].forEach((paymentLine) async {
                await PaymentDatabase().store({
                  'sell_id': element['id'],
                  'method': paymentLine['method'],
                  'amount': paymentLine['amount'],
                  'note': paymentLine['note'],
                  'payment_id': paymentLine['id'],
                  'is_return': paymentLine['is_return'],
                  'account_id': paymentLine['account_id']
                });
              });
            }
          }
        }
      }
    });
    return true;
  }

//toMap for creating payment
  makePayment(List payments, int sellId) {
    payments.forEach((element) async {
      Map<String, dynamic> payment = {
        'sell_id': sellId,
        'method': element['method'],
        'amount': element['amount'],
        'note': element['note'],
        'account_id': element['account_id']
      };
      await PaymentDatabase().store(payment);
    });
  }

//toMap create sell
  Future<Map<String, dynamic>> createSell(
      {String? invoiceNo,
      String? transactionDate,
      int? contactId,
      int? locId,
      int? taxId,
      String? discountType,
      double? discountAmount,
      double? invoiceAmount,
      double? changeReturn,
      double? pending,
      String? saleNote,
      String? staffNote,
      double? shippingCharges,
      String? shippingDetails,
      String? saleStatus,
      int? isQuotation,
      int? sellId}) async {
    Map<String, dynamic> sale;
    if (sellId == null) {
      //TODO:dynamic customer name and location name
      sale = {
        'transaction_date': transactionDate,
        'invoice_no': invoiceNo,
        'contact_id': contactId,
        'location_id': locId,
        'status': saleStatus,
        'tax_rate_id': taxId,
        'discount_amount': (discountAmount != null) ? discountAmount : 0.00,
        'discount_type': discountType,
        'invoice_amount': invoiceAmount,
        'change_return': changeReturn,
        'sale_note': saleNote,
        'staff_note': staffNote,
        'shipping_charges': shippingCharges,
        'shipping_details': shippingDetails,
        'pending_amount': pending,
        'is_quotation': isQuotation ?? 0,
        'is_synced': 0,
      };
      return sale;
    } else {
      sale = {
        'contact_id': contactId,
        'transaction_date': transactionDate,
        'location_id': locId,
        'status': saleStatus,
        'tax_rate_id': taxId,
        'discount_amount': (discountAmount != null) ? discountAmount : 0.0,
        'discount_type': discountType,
        'invoice_amount': invoiceAmount,
        'change_return': changeReturn,
        'sale_note': saleNote,
        'staff_note': staffNote,
        'shipping_charges': shippingCharges,
        'shipping_details': shippingDetails,
        'pending_amount': pending,
        'is_quotation': isQuotation ?? 0,
        'is_synced': 0,
      };
      return sale;
    }
  }

  //get unit_price
  getUnitPrice(unitPrice, taxId) async {
    double price = 0.00;
    await System().get('tax').then((value) {
      value.forEach((element) {
        if (element['id'] == taxId) {
          price = (unitPrice * 100) /
              (double.parse(element['amount'].toString()) + 100);
        }
      });
    });
    return price;
  }

/*
*  x + (x*15/100) = 575;
* 100x + 15x = 57500;
* x = 57500/115;
* */

//toMap create sellLine
  addToCart(product, sellId) async {
    //convert product to create sellLine
    double price =
        (product['tax_rate_id'] != 0 && product['tax_rate_id'] != null)
            ? await getUnitPrice(double.parse(product['unit_price'].toString()),
                product['tax_rate_id'])
            : product['unit_price'];
    var sellLine = {
      'sell_id': sellId,
      'product_id': product['product_id'],
      'variation_id': product['variation_id'],
      'quantity': 1,
      'unit_price': price,
      'tax_rate_id':
          (product['tax_rate_id'] == 0) ? null : product['tax_rate_id'],
      'discount_amount': 0.00,
      'discount_type': 'fixed',
      'note': '',
      'is_completed': 0
    };

    //check if item is added to cart/not
    List checkSellLine = await SellDatabase()
        .checkSellLine(sellLine['variation_id'], sellId: sellId);
    //if added increase quantity else addToCart
    if (checkSellLine.length > 0) {
      //update in database
      // var quantity = checkSellLine[0]['quantity'] + 1;
      // await SellDatabase()
      //     .update(checkSellLine[0]['id'], {'quantity': quantity});
    } else {
      //insert in database
      await SellDatabase().store(sellLine);
    }
  }

  //Reset cart
  resetCart() async {
    await SellDatabase().deleteInComplete();
  }

  Future<String> cartItemCount({isCompleted, sellId}) async {
    return await SellDatabase()
        .countSellLines(isCompleted: isCompleted, sellId: sellId);
  }

  //refresh sale
  Map<String, dynamic> createSellMap(Map sell, change, pending) {
    Map<String, dynamic> sale = {
      'transaction_date': sell['transaction_date'],
      'invoice_no': sell['invoice_no'],
      'contact_id': sell['contact_id'],
      'location_id': sell['location_id'],
      'status': sell['status'],
      'tax_rate_id': (sell['tax_id'] != 0) ? sell['tax_id'] : null,
      'discount_amount':
          (sell['discount_amount'] != null) ? sell['discount_amount'] : 0.00,
      'discount_type': sell['discount_type'],
      'invoice_amount': sell['final_total'],
      'change_return': change,
      'sale_note': sell['additional_notes'],
      'staff_note': sell['staff_note'],
      'shipping_charges': double.parse(sell['shipping_charges']),
      'shipping_details': sell['shipping_details'],
      'pending_amount': pending,
      'is_synced': 1,
    };
    return sale;
  }
}
