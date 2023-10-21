import 'dart:convert' as convert;

import 'package:http/http.dart' as http;

import '../config.dart';

class Api {
  String baseUrl = Config.baseUrl,
      apiUrl = Config.baseUrl + 'connector/api/',
      clientId = Config().clientId,
      clientSecret = Config().clientSecret;

  //validate the login details
  Future<Map?> login(String username, String password) async {
    String url = baseUrl + "oauth/token";

    Map body = {
      'grant_type': 'password',
      'client_id': clientId,
      'client_secret': clientSecret,
      'username': username,
      'password': password,
    };
    var response = await http.post(Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body);
    var jsonResponse = convert.jsonDecode(response.body);
    print(jsonResponse);

    if (response.statusCode == 200) {
      //logged in successfully
      return {'success': true, 'access_token': jsonResponse['access_token']};
    } else if (response.statusCode == 401) {
      //Invalid credentials
      return {'success': false, 'error': jsonResponse['error']};
    } else {
      return null;
    }
  }

  getHeader(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token'
    };
  }
}
