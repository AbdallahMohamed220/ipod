import 'dart:ui';

// import 'package:call_log/call_log.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../apis/api.dart';
// import 'package:url_launcher/url_launcher.dart';

import '../apis/shipment.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../locale/MyLocalizations.dart';
import '../models/contact_model.dart';
import '../models/shipment.dart';
import '../models/system.dart';
// import 'googleMap.dart';

class Shipment extends StatefulWidget {
  @override
  _ShipmentState createState() => _ShipmentState();
}

class _ShipmentState extends State<Shipment> {
  List<String>? shipmentStatus;
  DateTime selectedDate = DateTime.now();
  String? nextPage = '', selectedStatus = '', selectedInlineStatus;
  List<dynamic> shipments = [];
  TextEditingController deliveredToController = new TextEditingController();
  ScrollController _scrollController = new ScrollController();

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    shipmentStatus = ShipmentModel().shipmentStatus;
    selectedStatus = shipmentStatus![0];
    getShipments();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        generateShipmentList();
      }
    });
  }

  getShipments() async {
    var date = selectedDate.toLocal().toString().split(' ')[0];
    nextPage = Api().apiUrl +
        "sell/?start_date=$date"
            "&shipping_status=$selectedStatus";
    generateShipmentList();
  }

  @override
  void dispose() {
    super.dispose();
    deliveredToController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text(AppLocalizations.of(context).translate('shipment'),
            style: AppTheme.getTextStyle(themeData.textTheme.headline6,
                fontWeight: 600)),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                  left: MySize.size20!,
                  top: MySize.size5!,
                  bottom: MySize.size10!),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  status(), shipmentDatePicker(),
                  // locateShipments()
                ],
              ),
            ),
            ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                itemCount: shipments.length,
                itemBuilder: (context, index) {
                  return block(index, shipments[index]['id'],
                      invoiceNo: shipments[index]['invoice_no'],
                      date: shipments[index]['transaction_date'],
                      customerName: shipments[index]['customerName'],
                      status: shipments[index]['shipping_status'],
                      deliverTo: shipments[index]['delivered_to'],
                      contactNo: shipments[index]['contact_no']);
                })
          ],
        ),
      ),
    );
  }

  //locate shipments in map
  Widget locateShipments() {
    return TextButton(
      style: TextButton.styleFrom(
        shape: StadiumBorder(side: BorderSide(color: customAppTheme.bgLayer3)),
      ),
      onPressed: () => Navigator.pushNamed(context, '/google_map'),
      child: Text('Map',
          style: AppTheme.getTextStyle(themeData.textTheme.subtitle1,
              color: themeData.colorScheme.onBackground)),
    );
  }

  //date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2015),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
        shipments = [];
        getShipments();
      });
  }

  //widget shipment
  Widget status() {
    return PopupMenuButton(
        onSelected: (String? item) {
          setState(() {
            selectedStatus = item;
            shipments = [];
            getShipments();
          });
        },
        itemBuilder: (BuildContext context) {
          return shipmentStatus!.map((String value) {
            return PopupMenuItem(
              value: value,
              height: MySize.size36!,
              child: Text(value,
                  style: AppTheme.getTextStyle(themeData.textTheme.bodyText2,
                      color: themeData.colorScheme.onBackground)),
            );
          }).toList();
        },
        color: themeData.backgroundColor,
        child: Container(
          padding: EdgeInsets.only(
              left: MySize.size12!,
              right: MySize.size12!,
              top: MySize.size8!,
              bottom: MySize.size8!),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(MySize.size20!)),
            color: customAppTheme.bgLayer1,
            border: Border.all(color: customAppTheme.bgLayer3),
          ),
          child: Row(
            children: <Widget>[
              Text(
                selectedStatus!,
                style: AppTheme.getTextStyle(
                  themeData.textTheme.bodyText1,
                  color: themeData.colorScheme.onBackground,
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: MySize.size4!),
                child: Icon(
                  MdiIcons.chevronDown,
                  size: MySize.size22,
                  color: themeData.colorScheme.onBackground,
                ),
              )
            ],
          ),
        ));
  }

  //inline status
  //widget shipment
  Widget inlineStatus() {
    return PopupMenuButton(
      onSelected: (String? item) {
        setState(() {
          selectedInlineStatus = item;
        });
      },
      itemBuilder: (BuildContext context) {
        return shipmentStatus!.map((String value) {
          return PopupMenuItem(
            value: value,
            height: MySize.size36!,
            child: Text(value,
                style: AppTheme.getTextStyle(themeData.textTheme.bodyText2,
                    color: themeData.colorScheme.onBackground)),
          );
        }).toList();
      },
      color: themeData.backgroundColor,
      child: Container(
        padding: EdgeInsets.only(
            left: MySize.size12!,
            right: MySize.size12!,
            top: MySize.size8!,
            bottom: MySize.size8!),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(MySize.size8!)),
          color: customAppTheme.bgLayer1,
          border: Border.all(color: customAppTheme.bgLayer3, width: 1),
        ),
        child: Row(
          children: <Widget>[
            Text(
              selectedInlineStatus!,
              style: AppTheme.getTextStyle(
                themeData.textTheme.bodyText1,
                color: themeData.colorScheme.onBackground,
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: MySize.size4!),
              child: Icon(
                MdiIcons.chevronDown,
                size: MySize.size22,
                color: themeData.colorScheme.onBackground,
              ),
            )
          ],
        ),
      ),
    );
  }

  //get customer name by contact_id
  Future<Map<String, dynamic>> getCustomerNameById(int id) async {
    var customer = await Contact().getCustomerDetailById(id);
    Map<String, dynamic> customerName = {
      'name': customer['name'],
      'mobile': customer['mobile']
    };
    return customerName;
  }

