import 'dart:convert';

import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:search_choices/search_choices.dart';

import '../apis/field_force.dart';
import '../config.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/contact_model.dart';

class NewVisitForm extends StatefulWidget {
  const NewVisitForm({Key? key}) : super(key: key);

  @override
  _NewVisitFormState createState() => _NewVisitFormState();
}

class _NewVisitFormState extends State<NewVisitForm> {
  late bool isLoading = false;
  bool fromContact = false;
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> customerListMap = [];
  Map<String, dynamic> selectedCustomer = {
    'id': 0,
    'name': 'select customer',
    'mobile': ' - '
  };
  var visitOn = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  TextEditingController nameController = new TextEditingController(),
      addressController = new TextEditingController(),
      visitForController = new TextEditingController();

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    setCustomerList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).translate('add_visit'),
          style: AppTheme.getTextStyle(
            themeData.textTheme.subtitle1,
            fontWeight: 600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: (isLoading)
            ? Helper().loadingIndicator(context)
            : Container(
                height: MediaQuery.of(context).size.height,
                padding:
                    EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: [
                          Text(
                            "${AppLocalizations.of(context).translate('Whom_you_will_be_visiting')}*",
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.headline6,
                              fontWeight: 600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Radio(
                            value: true,
                            groupValue: fromContact,
                            onChanged: (bool? value) {
                              setState(() {
                                fromContact = value!;
                              });
                            },
                            toggleable: true,
                          ),
                          Padding(
                            padding: EdgeInsets.all(MySize.size6!),
                            child: Text(
                              AppLocalizations.of(context)
                                  .translate('contacts'),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(MySize.size14!),
                          ),
                          Radio(
                            value: false,
                            groupValue: fromContact,
                            onChanged: (bool? value) {
                              setState(() {
                                fromContact = value!;
                              });
                            },
                            toggleable: true,
                          ),
                          Padding(
                            padding: EdgeInsets.all(MySize.size6!),
                            child: Text(
                              AppLocalizations.of(context).translate('others'),
                            ),
                          )
                        ],
                      ),
                      Visibility(
                        visible: (fromContact == false),
                        child: Column(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${AppLocalizations.of(context).translate('person_or_company')} : ",
                                  style: AppTheme.getTextStyle(
                                    themeData.textTheme.subtitle1,
                                    fontWeight: 600,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: MySize.size4!,
                                      bottom: MySize.size10!),
                                  child: TextFormField(
                                    controller: nameController,
                                    validator: (value) {
                                      if (nameController.text.trim() == "") {
                                        return "${AppLocalizations.of(context).translate('pLease_provide_person_or_company_name')}";
                                      } else {
                                        return null;
                                      }
                                    },
                                    decoration: InputDecoration(
                                      border:
                                          themeData.inputDecorationTheme.border,
                                      enabledBorder:
                                          themeData.inputDecorationTheme.border,
                                      focusedBorder: themeData
                                          .inputDecorationTheme.focusedBorder,
                                    ),
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    style: AppTheme.getTextStyle(
                                      themeData.textTheme.bodyText1,
                                      fontWeight: 500,
                                      color: themeData.colorScheme.onBackground,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${AppLocalizations.of(context).translate('visit_address')} : ",
                                  style: AppTheme.getTextStyle(
                                    themeData.textTheme.subtitle1,
                                    fontWeight: 600,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: MySize.size4!,
                                      bottom: MySize.size10!),
                                  child: TextFormField(
                                    controller: addressController,
                                    validator: (value) {
                                      if (addressController.text.trim() == "") {
                                        return "${AppLocalizations.of(context).translate('please_enter_visit_address')}";
                                      } else {
                                        return null;
                                      }
                                    },
                                    minLines: 2,
                                    maxLines: 6,
                                    decoration: InputDecoration(
                                      border:
                                          themeData.inputDecorationTheme.border,
                                      enabledBorder:
                                          themeData.inputDecorationTheme.border,
                                      focusedBorder: themeData
                                          .inputDecorationTheme.focusedBorder,
                                    ),
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    style: AppTheme.getTextStyle(
                                      themeData.textTheme.bodyText1,
                                      fontWeight: 500,
                                      color: themeData.colorScheme.onBackground,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: (fromContact == true),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${AppLocalizations.of(context).translate('contacts')} : ",
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.subtitle1,
                                fontWeight: 600,
                              ),
                            ),
                            customerList()
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${AppLocalizations.of(context).translate('visit_on')} : ",
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.subtitle1,
                              fontWeight: 600,
                            ),
                          ),
                          Card(
                            margin: EdgeInsets.all(MySize.size5!),
                            child: DateTimePicker(
                              use24HourFormat: false,
                              locale: Locale('en', 'US'),
                              initialValue: visitOn,
                              type: DateTimePickerType.dateTime,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 366)),
                              dateMask: 'yyyy-MM-dd  hh:mm',
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyText1,
                                fontWeight: 700,
                                color: themeData.colorScheme.primary,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  visitOn = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${AppLocalizations.of(context).translate('purpose_of_visiting')} : ",
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.subtitle1,
                              fontWeight: 600,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                top: MySize.size4!, bottom: MySize.size10!),
                            child: TextFormField(
                              controller: visitForController,
                              minLines: 2,
                              maxLines: 6,
                              decoration: InputDecoration(
                                border: themeData.inputDecorationTheme.border,
                                enabledBorder:
                                    themeData.inputDecorationTheme.border,
                                focusedBorder: themeData
                                    .inputDecorationTheme.focusedBorder,
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyText1,
                                fontWeight: 500,
                                color: themeData.colorScheme.onBackground,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 16),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 48),
                            backgroundColor: themeData.colorScheme.primary,
                          ),
                          onPressed: () async {
                            bool validated = true;
                            if (fromContact && selectedCustomer['id'] == 0) {
                              validated = false;
                              Fluttertoast.showToast(
                                  msg: AppLocalizations.of(context)
                                      .translate('please_set_contact'));
                            }

                            if (await Helper().checkConnectivity()) {
                              if (_formKey.currentState!.validate() &&
                                  validated) {
                                setState(() {
                                  isLoading = true;
                                });
                                Map visitDetails = {
                                  if (fromContact == true)
                                    'contact_id': selectedCustomer['id'],
                                  if (fromContact == false)
                                    'visit_to': nameController.text,
                                  if (fromContact == false)
                                    'visit_address': addressController.text,
                                  'assigned_to': Config.userId,
                                  'visit_on': DateFormat('yyyy-MM-dd HH:mm:ss')
                                      .format(DateTime.now()),
                                  'visit_for': visitForController.text
                                };
                                FieldForceApi()
                                    .create(visitDetails)
                                    .then((value) {
                                  if (value != null) {
                                    Fluttertoast.showToast(
                                        msg: AppLocalizations.of(context)
                                            .translate('status_updated'));
                                  }
                                  Navigator.pop(context);
                                });
                              }
                            }
                          },
                          child: Text(
                              AppLocalizations.of(context).translate('save'),
                              style: AppTheme.getTextStyle(
                                  themeData.textTheme.bodyText1,
                                  color: themeData.colorScheme.onPrimary,
                                  letterSpacing: 0.3)),
                        ),
                      ),
                    ],
                  ),
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
      // value: customerListMap[0],
      iconEnabledColor: Colors.blue,
      iconDisabledColor: Colors.black,
      onChanged: (value) async {
        setState(() {
          selectedCustomer = jsonDecode(value);
        });
      },
      isExpanded: true,
    );
  }

  //set customer list
  setCustomerList() async {
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
}
