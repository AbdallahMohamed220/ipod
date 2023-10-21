import 'dart:convert';

import 'package:http/http.dart' as http;

import '../apis/api.dart';
import '../models/system.dart';

class VariationsApi extends Api {
//get variation list from api
  Future<Map<String, dynamic>> get(String link) async {
    var variations;
    String url = link;
    String token = await System().getToken();
    var response =
        await http.get(Uri.parse(url), headers: this.getHeader(token));
    variations = jsonDecode(response.body);
    List variationList = [];
    variations['data'].forEach((value) {
      variationList.add(value);
    });
    Map<String, dynamic> apiResponse = {
      "nextLink": variations['links']['next'],
      "products": variationList
    };
    return apiResponse;
  }
}
