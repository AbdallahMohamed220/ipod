import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';

class User extends Api {
  Future<Map> get(var token) async {
    String url = apiUrl + "user/loggedin";
    var response =
        await http.get(Uri.parse(url), headers: this.getHeader(token));
    var userDetails = jsonDecode(response.body);
    Map userDetailsMap = userDetails['data'];
    return userDetailsMap;
  }
}
