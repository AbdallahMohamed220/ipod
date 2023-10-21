import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/system.dart';
import 'api.dart';

class ContactPaymentApi extends Api {
  //Api request for selected customer due
  getCustomerDue(int customerId) async {
    try {
      var customer;
      String url = this.apiUrl + "contactapi/$customerId";
      var token = await System().getToken();
      var response = await http.get(
          //Encode the url
          Uri.parse(url),
          //only accept JSON response
          headers: this.getHeader('$token'));
      customer = jsonDecode(response.body);
      return customer;
    } catch (e) {
      return null;
    }
  }

  //contact payment via api
  Future<int?> postContactPayment(Map payment) async {
    try {
      String url = this.apiUrl + "contactapi-payment";
      var token = await System().getToken();
      Map data = payment;
      var response = await http.post(Uri.parse(url),
          headers: this.getHeader('$token'), body: jsonEncode(data));
      return response.statusCode;
    } catch (e) {
      return null;
    }
  }
}
