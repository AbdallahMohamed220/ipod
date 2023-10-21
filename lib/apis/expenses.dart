import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/system.dart';
import 'api.dart';

class ExpenseApi extends Api {
  //create an expense in api
  Future<Map<String, dynamic>?> create(data) async {
    try {
      String url = this.apiUrl + "expense";
      var token = await System().getToken();
      var response = await http.post(Uri.parse(url),
          headers: this.getHeader('$token'), body: jsonEncode(data));
      var info = jsonDecode(response.body);
      return info;
    } catch (e) {
      return null;
    }
  }

  //create an expense in api
  Future<List> get() async {
    try {
      String url = this.apiUrl + "expense-categories";
      var token = await System().getToken();
      var response =
          await http.get(Uri.parse(url), headers: this.getHeader('$token'));
      Map<String, dynamic>? result = jsonDecode(response.body);
      List expenseCategories = (result != null) ? result['data'] : [];
      return expenseCategories;
    } catch (e) {
      return [];
    }
  }
}
