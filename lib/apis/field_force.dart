import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/system.dart';
import 'api.dart';

class FieldForceApi extends Api {
  //add new visit
  create(Map visitDetails) async {
    try {
      String url = this.apiUrl + "field-force/create";
      var body = json.encode(visitDetails);
      var token = await System().getToken();
      var response = await http.post(Uri.parse(url),
          headers: this.getHeader('$token'), body: body);
      return response.statusCode;
    } catch (e) {}
  }

  //update visit status
  update(Map visitDetails, id) async {
    try {
      String url = this.apiUrl + "field-force/update-visit-status/$id";
      var body = json.encode(visitDetails);
      var token = await System().getToken();
      var response = await http.post(Uri.parse(url),
          headers: this.getHeader('$token'), body: body);
      return response.statusCode;
    } catch (e) {
      return null;
    }
  }
}
