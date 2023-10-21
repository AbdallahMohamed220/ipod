import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/system.dart';
import 'api.dart';

class Tax extends Api {
  var taxes;

  Future<List> get() async {
    try {
      String url = this.apiUrl + "tax";
      var token = await System().getToken();
      var response =
          await http.get(Uri.parse(url), headers: this.getHeader('$token'));
      taxes = jsonDecode(response.body);
      var taxList = taxes['data'];
      System().insert('tax', jsonEncode(taxList));
      return taxList;
    } catch (e) {
      return [];
    }
  }
}
