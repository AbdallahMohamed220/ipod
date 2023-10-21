import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sellDatabase.dart';
import '../models/system.dart';
import 'api.dart';

class SellApi extends Api {
  //create a sell in api
  Future<Map<String, dynamic>> create(data) async {
    String url = this.apiUrl + "sell";
    var token = await System().getToken();
    var response = await http.post(Uri.parse(url),
        headers: this.getHeader('$token'), body: data);
    var info = jsonDecode(response.body);
    var result;

    if (info[0]['payment_lines'] != null) {
      result = {
        'transaction_id': info[0]['id'],
        'payment_lines': info[0]['payment_lines'],
        'invoice_url': info[0]['invoice_url']
      };
    } else if (info[0]['is_quotation'] != null) {
      result = {
        'transaction_id': info[0]['id'],
        'invoice_url': info[0]['invoice_url']
      };
    } else {
      result = null;
    }
    return result;
  }

  //update a sell in api
  Future<Map<String, dynamic>> update(transactionId, data) async {
    String url = this.apiUrl + "sell/$transactionId";
    var token = await System().getToken();
    var response = await http.put(Uri.parse(url),
        headers: this.getHeader('$token'), body: data);
    var sellResponse = jsonDecode(response.body);
    return {
      'payment_lines': sellResponse['payment_lines'],
      'invoice_url': sellResponse['invoice_url']
    };
  }

  //delete sell
  delete(transactionId) async {
    String url = this.apiUrl + "sell/$transactionId";
    var token = await System().getToken();
    var response =
        await http.delete(Uri.parse(url), headers: this.getHeader('$token'));
    if (response.statusCode == 200) {
      var sellResponse = jsonDecode(response.body);
      return sellResponse;
    } else {
      return null;
    }
  }

  //get specified sell
  getSpecifiedSells(List transactionIds) async {
    String ids = transactionIds.join(",");
    String url = this.apiUrl + "sell/$ids";
    var token = await System().getToken();
    var response = [];
    await http
        .get(Uri.parse(url), headers: this.getHeader('$token'))
        .then((value) {
      if (value.body.contains('data')) {
        response = jsonDecode(value.body)['data'];
        var responseTransactionIds = [];
        response.forEach((element) {
          responseTransactionIds.add(element['id']);
        });
        transactionIds.forEach((id) async {
          if (!responseTransactionIds.contains(id)) {
            await SellDatabase().getSellByTransactionId(id).then((value) {
              SellDatabase().deleteSell(value[0]['id']);
            });
          }
        });
      }
    });
    return response;
  }
}
