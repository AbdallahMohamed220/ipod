import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/contact_model.dart';
import '../models/system.dart';
import 'api.dart';

class CustomerApi extends Api {
  var customers;

  get() async {
    String? url = this.apiUrl + "contactapi?type=customer&per_page=500";
    var token = await System().getToken();
    do {
      try {
        var response =
            await http.get(Uri.parse(url!), headers: this.getHeader('$token'));
        url = jsonDecode(response.body)['links']['next'];
        jsonDecode(response.body)['data'].forEach((element) {
          Contact().insertContact(Contact().contactModel(element));
        });
      } catch (e) {
        return null;
      }
    } while (url != null);
  }

  Future<dynamic> add(Map customer) async {
    try {
      String url = this.apiUrl + "contactapi?type=customer";
      var body = json.encode(customer);
      var token = await System().getToken();
      var response = await http.post(Uri.parse(url),
          headers: this.getHeader('$token'), body: body);
      var result = await jsonDecode(response.body);
      return result;
    } catch (e) {
      return null;
    }
  }
}
