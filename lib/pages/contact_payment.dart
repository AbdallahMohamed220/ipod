import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:search_choices/search_choices.dart';

import '../apis/contact_payment.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/contact_model.dart';
import '../models/system.dart';

class ContactPayment extends StatefulWidget {
  @override
  _ContactPaymentState createState() => _ContactPaymentState();
}

class _ContactPaymentState extends State<ContactPayment> {
  final _formKey = GlobalKey<FormState>();
  int selectedCustomerId = 0;
  List<Map<String, dynamic>> customerListMap = [],
      paymentAccounts = [],
      paymentMethods = [],
      locationListMap = [
        {'id': 0, 'name': 'set location'}
      ];
  Map<String, dynamic> selectedLocation = {'id': 0, 'name': 'set location'},
      selectedCustomer = {'id': 0, 'name': 'select customer', 'mobile': ' - '};
  String due = '0.00';
  Map<String, dynamic> selectedPaymentAccount = {'id': null, 'name': "None"},
      selectedPaymentMethod = {
        'name': 'name',
        'value': 'value',
        'account_id': null
      };

  String symbol = '';
  var payingAmount = new TextEditingController();

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    selectCustomer();
    setPaymentDetails();
    setLocationMap();
    Helper().syncCallLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text(AppLocalizations.of(context).translate('contact_payment'),
            style: AppTheme.getTextStyle(themeData.textTheme.headline6,
                fontWeight: 600)),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(MySize.size10!),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customerList(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate('due')
                              .toUpperCase(),
                          style: AppTheme.getTextStyle(
                              themeData.textTheme.subtitle1,
                              fontWeight: 600,
                              letterSpacing: -0.2),
                        ),
                        // Padding(padding: EdgeInsets.symmetric(vertical: MySize.size4)),
                        Text(
                          Helper().formatCurrency(due),
                          style: AppTheme.getTextStyle(
                              themeData.textTheme.headline5,
                              fontWeight: 600,
                              letterSpacing: -0.2),
                        ),
                      ],
                    )
                  ],
                ),
                Padding(padding: EdgeInsets.symmetric(vertical: MySize.size4!)),
                Visibility(
                  visible: (selectedCustomerId != 0),
                  child: Column(
                    children: [
                      TextFormField(
                          decoration: InputDecoration(
                            prefix: Text(symbol),
                            labelText: AppLocalizations.of(context)
                                .translate('payment_amount'),
                            border: themeData.inputDecorationTheme.border,
                            enabledBorder:
                                themeData.inputDecorationTheme.border,
                            focusedBorder:
                                themeData.inputDecorationTheme.focusedBorder,
                          ),
                          controller: payingAmount,
                          validator: (newValue) {
                            if ((newValue == '' ||
                                    double.parse(newValue!) < 0.01) ||
                                double.parse(newValue) >
                                    double.parse(due.toString())) {
                              return AppLocalizations.of(context)
                                  .translate('enter_valid_payment_amount');
                            } else {
                              return null;
                            }
                          },
                          textAlign: TextAlign.end,
                          style: AppTheme.getTextStyle(
                              themeData.textTheme.subtitle2,
                              fontWeight: 400,
                              letterSpacing: -0.2),
                          inputFormatters: [
                            // ignore: deprecated_member_use
                            FilteringTextInputFormatter(
                                RegExp(r'^(\d+)?\.?\d{0,2}'),
                                allow: true)
                          ],
                          keyboardType: TextInputType.number,
                          onChanged: (value) {}),
                      Padding(
                        padding: EdgeInsets.all(MySize.size10!),
                        child: Row(
                          children: <Widget>[
                            Text(
                              AppLocalizations.of(context)
                                      .translate('location') +
                                  ' : ',
                              style: AppTheme.getTextStyle(
                                  themeData.textTheme.headline6,
                                  fontWeight: 700,
                                  letterSpacing: -0.2),
                            ),
                            locations(),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(MySize.size10!),
                        child: paymentOptions(),
                      ),
                      Padding(
                        padding: EdgeInsets.all(MySize.size10!),
                        child: paymentAccount(),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: themeData.colorScheme.primary,
                      ),
                      onPressed: () async {
                        await onSubmit();
                      },
                      child: Text(
                        AppLocalizations.of(context).translate('submit'),
                        style: AppTheme.getTextStyle(
                            themeData.textTheme.headline6,
                            color: themeData.colorScheme.onPrimary,
                            fontWeight: 700,
                            letterSpacing: -0.2),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  onSubmit() async {
    if (await Helper().checkConnectivity()) {
      if (_formKey.currentState!.validate()) {
        if (selectedLocation['id'] != 0) {
          Map<String, dynamic> paymentMap = {
            "contact_id": selectedCustomerId,
            "amount": double.parse(payingAmount.text),
            "method": selectedPaymentMethod['name'],
            "account_id": selectedPaymentMethod['account_id'],
            "paid_on": DateFormat("yyyy-MM-dd hh:mm:ss")
                .format(DateTime.now())
                .toString(),
          };
          await ContactPaymentApi()
              .postContactPayment(paymentMap)
              .then((value) {
            Navigator.popUntil(context, ModalRoute.withName('/home'));
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)
                    .translate('payment_successful'));
          });
        } else {
          Fluttertoast.showToast(
              msg: AppLocalizations.of(context)
                  .translate('error_invalid_location'));
        }
      }
    } else {
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context).translate('check_connectivity'));
    }
  }

  //dropdown widget for selecting customer
  Widget customerList() {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context).translate('select_customer') + ' : ',
          style: AppTheme.getTextStyle(themeData.textTheme.headline6,
              fontWeight: 700, letterSpacing: -0.2),
        ),
        SearchChoices.single(
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
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyText2,
                          color: themeData.colorScheme.onBackground)),
                ));
          }).toList(),
          // value: customerListMap[0],
          iconEnabledColor: Colors.blue,
          iconDisabledColor: Colors.black,
          onChanged: (value) async {
            setState(() {
              selectedCustomer = jsonDecode(value);
            });
            var newValue = selectedCustomer['id'];
            if (newValue != 0) {
              if (await Helper().checkConnectivity()) {
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          Container(
                              margin: EdgeInsets.only(left: 5),
                              child: Text(AppLocalizations.of(context)
                                  .translate('loading'))),
                        ],
                      ),
                    );
                  },
                );
                await ContactPaymentApi()
                    .getCustomerDue(newValue)
                    .then((value) {
                  if (value != null) {
                    due = value['data'][0]['sell_due'].toString();
                    setState(() {
                      selectedCustomerId = newValue;
                      _formKey.currentState!.reset();
                    });
                  }
                  Navigator.pop(context);
                });
              } else {
                Fluttertoast.showToast(
                    msg: AppLocalizations.of(context)
                        .translate('check_connectivity'));
              }
            }
          },
          isExpanded: true,
        )
      ],
    );
  }

  Widget locations() {
    return PopupMenuButton(
        onSelected: (item) {
          setState(() {
            selectedLocation = item as Map<String, dynamic>;
            setPaymentDetails().then((value) {
              selectedPaymentMethod = paymentMethods[0];
              selectedPaymentAccount = paymentAccounts[0];
              paymentAccounts.forEach((element) {
                if (selectedPaymentMethod['account_id'] == element['id']) {
                  selectedPaymentAccount = element;
                }
              });
            });
          });
        },
        itemBuilder: (BuildContext context) {
          return locationListMap.map((Map value) {
            return PopupMenuItem(
              value: value,
              height: MySize.size36!,
              child: Text(value['name'],
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
                selectedLocation['name'],
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

  selectCustomer() async {
    customerListMap = [
      {'id': 0, 'name': 'select customer', 'mobile': ' - '}
    ];
    await Contact().get().then((value) {
      value.forEach((Map<String, dynamic> element) {
        setState(() {
          customerListMap.add({
            'id': element['id'],
            'name': element['name'],
            'mobile': element['mobile']
          });
        });
      });
    });
  }

  setLocationMap() async {
    locationListMap = [];
    await System().get('location').then((value) {
      value.forEach((element) {
        setState(() {
          locationListMap.add({
            'id': element['id'],
            'name': element['name'],
          });
        });
      });
    });
  }

  setPaymentDetails() async {
    await Helper().getFormattedBusinessDetails().then((value) {
      setState(() {
        symbol = value['symbol'];
      });
    });
    List payments =
        await System().get('payment_method', selectedLocation['id']);
    paymentAccounts = [
      {'id': null, 'name': "None"}
    ];
    await System().getPaymentAccounts().then((value) {
      List<String> accIds = [];
      value.forEach((element) {
        payments.forEach((payment) {
          if ((payment['account_id'].toString() == element['id'].toString()) &&
              !accIds.contains(element['id'].toString())) {
            accIds.add(element['id'].toString());
            paymentAccounts.add({'id': element['id'], 'name': element['name']});
          }
        });
      });
    });
    paymentMethods = [];
    payments.forEach((element) {
      setState(() {
        paymentMethods.add({
          'name': element['name'],
          'value': element['label'],
          'account_id': (element['account_id'] != null)
              ? int.parse(element['account_id'].toString())
              : null
        });
      });
    });
  }

  //contact payment widget
  Widget paymentOptions() {
    return Row(
      children: <Widget>[
        Text(
          AppLocalizations.of(context).translate('payment_method') + ' : ',
          style: AppTheme.getTextStyle(themeData.textTheme.headline6,
              fontWeight: 700, letterSpacing: -0.2),
        ),
        PopupMenuButton(
          onSelected: (item) {
            setState(() {
              selectedPaymentMethod = item as Map<String, dynamic>;
              selectedPaymentAccount = paymentAccounts[0];
              paymentAccounts.forEach((element) {
                if (selectedPaymentMethod['account_id'] == element['id']) {
                  selectedPaymentAccount = element;
                }
              });
            });
          },
          itemBuilder: (BuildContext context) {
            return paymentMethods.map((Map value) {
              return PopupMenuItem(
                value: value,
                height: MySize.size36!,
                child: Text(value['value'],
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
                  selectedPaymentMethod['value'],
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
        ),
      ],
    );
  }

  //payment account widget
  Widget paymentAccount() {
    return Row(
      children: <Widget>[
        Text(
          AppLocalizations.of(context).translate('payment_account') + ' : ',
          style: AppTheme.getTextStyle(themeData.textTheme.headline6,
              fontWeight: 700, letterSpacing: -0.2),
        ),
        PopupMenuButton(
          onSelected: (item) {
            Map<String, dynamic> selectedItem = item as Map<String, dynamic>;
            setState(() {
              selectedPaymentAccount = item;
              selectedPaymentMethod['account_id'] = selectedItem['id'];
            });
          },
          itemBuilder: (BuildContext context) {
            return paymentAccounts.map((Map value) {
              return PopupMenuItem(
                value: value,
                height: MySize.size36!,
                child: Text(value['name'],
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
                  selectedPaymentAccount['name'],
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
        ),
      ],
    );
  }
}
