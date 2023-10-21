import 'dart:convert';

import 'package:http/http.dart' as http;

import '../apis/tax.dart';
import '../models/system.dart';
import 'api.dart';
import 'contact.dart';

class SystemApi {
  Future<void> store() async {
    await Business().get();
    await Permissions().get();
    await ActiveSubscription().get();
    await CustomerApi().get();
    await Brand().get();
    await Category().get();
    await Payment().get();
    await Tax().get();
    await Location().get();
    await PaymentAccounts().get();
  }
}

class Brand extends Api {
  var brands;

  Future<List> get() async {
    try {
      String url = this.apiUrl + "brand";
      var token = await System().getToken();
      var response =
          await http.get(Uri.parse(url), headers: this.getHeader('$token'));
      brands = jsonDecode(response.body);
      var brandList = brands['data'];
      System().insert('brand', jsonEncode(brandList));
      return brandList;
    } catch (e) {
      return [];
    }
  }
}

class Category extends Api {
  var taxonomy;

  Future<List> get() async {
    try {
      String url = this.apiUrl + "taxonomy?type=product";
      var token = await System().getToken();
      var response =
      await http.get(Uri.parse(url), headers: this.getHeader('$token'));
      taxonomy = jsonDecode(response.body);
      var categoryList = taxonomy['data'];
      System().insert('taxonomy', jsonEncode(categoryList));
      taxonomy['data'].forEach((element) {
        if (element['sub_categories'].isNotEmpty) {
          element['sub_categories'].forEach((value) {
            System().insert(
                'sub_categories',
                jsonEncode({'id': value['id'], 'name': value['name']}),
                value['parent_id']);
          });
        }
      });
      return categoryList;
    } catch (e) {
      return [];
    }
  }
}

class Payment extends Api {
  late Map payment;

  Future<List> get() async {
    try {
      String url = this.apiUrl + "payment-methods";
      var token = await System().getToken();
      var response =
          await http.get(Uri.parse(url), headers: this.getHeader('$token'));
      payment = jsonDecode(response.body);
      List paymentList = [];
      payment.forEach((key, value) {
        paymentList.add({key: value});
      });
      System().insert('payment_methods', jsonEncode(paymentList));
      return paymentList;
    } catch (e) {
      return [];
    }
  }
}

class Permissions extends Api {
  get() async {
    try {
      String url = apiUrl + "user/loggedin";
      var token = await System().getToken();
      var response =
          await http.get(Uri.parse(url), headers: this.getHeader(token));
      var userDetails = jsonDecode(response.body);
      Map userDetailsMap = userDetails['data'];
      if (userDetailsMap.containsKey('all_permissions')) {
        var userData = jsonEncode(userDetailsMap['all_permissions']);
        await System().insert('user_permissions', userData);
      }
    } catch (e) {}
  }
}

class Location extends Api {
  var locations;

  Future<List?> get() async {
    try {
      String url = this.apiUrl + "business-location";
      var token = await System().getToken();
      var response =
          await http.get(Uri.parse(url), headers: this.getHeader('$token'));
      locations = jsonDecode(response.body);

      List? locationList = locations['data'];
      System().insert('location', jsonEncode(locationList));
      if (locationList != null) {
        locationList.forEach((element) {
          System().insert('payment_method',
              jsonEncode(element['payment_methods']), element['id']);
        });
      }
      return locationList;
    } catch (e) {
      return [];
    }
  }
}

class Business extends Api {
  var business;

  Future<List> get() async {
    try {
      String url = this.apiUrl + "business-details";
      var token = await System().getToken();
      var response =
          await http.get(Uri.parse(url), headers: this.getHeader('$token'));
      business = jsonDecode(response.body);
      List businessDetails = [business['data']];
      System().insert('business', jsonEncode(businessDetails));
      return businessDetails;
    } catch (e) {
      return [];
    }
  }
}

class ActiveSubscription extends Api {
  var activeSubscription;

  Future<List> get() async {
    try {
      String url = this.apiUrl + "active-subscription";
      var token = await System().getToken();
      var response =
          await http.get(Uri.parse(url), headers: this.getHeader('$token'));
      activeSubscription = jsonDecode(response.body);
      List activeSubscriptionDetails = (activeSubscription['data'].isNotEmpty)
          ? [activeSubscription['data']]
          : [];
      System()
          .insert('active-subscription', jsonEncode(activeSubscriptionDetails));
      return activeSubscriptionDetails;
    } catch (e) {
      return [];
    }
  }
}

class PaymentAccounts extends Api {
  Future<List> get() async {
    try {
      var accounts;
      String url = this.apiUrl + "payment-accounts";
      var token = await System().getToken();
      var response =
          await http.get(Uri.parse(url), headers: this.getHeader('$token'));
      accounts = jsonDecode(response.body);
      List paymentAccounts = accounts['data'];
      System().insert('payment_accounts', jsonEncode(paymentAccounts));
      return paymentAccounts;
    } catch (e) {
      return [];
    }
  }
}
