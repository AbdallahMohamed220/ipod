import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:search_choices/search_choices.dart';

import '../apis/contact.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../helpers/style.dart' as style;
import '../locale/MyLocalizations.dart';
import '../models/contact_model.dart';
import '../models/sell.dart';
import '../models/sellDatabase.dart';
import 'elements.dart';
import 'login.dart';

class Customer extends StatefulWidget {
  @override
  _CustomerState createState() => _CustomerState();
}

class _CustomerState extends State<Customer> {
  Map? argument;
  final _formKey = GlobalKey<FormState>();

  String transactionDate =
      DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
  List<Map<String, dynamic>> customerListMap = [];
  Map<String, dynamic> selectedCustomer = {
    'id': 0,
    'name': 'select customer',
    'mobile': ' - '
  };
  TextEditingController prefix = new TextEditingController(),
      firstName = new TextEditingController(),
      middleName = new TextEditingController(),
      lastName = new TextEditingController(),
      mobile = new TextEditingController(),
      addressLine1 = new TextEditingController(),
      addressLine2 = new TextEditingController(),
      city = new TextEditingController(),
      state = new TextEditingController(),
      country = new TextEditingController(),
      zip = new TextEditingController();

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    selectCustomer();
  }

  @override
  void didChangeDependencies() {
    argument = ModalRoute.of(context)!.settings.arguments as Map?;

    if (argument!['customerId'] != null) {
      Future.delayed(Duration(milliseconds: 400), () async {
        await Contact()
            .getCustomerDetailById(argument!['customerId'])
            .then((value) {
          if (this.mounted) {
            setState(() {
              selectedCustomer = {
                'id': argument!['customerId'],
                'name': value['name'],
                'mobile': value['mobile']
              };
            });
          }
        });
      });
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(AppLocalizations.of(context).translate('customer'),
              style: AppTheme.getTextStyle(themeData.textTheme.headline6,
                  fontWeight: 600)),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(new MaterialPageRoute<Null>(
                builder: (BuildContext context) {
                  return newCustomer();
                },
                fullscreenDialog: true));
          },
          child: Icon(MdiIcons.accountPlus),
          elevation: 2,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                padding:
                    EdgeInsets.only(top: MySize.size120!, left: MySize.size20!),
                child: Card(child: customerList()),
              ),
              Center(
                child: Visibility(
                  visible: (selectedCustomer['id'] == 0),
                  child: Text(
                      AppLocalizations.of(context).translate(
                          'please_select_a_customer_for_checkout_option'),
                      style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Visibility(
          visible: (selectedCustomer['id'] != 0),
          child: Row(
            mainAxisAlignment: (argument!['is_quotation'] == null)
                ? MainAxisAlignment.spaceAround
                : MainAxisAlignment.center,
            children: [
              Visibility(
                visible: argument!['is_quotation'] == null,
                child: TextButton(
                  onPressed: (addQuotation),
                  style: TextButton.styleFrom(
                      primary: Colors.black,
                      backgroundColor: style.StyleColors().mainColor(1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40.0),
                      )),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      Text(
                        AppLocalizations.of(context).translate('add_quotation'),
                        style: AppTheme.getTextStyle(
                            Theme.of(context).textTheme.bodyText1,
                            color: Theme.of(context).colorScheme.surface),
                      ),
                    ],
                  ),
                ),
              ),
              cartBottomBar(
                  '/checkout',
                  AppLocalizations.of(context).translate('pay_&_checkout'),
                  context,
                  Helper().argument(
                      locId: argument!['locationId'],
                      taxId: argument!['taxId'],
                      discountType: argument!['discountType'],
                      discountAmount: argument!['discountAmount'],
                      invoiceAmount: argument!['invoiceAmount'],
                      customerId: selectedCustomer['id'],
                      sellId: argument!['sellId'])),
            ],
          ),
        ));
  }

  //add quotation
  addQuotation() async {
    Map sell = await Sell().createSell(
        changeReturn: 0.00,
        transactionDate: transactionDate,
        pending: argument!['invoiceAmount'],
        shippingCharges: 0.00,
        shippingDetails: '',
        invoiceNo: USERID.toString() +
            "_" +
            DateFormat('yMdHm').format(DateTime.now()),
        contactId: selectedCustomer['id'],
        discountAmount: argument!['discountAmount'],
        discountType: argument!['discountType'],
        invoiceAmount: argument!['invoiceAmount'],
        locId: argument!['locationId'],
        saleStatus: 'draft',
        sellId: argument!['sellId'],
        taxId: argument!['taxId'],
        isQuotation: 1);
    confirmDialog(sell);
  }

  //confirmation dialogBox
  confirmDialog(sell) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: customAppTheme.bgLayer1,
          title: Text(AppLocalizations.of(context).translate('quotation'),
              style: AppTheme.getTextStyle(themeData.textTheme.headline6,
                  color: themeData.colorScheme.onBackground, fontWeight: 700)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: themeData.colorScheme.primary,
              ),
              onPressed: () async {
                if (argument!['sellId'] != null) {
                  //update sell
                } else {
                  await SellDatabase().storeSell(sell).then((value) async {
                    SellDatabase()
                        .updateSellLine({'sell_id': value, 'is_completed': 1});
                    if (await Helper().checkConnectivity()) {
                      await Sell().createApiSell(sellId: value);
                    }
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/products', ModalRoute.withName('/home'));
                  });
                }
              },
              child: Text(AppLocalizations.of(context).translate('save')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: themeData.colorScheme.primary,
              ),
              onPressed: () async {
                await SellDatabase().storeSell(sell).then((value) async {
                  SellDatabase()
                      .updateSellLine({'sell_id': value, 'is_completed': 1});
                  if (await Helper().checkConnectivity()) {
                    await Sell().createApiSell(sellId: value);
                  }
                  Helper()
                      .printDocument(value, argument!['taxId'], context)
                      .then((value) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/products', ModalRoute.withName('/home'));
                    Fluttertoast.showToast(
                        msg: AppLocalizations.of(context)
                            .translate('quotation_added'));
                  });
                });
              },
              child:
                  Text(AppLocalizations.of(context).translate('save_n_print')),
            )
          ],
        );
      },
    );
  }

  //show add customer alert box
  Widget newCustomer() {
    return Scaffold(
      appBar: new AppBar(
        title: Text(AppLocalizations.of(context).translate('create_contact'),
            style: themeData.appBarTheme.textTheme!.headline6),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        padding: EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 64,
                          child: Center(
                            child: Icon(
                              MdiIcons.accountChildCircle,
                              color: themeData.colorScheme.onBackground,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            margin: EdgeInsets.only(left: 16),
                            child: Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Container(
                                      width: 50,
                                      child: TextFormField(
                                        controller: prefix,
                                        style: themeData.textTheme.subtitle2!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onBackground)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.subtitle2!
                                              .merge(TextStyle(
                                                  color: themeData.colorScheme
                                                      .onBackground)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('prefix'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    ),
                                    Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 4)),
                                    Expanded(
                                      child: TextFormField(
                                        controller: firstName,
                                        validator: (value) {
                                          if (value!.length < 1) {
                                            return AppLocalizations.of(context)
                                                .translate(
                                                    'please_enter_your_name');
                                          } else {
                                            return null;
                                          }
                                        },
                                        style: themeData.textTheme.subtitle2!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onBackground)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.subtitle2!
                                              .merge(TextStyle(
                                                  color: themeData.colorScheme
                                                      .onBackground)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('first_name'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Container(
                                      width: MySize.screenWidth! * 0.35,
                                      child: TextFormField(
                                        controller: middleName,
                                        style: themeData.textTheme.subtitle2!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onBackground)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.subtitle2!
                                              .merge(TextStyle(
                                                  color: themeData.colorScheme
                                                      .onBackground)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('middle_name'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    ),
                                    Container(
                                      width: MySize.screenWidth! * 0.35,
                                      child: TextFormField(
                                        controller: lastName,
                                        style: themeData.textTheme.subtitle2!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onBackground)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.subtitle2!
                                              .merge(TextStyle(
                                                  color: themeData.colorScheme
                                                      .onBackground)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('last_name'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: 64,
                            child: Center(
                              child: Icon(
                                MdiIcons.homeCityOutline,
                                color: themeData.colorScheme.onBackground,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: EdgeInsets.only(left: 16),
                              child: Column(
                                children: <Widget>[
                                  TextFormField(
                                    controller: addressLine1,
                                    style: themeData.textTheme.subtitle2!.merge(
                                        TextStyle(
                                            color: themeData
                                                .colorScheme.onBackground)),
                                    decoration: InputDecoration(
                                      hintStyle: themeData.textTheme.subtitle2!
                                          .merge(TextStyle(
                                              color: themeData
                                                  .colorScheme.onBackground)),
                                      hintText: AppLocalizations.of(context)
                                          .translate('address_line_1'),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .border!
                                                .borderSide
                                                .color),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .enabledBorder!
                                                .borderSide
                                                .color),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .focusedBorder!
                                                .borderSide
                                                .color),
                                      ),
                                    ),
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                  ),
                                  TextFormField(
                                    controller: addressLine2,
                                    style: themeData.textTheme.subtitle2!.merge(
                                        TextStyle(
                                            color: themeData
                                                .colorScheme.onBackground)),
                                    decoration: InputDecoration(
                                      hintStyle: themeData.textTheme.subtitle2!
                                          .merge(TextStyle(
                                              color: themeData
                                                  .colorScheme.onBackground)),
                                      hintText: AppLocalizations.of(context)
                                          .translate('address_line_2'),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .border!
                                                .borderSide
                                                .color),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .enabledBorder!
                                                .borderSide
                                                .color),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .focusedBorder!
                                                .borderSide
                                                .color),
                                      ),
                                    ),
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: 64,
                            child: Center(
                              child: Icon(
                                MdiIcons.phoneOutline,
                                color: themeData.colorScheme.onBackground,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: EdgeInsets.only(left: 16),
                              child: Column(
                                children: <Widget>[
                                  TextFormField(
                                    controller: mobile,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value!.length < 1) {
                                        return AppLocalizations.of(context)
                                            .translate(
                                                'please_enter_your_number');
                                      } else {
                                        return null;
                                      }
                                    },
                                    style: themeData.textTheme.subtitle2!.merge(
                                        TextStyle(
                                            color: themeData
                                                .colorScheme.onBackground)),
                                    decoration: InputDecoration(
                                      hintStyle: themeData.textTheme.subtitle2!
                                          .merge(TextStyle(
                                              color: themeData
                                                  .colorScheme.onBackground)),
                                      hintText: AppLocalizations.of(context)
                                          .translate('phone'),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .border!
                                                .borderSide
                                                .color),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .enabledBorder!
                                                .borderSide
                                                .color),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .focusedBorder!
                                                .borderSide
                                                .color),
                                      ),
                                    ),
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: 64,
                            child: Center(
                              child: Icon(
                                MdiIcons.homeCityOutline,
                                color: themeData.colorScheme.onBackground,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: EdgeInsets.only(left: 16),
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Container(
                                        width: MySize.screenWidth! * 0.35,
                                        child: TextFormField(
                                          controller: city,
                                          style: themeData.textTheme.subtitle2!
                                              .merge(TextStyle(
                                                  color: themeData.colorScheme
                                                      .onBackground)),
                                          decoration: InputDecoration(
                                            hintStyle: themeData
                                                .textTheme.subtitle2!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onBackground)),
                                            hintText:
                                                AppLocalizations.of(context)
                                                    .translate('city'),
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .border!
                                                      .borderSide
                                                      .color),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .enabledBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .focusedBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                          ),
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                        ),
                                      ),
                                      Container(
                                        width: MySize.screenWidth! * 0.35,
                                        child: TextFormField(
                                          controller: state,
                                          style: themeData.textTheme.subtitle2!
                                              .merge(TextStyle(
                                                  color: themeData.colorScheme
                                                      .onBackground)),
                                          decoration: InputDecoration(
                                            hintStyle: themeData
                                                .textTheme.subtitle2!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onBackground)),
                                            hintText:
                                                AppLocalizations.of(context)
                                                    .translate('state'),
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .border!
                                                      .borderSide
                                                      .color),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .enabledBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .focusedBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                          ),
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                        ),
                                      )
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Container(
                                        width: MySize.screenWidth! * 0.35,
                                        child: TextFormField(
                                          controller: country,
                                          style: themeData.textTheme.subtitle2!
                                              .merge(TextStyle(
                                                  color: themeData.colorScheme
                                                      .onBackground)),
                                          decoration: InputDecoration(
                                            hintStyle: themeData
                                                .textTheme.subtitle2!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onBackground)),
                                            hintText:
                                                AppLocalizations.of(context)
                                                    .translate('country'),
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .border!
                                                      .borderSide
                                                      .color),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .enabledBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .focusedBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                          ),
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                        ),
                                      ),
                                      Container(
                                        width: MySize.screenWidth! * 0.35,
                                        child: TextFormField(
                                          controller: zip,
                                          keyboardType: TextInputType.number,
                                          style: themeData.textTheme.subtitle2!
                                              .merge(TextStyle(
                                                  color: themeData.colorScheme
                                                      .onBackground)),
                                          decoration: InputDecoration(
                                            hintStyle: themeData
                                                .textTheme.subtitle2!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onBackground)),
                                            hintText:
                                                AppLocalizations.of(context)
                                                    .translate('zip_code'),
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .border!
                                                      .borderSide
                                                      .color),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .enabledBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .focusedBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                          ),
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 16),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 48),
                          backgroundColor: themeData.colorScheme.primary,
                        ),
                        onPressed: () async {
                          if (await Helper().checkConnectivity()) {
                            if (_formKey.currentState!.validate()) {
                              Map newCustomer = {
                                'type': 'customer',
                                'prefix': prefix.text,
                                'first_name': firstName.text,
                                'middle_name': middleName.text,
                                'last_name': lastName.text,
                                'mobile': mobile.text,
                                'address_line_1': addressLine1.text,
                                'address_line_2': addressLine2.text,
                                'city': city.text,
                                'state': state.text,
                                'country': country.text,
                                'zip_code': zip.text
                              };
                              await CustomerApi()
                                  .add(newCustomer)
                                  .then((value) {
                                if (value['data'] != null) {
                                  Contact()
                                      .insertContact(
                                          Contact().contactModel(value['data']))
                                      .then((value) {
                                    selectCustomer();
                                    selectedCustomer = customerListMap[0];
                                    Navigator.pop(context);
                                    _formKey.currentState!.reset();
                                  });
                                }
                              });
                            }
                          } else {
                            Fluttertoast.showToast(
                                msg: AppLocalizations.of(context)
                                    .translate('check_connectivity'));
                          }
                        },
                        child: Text(
                            AppLocalizations.of(context)
                                .translate('add_to_contact')
                                .toUpperCase(),
                            style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyText1,
                                color: themeData.colorScheme.onPrimary,
                                letterSpacing: 0.3)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  //dropdown widget for selecting customer
  Widget customerList() {
    return SearchChoices.single(
      underline: Visibility(
        child: Container(),
        visible: false,
      ),
      displayClearIcon: false,
      value: jsonEncode(selectedCustomer),
      items: customerListMap.map<DropdownMenuItem<String>>((Map value) {
        return DropdownMenuItem<String>(
            value: jsonEncode(value),
            child: Container(
              width: MySize.screenWidth! * 0.8,
              child: Text("${value['name']} (${value['mobile'] ?? ' - '})",
                  softWrap: true,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.getTextStyle(themeData.textTheme.bodyText2,
                      color: themeData.colorScheme.onBackground)),
            ));
      }).toList(),
      iconEnabledColor: Colors.blue,
      iconDisabledColor: Colors.black,
      onChanged: (newValue) {
        setState(() {
          selectedCustomer = jsonDecode(newValue);
        });
      },
      isExpanded: true,
    );
  }

  selectCustomer() async {
    customerListMap = [
      {'id': 0, 'name': 'select customer', 'mobile': ' - '}
    ];
    List customers = await Contact().get();

    customers.forEach((value) {
      setState(() {
        customerListMap.add({
          'id': value['id'],
          'name': value['name'],
          'mobile': value['mobile']
        });
      });
      if (value['name'] == 'Walk-In Customer') {
        selectedCustomer = {
          'id': value['id'],
          'name': value['name'],
          'mobile': value['mobile']
        };
      }
    });
  }
}
