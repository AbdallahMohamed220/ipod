// import 'package:call_log/call_log.dart';
import 'package:flutter/material.dart';

import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../pages/login.dart';
import 'database.dart';

class FollowUpModel {
  var createFollowUpMap;
  var followUpMap;
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  followUpForm(customerDetail) {
    followUpMap = {
      'id': customerDetail['contact_id'],
      'followUpId': customerDetail['id'],
      'name': '${customerDetail['customer']['name']}',
      'mobile': '${customerDetail['customer']['mobile']}',
      'landline': '${customerDetail['customer']['landline']}',
      'alternate_number': '${customerDetail['customer']['alternate_number']}',
      'title': '${customerDetail['title']}',
      'status': '${customerDetail['status']}',
      if (customerDetail['followup_category'] != null)
        'followup_category': {
          'id': int.parse(customerDetail['followup_category']['id'].toString()),
          'name': customerDetail['followup_category']['name']
        },
      'schedule_type': '${customerDetail['schedule_type']}',
      'start_datetime': '${customerDetail['start_datetime']}',
      'end_datetime': '${customerDetail['end_datetime']}',
      'description': customerDetail['description'] ?? ''
    };
    return followUpMap;
  }

  submitFollowUp(
      {id,
      contactId,
      title,
      scheduleType,
      status,
      followUpCategoryId,
      startDate,
      endDate,
      description,
      duration}) {
    createFollowUpMap = {
      'title': title,
      'contact_id': contactId,
      'schedule_type': scheduleType,
      'user_id': [USERID],
      'status': status,
      'followup_category_id': followUpCategoryId,
      'start_datetime': '$startDate',
      'end_datetime': '$endDate',
      'description': '$description',
      'followup_additional_info': (duration != null && scheduleType == 'call')
          ? {'call duration': '$duration'}
          : ''
    };
    return createFollowUpMap;
  }

  // Future<CallLogEntry> getLogs(number) async {int from = DateTime.now().subtract(Duration(hours: 8)).millisecondsSinceEpoch;String numberQuery = '%${number.replaceAll(RegExp("[^0-9]"), "")}';Iterable<CallLogEntry> entries = await CallLog.query(number: numberQuery, dateFrom: from);return (entries.isNotEmpty) ? entries.first : null;}

  //calling widget
  Widget callCustomer() {
    return Container(
      margin: EdgeInsets.only(left: MySize.size8!),
      decoration: BoxDecoration(
        color: themeData.colorScheme.secondaryVariant,
        borderRadius: BorderRadius.all(Radius.circular(MySize.size8!)),
        boxShadow: [
          BoxShadow(
            color: themeData.cardTheme.shadowColor!.withAlpha(48),
            blurRadius: 3,
            offset: Offset(0, 1),
          )
        ],
      ),
      padding: EdgeInsets.all(MySize.size4!),
      child: Icon(
        Icons.call,
        color: themeData.colorScheme.background,
      ),
    );
  }
}

class Contact {
  late DbProvider dbProvider;

  Contact() {
    dbProvider = new DbProvider();
  }

  Map<String, dynamic> contactModel(element) {
    //contact model
    Map<String, dynamic> customer = {
      'id': element['id'],
      'name': element['supplier_business_name'] ?? element['name'],
      'city': element['city'],
      'state': element['state'],
      'country': element['country'],
      'address_line_1': element['address_line_1'],
      'address_line_2': element['address_line_2'],
      'zip_code': element['zip_code'],
      'mobile': element['mobile']
    };
    return customer;
  }

  //save contact
  insertContact(customer) async {
    final db = await dbProvider.database;
    var response = await db.insert('contact', customer);
    return response;
  }

  //get customer name by contact_id
  getCustomerDetailById(id) async {
    final db = await dbProvider.database;
    List response =
        await db.query('contact', where: 'id = ?', whereArgs: ['$id']);
    var customerDetail = (response.length > 0) ? response[0] : null;
    return customerDetail;
  }

  //get customer name by contact_id
  Future<List<Map<String, dynamic>>> get({bool? all}) async {
    final db = await dbProvider.database;
    if (all == true) {
      List<Map<String, dynamic>> customers = await db.query('contact');
      return customers;
    } else {
      List<Map<String, dynamic>> customers = await db.query('contact',
          columns: ['id', 'name', 'mobile'], orderBy: 'name ASC');
      return customers;
    }
  }

  //empty contact table
  emptyContact() async {
    final db = await dbProvider.database;
    var response = await db.delete('contact');
    return response;
  }
}
