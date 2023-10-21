import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../apis/expenses.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/expenses.dart';
import '../models/system.dart';

class Expense extends StatefulWidget {
  @override
  _ExpenseState createState() => _ExpenseState();
}

class _ExpenseState extends State<Expense> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> expenseCategories = [],
      expenseSubCategories = [],
      paymentMethods = [],
      paymentAccounts = [],
      locationListMap = [
        {'id': 0, 'name': 'set location'}
      ],
      taxListMap = [
        {'id': 0, 'name': 'Tax rate', 'amount': 0}
      ];
  Map<String, dynamic> selectedLocation = {'id': 0, 'name': 'set location'},
      selectedTax = {'id': 0, 'name': 'Tax rate', 'amount': 0},
      selectedExpenseCategoryId = {'id': 0, 'name': 'Select'},
      selectedExpenseSubCategoryId = {'id': 0, 'name': 'Select'};
  TextEditingController expenseAmount = new TextEditingController(),
      expenseNote = new TextEditingController(),
      payingAmount = new TextEditingController();

  Map<String, dynamic> selectedPaymentAccount = {'id': null, 'name': "None"},
      selectedPaymentMethod = {
        'name': 'name',
        'value': 'value',
        'account_id': null
      };
  String symbol = '';

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    setLocationMap();
    setTaxMap();
    setPaymentDetails(selectedLocation['id']);
    Helper().syncCallLogs();
  }

  @override
  void dispose() {
    expenseAmount.dispose();
    expenseNote.dispose();
    payingAmount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text(AppLocalizations.of(context).translate('expenses'),
            style: AppTheme.getTextStyle(themeData.textTheme.headline6,
                fontWeight: 600)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(MySize.size20!),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Text(
                        AppLocalizations.of(context).translate('location') +
                            ' : ',
                        style: AppTheme.getTextStyle(
                            themeData.textTheme.headline6,
                            fontWeight: 700,
                            letterSpacing: -0.2),
                      ),
                      locations(),
                    ],
                  ),
                  Column(
                    children: <Widget>[
                      Text(
                        AppLocalizations.of(context).translate('tax') + ' : ',
                        style: AppTheme.getTextStyle(
                            themeData.textTheme.headline6,
                            fontWeight: 700,
                            letterSpacing: -0.2),
                      ),
                      taxes(),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(MySize.size8!),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SizedBox(
                    width: MySize.screenWidth! * 0.4,
                    child: Text(
                      "${AppLocalizations.of(context).translate('expense_categories')} : ",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.headline6,
                          fontWeight: 700,
                          letterSpacing: -0.2),
                    ),
                  ),
                  SizedBox(
                      width: MySize.screenWidth! * 0.45,
                      child: expenseCategory()),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(MySize.size8!),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SizedBox(
                    width: MySize.screenWidth! * 0.4,
                    child: Text(
                      "${AppLocalizations.of(context).translate('sub_categories')} : ",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.headline6,
                          fontWeight: 700,
                          letterSpacing: -0.2),
                    ),
                  ),
                  SizedBox(
                      width: MySize.screenWidth! * 0.45,
                      child: expenseSubCategory()),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(MySize.size8!),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      validator: (value) {
                        if (value!.length < 1) {
                          return AppLocalizations.of(context)
                              .translate('please_enter_expense_amount');
                        } else {
                          return null;
                        }
                      },
                      decoration: InputDecoration(
                        prefix: Text(symbol),
                        labelText: AppLocalizations.of(context)
                            .translate('expense_amount'),
                        border: themeData.inputDecorationTheme.border,
                        enabledBorder: themeData.inputDecorationTheme.border,
                        focusedBorder:
                            themeData.inputDecorationTheme.focusedBorder,
                      ),
                      controller: expenseAmount,
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.subtitle2,
                          fontWeight: 400,
                          letterSpacing: -0.2),
                      textAlign: TextAlign.end,
                      inputFormatters: [
                        FilteringTextInputFormatter(
                            RegExp(r'^(\d+)?\.?\d{0,2}'),
                            allow: true)
                      ],
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(MySize.size8!),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)
                            .translate('expense_note'),
                        border: themeData.inputDecorationTheme.border,
                        enabledBorder: themeData.inputDecorationTheme.border,
                        focusedBorder:
                            themeData.inputDecorationTheme.focusedBorder,
                      ),
                      controller: expenseNote,
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.subtitle2,
                          fontWeight: 400,
                          letterSpacing: -0.2),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(MySize.size8!),
              ),
              payment(),
              Padding(
                padding: EdgeInsets.all(MySize.size8!),
              ),
              paymentAccount(),
              Padding(
                padding: EdgeInsets.all(MySize.size8!),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: themeData.colorScheme.primary,
                ),
                onPressed: () async {
                  if (await Helper().checkConnectivity()) {
                    if (_formKey.currentState!.validate()) {
                      onSubmit();
                    }
                  } else {
                    Fluttertoast.showToast(
                        msg: AppLocalizations.of(context)
                            .translate('check_connectivity'));
                  }
                },
                child: Text(
                  AppLocalizations.of(context).translate('submit'),
                  style: AppTheme.getTextStyle(themeData.textTheme.headline6,
                      color: themeData.colorScheme.onPrimary,
                      fontWeight: 700,
                      letterSpacing: -0.2),
                ),
              )
            ],
          ),
        ),
      ),
    );
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

  onSubmit() async {
    if (selectedLocation['id'] != 0) {
      if (expenseAmount.text == '') {
        expenseAmount.text = '0.00';
      }
      if (payingAmount.text == '') {
        payingAmount.text = '0.00';
      }
      var expenseMap = ExpenseManagement().createExpense(
          locId: selectedLocation['id'],
          finalTotal: double.parse(expenseAmount.text),
          amount: double.parse(payingAmount.text),
          method: selectedPaymentMethod['name'],
          accountId: selectedPaymentAccount['id'],
          expenseCategoryId: selectedExpenseCategoryId['id'],
          expenseSubCategoryId: selectedExpenseSubCategoryId['id'],
          taxId: (selectedTax['id'] != 0) ? selectedTax['id'] : null,
          note: expenseNote.text);
      await ExpenseApi().create(expenseMap).then((value) {
        Navigator.pop(context);
        Fluttertoast.showToast(
            msg: AppLocalizations.of(context)
                .translate('expense_added_successfully'));
      });
    } else {
      Fluttertoast.showToast(
          msg:
              AppLocalizations.of(context).translate('error_invalid_location'));
    }
  }

  Widget locations() {
    return PopupMenuButton(
        onSelected: (Map<String, dynamic> item) {
          setState(() {
            selectedLocation = item;
            setExpenseCategories();
            setPaymentDetails(selectedLocation['id']).then((value) {
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
          return locationListMap.map((Map<String, dynamic> value) {
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

  setTaxMap() {
    System().get('tax').then((value) {
      value.forEach((element) {
        taxListMap.add({
          'id': element['id'],
          'name': element['name'],
          'amount': element['amount']
        });
      });
    });
  }

  //dropdown tax widget
  Widget taxes() {
    return PopupMenuButton(
      onSelected: (Map<String, dynamic> item) {
        setState(() {
          selectedTax = item;
        });
      },
      itemBuilder: (BuildContext context) {
        return taxListMap.map((Map<String, dynamic> value) {
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
              selectedTax['name'],
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

  //dropdown tax widget
  Widget expenseCategory() {
    return PopupMenuButton(
      onSelected: (Map<String, dynamic> item) {
        setState(() {
          selectedExpenseCategoryId = item;
          selectedExpenseSubCategoryId = {'id': 0, 'name': 'Select'};
          if (item.containsKey('sub_categories') &&
              item['sub_categories'].length > 0) {
            item['sub_categories'].forEach((element) {
              expenseSubCategories
                  .add({'id': element['id'], 'name': element['name']});
            });
          } else {
            expenseSubCategories = [];
          }
        });
      },
      itemBuilder: (BuildContext context) {
        return expenseCategories.map((Map<String, dynamic> value) {
          return PopupMenuItem(
            value: value,
            height: MySize.size36!,
            child: Text(value['name'],
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            SizedBox(
              width: MySize.screenWidth! * 0.3,
              child: Text(
                selectedExpenseCategoryId['name'],
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                textAlign: TextAlign.end,
                style: AppTheme.getTextStyle(
                  themeData.textTheme.bodyText1,
                  color: themeData.colorScheme.onBackground,
                ),
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

  //dropdown tax widget
  Widget expenseSubCategory() {
    return PopupMenuButton(
      onSelected: (Map<String, dynamic> item) {
        setState(() {
          selectedExpenseSubCategoryId = item;
        });
      },
      itemBuilder: (BuildContext context) {
        return expenseSubCategories.map((Map<String, dynamic> value) {
          return PopupMenuItem(
            value: value,
            height: MySize.size36!,
            child: Text(value['name'],
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            SizedBox(
              width: MySize.screenWidth! * 0.3,
              child: Text(
                selectedExpenseSubCategoryId['name'],
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: AppTheme.getTextStyle(
                  themeData.textTheme.bodyText1,
                  color: themeData.colorScheme.onBackground,
                ),
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

  setExpenseCategories() async {
    await ExpenseApi().get().then((value) {
      value.forEach((element) {
        setState(() {
          expenseCategories.add({
            'id': element['id'],
            'name': element['name'],
            'sub_categories': element['sub_categories']
          });
        });
      });
    });
  }

  setPaymentDetails(int locId) async {
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

  //payment widget
  Widget payment() {
    return Column(
      children: <Widget>[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <
            Widget>[
          Expanded(
            child: TextFormField(
                validator: (value) {
                  if (value == '') value = '0.00';
                  if (expenseAmount.text == '' ||
                      double.parse(value!) > double.parse(expenseAmount.text)) {
                    return AppLocalizations.of(context)
                        .translate('enter_valid_payment_amount');
                  } else {
                    return null;
                  }
                },
                decoration: InputDecoration(
                  prefix: Text(symbol),
                  labelText:
                      AppLocalizations.of(context).translate('payment_amount'),
                  border: themeData.inputDecorationTheme.border,
                  enabledBorder: themeData.inputDecorationTheme.border,
                  focusedBorder: themeData.inputDecorationTheme.focusedBorder,
                ),
                controller: payingAmount,
                textAlign: TextAlign.end,
                style: AppTheme.getTextStyle(themeData.textTheme.subtitle2,
                    fontWeight: 400, letterSpacing: -0.2),
                inputFormatters: [
                  FilteringTextInputFormatter(RegExp(r'^(\d+)?\.?\d{0,2}'),
                      allow: true)
                ],
                keyboardType: TextInputType.number,
                onChanged: (value) {}),
          ),
        ]),
        Padding(
          padding: EdgeInsets.all(MySize.size8!),
        ),
        Row(children: <Widget>[
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
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyText2,
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
        ])
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