//date picker
  Widget shipmentDatePicker() {
    return TextButton(
      style: TextButton.styleFrom(
        shape: StadiumBorder(side: BorderSide(color: customAppTheme.bgLayer3)),
      ),
      onPressed: () => _selectDate(context),
      child: Text("${selectedDate.toLocal()}".split(' ')[0]),
    );
  }

// shipment block
  Widget block(int index, int id,
      {invoiceNo, date, customerName, deliverTo, contactNo, status}) {
    return Card(
      margin: EdgeInsets.all(MySize.size10!),
      elevation: 2,
      shadowColor: Colors.grey,
      child: Container(
        padding: EdgeInsets.all(MySize.size5!),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#$invoiceNo',
                      style: AppTheme.getTextStyle(
                        themeData.textTheme.subtitle1,
                        fontWeight: 600,
                        color: themeData.colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      MdiIcons.accountBoxOutline,
                      color: Colors.blueGrey.shade600,
                    ),
                    Text(
                      " $customerName",
                      style: AppTheme.getTextStyle(
                        themeData.textTheme.subtitle1,
                        fontWeight: 600,
                        color: themeData.colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      MdiIcons.calendarClock,
                      color: Colors.green.shade900,
                    ),
                    Text(
                      ' $date',
                      style: AppTheme.getTextStyle(
                        themeData.textTheme.subtitle1,
                        color: themeData.colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            launch("tel:$contactNo");
                            // CustomerApi().getLeads();
                            // var now = DateTime.now();int from = now.subtract(Duration(days: 1)).millisecondsSinceEpoch;int to = now.subtract(Duration(days: 0)).millisecondsSinceEpoch;

                            // Iterable<CallLogEntry> result = await CallLog.query(dateFrom: from, dateTo: to, number: '$contactNo');result.forEach((element) {print(element.formattedNumber);print(element.cachedMatchedNumber);print(element.number);print(element.name);print(element.callType);print(element.timestamp);print(element.duration);});
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.call_outlined,
                                color: Colors.lightBlue,
                              ),
                              Text(
                                ' $contactNo',
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.headline6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          child: Row(
                            children: [
                              Icon(
                                Icons.delivery_dining,
                                color: Colors.yellow.shade900,
                              ),
                              Text(
                                ' $deliverTo',
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.headline6,
                                  fontWeight: 700,
                                  color: themeData.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          visible: (deliverTo.toString().trim() != '' &&
                              deliverTo != null),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        selectedInlineStatus =
                            shipments[index]['shipping_status'];
                        deliveredToController.text =
                            shipments[index]['delivered_to'] ?? '';
                        shippingDialog(index,
                            details: shipments[index]['shipping_details'] ?? '',
                            address:
                                shipments[index]['shipping_address'] ?? '');
                      },
                      child: Container(
                          margin: EdgeInsets.only(top: MySize.size2!),
                          padding: EdgeInsets.all(MySize.size4!),
                          decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                    offset: Offset.zero,
                                    color: customAppTheme.bgLayer3)
                              ],
                              borderRadius: BorderRadius.all(
                                  Radius.circular(MySize.size20!)),
                              border:
                                  Border.all(color: customAppTheme.bgLayer3)),
                          child: Text(
                            status.toString().toUpperCase(),
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyText1,
                              color: themeData.colorScheme.onBackground,
                            ),
                          )),
                    )
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      MdiIcons.googleMaps,
                      color: Colors.red,
                    ),
                    Container(
                      margin: EdgeInsets.only(left: MySize.size2!),
                      width: MySize.screenWidth! * 0.8,
                      child: Text(
                        '${shipments[index]['shipping_address']}',
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyText1,
                          color: themeData.colorScheme.onBackground,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Container(alignment: Alignment.topRight, child: GestureDetector(child: Icon(Icons.directions, color: Colors.green, size: MySize.size40,), onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => Direction(shipments[index]['shipping_address'])));},),)
          ],
        ),
      ),
    );
  }

  //Retrieve shipment list from api
  //generate shipment list
  generateShipmentList() async {
    setState(() {
      /* isLoading = false;*/
    });
    final dio = new Dio();
    var token = await System().getToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["Authorization"] = "Bearer $token";
    if (nextPage != null) {
      await dio.get(nextPage!).then((value) {
        Map links = value.data['links'];
        nextPage = links['next'];
        List shipment = value.data['data'];
        shipment.forEach((element) async {
          Map<String, dynamic> customer =
              await getCustomerNameById(element['contact_id']);
          setState(() {
            shipments.add({
              'id': element['id'],
              'invoice_no': element['invoice_no'],
              'customerName': customer['name'],
              'transaction_date': element['transaction_date'],
              'shipping_status': element['shipping_status'],
              'shipping_details': element['shipping_details'],
              'shipping_address': element['shipping_address'],
              'delivered_to': element['delivered_to'],
              'contact_no': customer['mobile'],
            });
          });
        });
      });
    }
  }

  shippingDialog(int index, {String? details, String? address}) {
    showDialog(
        barrierDismissible: true,
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("${shipments[index]['invoice_no']}"),
            content: Container(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: Text(
                      "${AppLocalizations.of(context).translate('shipping_details')} : ",
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyText1,
                          fontWeight: 600),
                    ),
                    subtitle: Text(
                      '$details',
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyText1,
                          fontWeight: 500),
                    ),
                    isThreeLine: true,
                  ),
                  ListTile(
                    title: Text(
                      "${AppLocalizations.of(context).translate('shipping_address')} : ",
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyText1,
                          fontWeight: 600),
                    ),
                    subtitle: Text(
                      '$address',
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyText1,
                          fontWeight: 500),
                    ),
                    isThreeLine: true,
                  ),
                  inlineStatus(),
                  Padding(
                    padding: EdgeInsets.only(top: MySize.size8!),
                    child: TextFormField(
                      controller: deliveredToController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)
                            .translate('delivered_to'),
                      ),
                    ),
                  )
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  primary: Colors.blue,
                ),
                onPressed: () async {
                  var data = ShipmentModel().updateShipment(
                      id: shipments[index]['id'],
                      status: selectedInlineStatus,
                      deliveredTo: deliveredToController.text);
                  await ShipmentApi().updateShipmentStatus(data).then((value) {
                    selectedInlineStatus = null;
                    Navigator.pop(context);
                    if (this.mounted) {
                      setState(() {
                        shipments = [];
                        getShipments();
                      });
                    }
                  });
                },
                child: Text(AppLocalizations.of(context).translate('save')),
              ),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context).translate('cancel')))
            ],
          );
        });
  }
}
