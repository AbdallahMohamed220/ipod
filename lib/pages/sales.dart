import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:search_choices/search_choices.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../apis/api.dart';
import '../apis/sell.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/contact_model.dart';
import '../models/paymentDatabase.dart';
import '../models/sell.dart';
import '../models/sellDatabase.dart';
import '../models/system.dart';
import '../pages/login.dart';
import 'elements.dart';

class Sales extends StatefulWidget {
  @override
  _SalesState createState() => _SalesState();
}

class _SalesState extends State<Sales> {
  List sellList = [];
  List<String> paymentStatuses = ['all'], invoiceStatuses = ['final', 'draft'];
  ScrollController _scrollController = new ScrollController();
  bool isLoading = false,
      synced = true,
      canViewSell = false,
      canEditSell = false,
      canDeleteSell = false,
      showFilter = false,
      changeUrl = false;
  Map<dynamic, dynamic> selectedLocation = {'id': 0, 'name': 'All'},
      selectedCustomer = {'id': 0, 'name': 'All', 'mobile': ''};
  String selectedPaymentStatus = '';
  String? startDateRange, endDateRange; // selectedInvoiceStatus = 'all';
  List<Map<dynamic, dynamic>> allSalesListMap = [],
      customerListMap = [
        {'id': 0, 'name': 'All', 'mobile': ''}
      ],
      locationListMap = [
        {'id': 0, 'name': 'All'}
      ];
  String symbol = '';
  String? nextPage = '', url = Api().apiUrl + "sell?order_by_date=desc";
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    setCustomers();
    setLocations();
    if ((synced)) refreshSales();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        setAllSalesList();
      }
    });
    Helper().syncCallLogs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  setCustomers() async {
    customerListMap.addAll(await Contact().get());
    setState(() {});
  }

  setLocations() async {
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
    await System().refreshPermissionList().then((value) async {
      await getPermission().then((value) {
        changeUrl = true;
        onFilter();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(AppLocalizations.of(context).translate('sales'),
              style: AppTheme.getTextStyle(themeData.textTheme.headline6,
                  fontWeight: 600)),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                if (await Helper().checkConnectivity()) {
                  showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(),
                            Container(
                                margin: EdgeInsets.only(left: 5),
                                child: Text(AppLocalizations.of(context)
                                    .translate('sync_in_progress'))),
                          ],
                        ),
                      );
                    },
                  );
                  await Sell().createApiSell(syncAll: true).then((value) {
                    Navigator.pop(context);
                    setState(() {
                      synced = true;
                      sells();
                    });
                  });
                } else
                  Fluttertoast.showToast(
                      msg: AppLocalizations.of(context)
                          .translate('check_connectivity'));
              },
              child: Text(
                AppLocalizations.of(context).translate('sync'),
                style: AppTheme.getTextStyle(themeData.textTheme.subtitle1,
                    fontWeight: (synced) ? 500 : 900, letterSpacing: -0.2),
              ),
            ),
          ],
          bottom: TabBar(tabs: [
            Tab(
                icon: Icon(Icons.line_weight),
                child: Text(
                    AppLocalizations.of(context).translate('recent_sales'))),
            Tab(
              icon: Icon(Icons.line_style),
              child: Text(AppLocalizations.of(context).translate('all_sales')),
            )
          ]),
        ),
        body: TabBarView(children: [currentSales(), allSales()]),
        bottomNavigationBar: posBottomBar('sale', context),
      ),
    );
  }

  //Fetch permission from database
  getPermission() async {
    var activeSubscriptionDetails = await System().get('active-subscription');
    if (activeSubscriptionDetails.length > 0) {
      if (await Helper().getPermission("sell.update")) {
        canEditSell = true;
      }
      if (await Helper().getPermission("sell.delete")) {
        canDeleteSell = true;
      }
    }
    if (await Helper().getPermission("view_paid_sells_only")) {
      paymentStatuses.add('paid');
      selectedPaymentStatus = 'paid';
    }
    if (await Helper().getPermission("view_due_sells_only")) {
      paymentStatuses.add('due');
      selectedPaymentStatus = 'due';
    }
    if (await Helper().getPermission("view_partial_sells_only")) {
      paymentStatuses.add('partial');
      selectedPaymentStatus = 'partial';
    }
    if (await Helper().getPermission("view_overdue_sells_only")) {
      paymentStatuses.add('overdue');
      selectedPaymentStatus = 'overdue';
    }
    //await Helper().getPermission("sell.view")
    if (await Helper().getPermission("direct_sell.view")) {
      url = Api().apiUrl + "sell?order_by_date=desc";
      if (paymentStatuses.length < 2) {
        paymentStatuses.addAll(['paid', 'due', 'partial', 'overdue']);
        selectedPaymentStatus = 'all';
      }
      setState(() {
        canViewSell = true;
      });
    } else if (await Helper().getPermission("view_own_sell_only")) {
      url = Api().apiUrl + "sell?order_by_date=desc&user_id=$USERID";
      if (paymentStatuses.length < 2) {
        paymentStatuses.addAll(['paid', 'due', 'partial', 'overdue']);
        selectedPaymentStatus = 'all';
      }
      setState(() {
        canViewSell = true;
      });
    }
  }

  refreshSales() async {
    if (await Helper().checkConnectivity()) {
      showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                Container(
                  margin: EdgeInsets.only(left: 5),
                  child:
                      Text(AppLocalizations.of(context).translate('loading')),
                ),
              ],
            ),
          );
        },
      );
      //update sells from api
      // await updateSellsFromApi().then((value) {
      sells();
      Navigator.pop(context);
      // });
    } else {
      sells();
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context).translate('check_connectivity'));
    }
  }

  //fetch current sales from database
  sells() async {
    sellList = [];
    await SellDatabase().getSells(all: true).then((value) {
      value.forEach((element) async {
        if (element['is_synced'] == 0) synced = false;
        var customerDetail =
            await Contact().getCustomerDetailById(element['contact_id']);
        var locationName =
            await Helper().getLocationNameById(element['location_id']);
        setState(() {
          sellList.add({
            'id': element['id'],
            'transaction_date': element['transaction_date'],
            'invoice_no': element['invoice_no'],
            'customer_name': customerDetail['name'],
            'mobile': customerDetail['mobile'],
            'contact_id': element['contact_id'],
            'location_id': element['location_id'],
            'location_name': locationName,
            'status': element['status'],
            'tax_rate_id': element['tax_rate_id'],
            'discount_amount': element['discount_amount'],
            'discount_type': element['discount_type'],
            'sale_note': element['sale_note'],
            'staff_note': element['staff_note'],
            'invoice_amount': element['invoice_amount'],
            'pending_amount': element['pending_amount'],
            'is_synced': element['is_synced'],
            'is_quotation': element['is_quotation'],
            'invoice_url': element['invoice_url'],
            'transaction_id': element['transaction_id']
          });
        });
      });
    });
    await Helper().getFormattedBusinessDetails().then((value) {
      symbol = value['symbol'];
    });
  }

  //refresh sales list
  updateSellsFromApi() async {
    //get synced sells transactionId
    List transactionIds = await SellDatabase().getTransactionIds();

    if (transactionIds.isNotEmpty) {
      //fetch specified sells by transactionId from api
      List specificSales = await SellApi().getSpecifiedSells(transactionIds);

      specificSales.forEach((element) async {
        //fetch sell from database with respective transactionId
        List sell = await SellDatabase().getSellByTransactionId(element['id']);

        if (sell.length > 0) {
          //Updating latest data in sell_payments
          //delete payment lines with reference to its sellId
          await PaymentDatabase().delete(sell[0]['id']);
          element['payment_lines'].forEach((value) async {
            //store payment lines from response
            await PaymentDatabase().store({
              'sell_id': sell[0]['id'],
              'method': value['method'],
              'amount': value['amount'],
              'note': value['note'],
              'payment_id': value['id'],
              'is_return': value['is_return'],
              'account_id': value['account_id']
            });
          });

          //Updating latest data in sell_lines
          //delete sell_lines with reference to its sellId
          await SellDatabase().deleteSellLineBySellId(sell[0]['id']);

          element['sell_lines'].forEach((value) async {
            //   //store sell lines from response
            await SellDatabase().store({
              'sell_id': sell[0]['id'],
              'product_id': value['product_id'],
              'variation_id': value['variation_id'],
              'quantity': value['quantity'],
              'unit_price': value['unit_price_before_discount'],
              'tax_rate_id': value['tax_id'],
              'discount_amount': value['line_discount_amount'],
              'discount_type': value['line_discount_type'],
              'note': value['sell_line_note'],
              'is_completed': 1
            });
          });
          //update latest sells details
          updateSells(element);
        }
      });
    }
  }

  //update sells
  updateSells(sells) async {
    var changeReturn = 0.0;
    var pendingAmount = 0.0;
    var totalAmount = 0.0;
    List sell = await SellDatabase().getSellByTransactionId(sells['id']);
    await PaymentDatabase().get(sell[0]['id'], allColumns: true).then((value) {
      value.forEach((element) {
        if (element['is_return'] == 1) {
          changeReturn += element['amount'];
        } else {
          totalAmount += element['amount'];
        }
      });
    });
    if (double.parse(sells['final_total']) > totalAmount) {
      pendingAmount = double.parse(sells['final_total']) - totalAmount;
    }
    Map<String, dynamic> sellMap =
        Sell().createSellMap(sells, changeReturn, pendingAmount);
    await SellDatabase().updateSells(sell[0]['id'], sellMap);
  }

  onFilter() {
    nextPage = url;
    if (selectedLocation['id'] != 0) {
      nextPage = nextPage! + "&location_id=${selectedLocation['id']}";
    }
    if (selectedCustomer['id'] != 0) {
      nextPage = nextPage! + "&contact_id=${selectedCustomer['id']}";
    }
    if (selectedPaymentStatus != 'all') {
      nextPage = nextPage! + "&payment_status=$selectedPaymentStatus";
    } else if (selectedPaymentStatus == 'all') {
      List<String> status = List.from(paymentStatuses);
      status.remove('all');
      String statuses = status.join(',');
      nextPage = nextPage! + "&payment_status=$statuses";
    }
    if (startDateRange != null && endDateRange != null) {
      nextPage =
          nextPage! + "&start_date=$startDateRange&end_date=$endDateRange";
    }
    changeUrl = true;
    setAllSalesList();
  }

  //Retrieve sales list from api
  void setAllSalesList() async {
    setState(() {
      if (changeUrl) {
        allSalesListMap = [];
        changeUrl = false;
        showFilter = false;
      }
      isLoading = false;
    });
    final dio = new Dio();
    var token = await System().getToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["Authorization"] = "Bearer $token";
    final response = await dio.get(nextPage!);
    List sales = response.data['data'];
    Map links = response.data['links'];
    nextPage = links['next'];
    sales.forEach((sell) async {
      var paidAmount;
      List payments = sell['payment_lines'];
      double totalPaid = 0.00;
      Map<String, dynamic>? customer =
          //sell['contact'];
          await Contact().getCustomerDetailById(sell['contact_id']);
      var location = await Helper().getLocationNameById(sell['location_id']);
      payments.forEach((element) {
        totalPaid += double.parse(element['amount']);
      });
      (totalPaid <= double.parse(sell['final_total']))
          ? paidAmount = Helper().formatCurrency(totalPaid)
          : paidAmount = Helper().formatCurrency(sell['final_total']);
      allSalesListMap.add({
        'id': sell['id'],
        'location_name': location,
        'contact_name': (customer != null)
            ? ("${(customer['name'] != null) ? customer['name'] : ''} "
                "${(customer['supplier_business_name'] != null) ? customer['supplier_business_name'] : ''}")
            : null,
        'mobile': (customer != null) ? customer['mobile'] : null,
        'invoice_no': sell['invoice_no'],
        'invoice_url': sell['invoice_url'],
        'date_time': sell['transaction_date'],
        'invoice_amount': sell['final_total'],
        'status': sell['payment_status'] ?? sell['status'],
        'paid_amount': paidAmount,
        'is_quotation': sell['is_quotation'].toString()
      });
      if (this.mounted) {
        setState(() {
          isLoading = true;
        });
      }
    });
  }

//progress indicator
  Widget _buildProgressIndicator() {
    return new Padding(
      padding: const EdgeInsets.all(8.0),
      child: new Center(
        child: FutureBuilder<bool>(
            future: Helper().checkConnectivity(),
            builder: (context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.data == false) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)
                          .translate('check_connectivity'),
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.subtitle1,
                          fontWeight: 700,
                          letterSpacing: -0.2),
                    ),
                    Icon(
                      Icons.error_outline,
                      color: themeData.colorScheme.onBackground,
                    )
                  ],
                );
              } else {
                return CircularProgressIndicator();
              }
            }),
      ),
    );
  }

//widget for listing sales from database
  Widget currentSales() {
    return (sellList.length > 0)
        ? ListView.builder(
        padding: EdgeInsets.all(10),
            controller: _scrollController,
            shrinkWrap: true,
            itemCount: sellList.length,
            itemBuilder: (context, index) {
              return recentSellItem(
                  price: Helper()
                      .formatCurrency(sellList[index]['invoice_amount']),
                  number: sellList[index]['invoice_no'],
                  status: checkStatus(sellList[index]['invoice_amount'],
                      sellList[index]['pending_amount']),
                  time: sellList[index]['transaction_date'],
                  paid: Helper().formatCurrency(sellList[index]
                          ['invoice_amount'] -
                      sellList[index]['pending_amount']),
                  isSynced: sellList[index]['is_synced'],
                  customerName: sellList[index]['customer_name'],
                  locationName: sellList[index]['location_name'],
                  isQuotation: sellList[index]['is_quotation'],
                  index: index);
            })
        : Helper().noDataWidget(context);
  }

//widget for listing sales from api
  Widget allSales() {
    return (canViewSell)
        ? Column(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    showFilter = !showFilter;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(MySize.size12!),
                  margin: EdgeInsets.all(MySize.size12!),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.all(Radius.circular(MySize.size8!)),
                    color: customAppTheme.bgLayer1,
                    border:
                        Border.all(color: customAppTheme.bgLayer4, width: 1.2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            (showFilter)
                                ? MdiIcons.chevronUp
                                : MdiIcons.chevronDown,
                            color: themeData.colorScheme.primary,
                          ),
                          Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)
                                    .translate('filter'),
                                style: AppTheme.getTextStyle(
                                    themeData.textTheme.headline6,
                                    color: themeData.colorScheme.primary,
                                    fontWeight: 700),
                              ),
                              Icon(
                                MdiIcons.filter,
                                color: themeData.colorScheme.primary,
                              )
                            ],
                          ),
                        ],
                      ),
                      (showFilter)
                          ? Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "${AppLocalizations.of(context).translate('location')} : ",
                                      style: AppTheme.getTextStyle(
                                          themeData.textTheme.bodyText1,
                                          fontWeight: 600),
                                    ),
                                    locations()
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "${AppLocalizations.of(context).translate('customer')} : ",
                                      style: AppTheme.getTextStyle(
                                          themeData.textTheme.bodyText1,
                                          fontWeight: 600),
                                    ),
                                    Expanded(child: customers())
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context)
                                        .push(new MaterialPageRoute<Null>(
                                            builder: (BuildContext context) {
                                              return dateRangePicker();
                                            },
                                            fullscreenDialog: true));
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(MySize.size8!),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(MySize.size8!)),
                                      color: customAppTheme.bgLayer1,
                                      border: Border.all(
                                          color: customAppTheme.bgLayer4,
                                          width: 2),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                            (startDateRange != null &&
                                                    endDateRange != null)
                                                ? "$startDateRange   -   $endDateRange"
                                                : "Date range",
                                            style: AppTheme.getTextStyle(
                                                themeData.textTheme.bodyText1,
                                                fontWeight: 600)),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: MySize.size6!),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "${AppLocalizations.of(context).translate('payment_status')} : ",
                                      style: AppTheme.getTextStyle(
                                          themeData.textTheme.bodyText1,
                                          fontWeight: 600),
                                    ),
                                    (paymentStatuses.length > 0)
                                        ? paymentStatus()
                                        : Container()
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: MySize.size6!),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                MySize.size20!),
                                            side: BorderSide(
                                                color: themeData
                                                    .colorScheme.primary)),
                                        onPrimary:
                                            themeData.colorScheme.primary,
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)
                                            .translate('reset'),
                                        style: AppTheme.getTextStyle(
                                            themeData.textTheme.button,
                                            color:
                                                themeData.colorScheme.onPrimary,
                                            fontWeight: 600),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          selectedLocation = locationListMap[0];
                                          selectedCustomer = customerListMap[0];
                                          startDateRange = null;
                                          endDateRange = null;
                                          selectedPaymentStatus =
                                              paymentStatuses[0];
                                        });
                                        onFilter();
                                      },
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                MySize.size20!),
                                            side: BorderSide(
                                                color: themeData
                                                    .colorScheme.primary)),
                                        onPrimary:
                                            themeData.colorScheme.primary,
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)
                                            .translate('ok'),
                                        style: AppTheme.getTextStyle(
                                            themeData.textTheme.button,
                                            color:
                                                themeData.colorScheme.onPrimary,
                                            fontWeight: 600),
                                      ),
                                      onPressed: () {
                                        onFilter();
                                      },
                                    ),
                                  ],
                                )
                                // Padding(padding: EdgeInsets.symmetric(vertical: MySize.size6),), Row(children: [Text("${AppLocalizations.of(context).translate('invoice_status')} : ", style: AppTheme.getTextStyle(themeData.textTheme.bodyText1, fontWeight: 600),), invoiceStatus()],),
                              ],
                            )
                          : Container()
                    ],
                  ),
                ),
              ),
              Expanded(
                child: (allSalesListMap.length > 0)
                    ? ListView.builder(
                        padding: EdgeInsets.all(10),
                        shrinkWrap: true,
                        controller: _scrollController,
                        itemCount: allSalesListMap.length + 1,
                        itemBuilder: (context, index) {
                          if (index == allSalesListMap.length) {
                            return (isLoading)
                                ? _buildProgressIndicator()
                                : Container();
                          } else {
                            return allSellItem(
                                index: index,
                                price: allSalesListMap[index]['invoice_amount'],
                                number: allSalesListMap[index]['invoice_no'],
                                time: allSalesListMap[index]['date_time'],
                                status: allSalesListMap[index]['status'],
                                paid: allSalesListMap[index]['paid_amount'],
                                customerName: allSalesListMap[index]
                                    ['contact_name'],
                                locationName: allSalesListMap[index]
                                    ['location_name'],
                                isQuotation: int.parse(allSalesListMap[index]
                                        ['is_quotation']
                                    .toString()));
                          }
                        })
                    : Helper().noDataWidget(context),
              )
            ],
          )
        : Center(
            child: Text(
              AppLocalizations.of(context).translate('unauthorised'),
              style: TextStyle(color: Colors.black),
            ),
          );
  }

  Widget dateRangePicker() {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('select_range')),
        elevation: 0,
      ),
      body: Column(
        children: [
          SfDateRangePicker(
            view: DateRangePickerView.year,
            selectionMode: DateRangePickerSelectionMode.range,
            onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
              if (args.value.startDate != null) {
                setState(() {
                  startDateRange = DateFormat('yyyy-MM-dd')
                      .format(args.value.startDate)
                      .toString();
                });
              }
              if (args.value.endDate != null) {
                setState(() {
                  endDateRange = DateFormat('yyyy-MM-dd')
                      .format(args.value.endDate)
                      .toString();
                });
              }
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: MySize.size30!),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MySize.size20!),
                      side: BorderSide(color: themeData.colorScheme.primary)),
                  onPrimary: themeData.colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    startDateRange = null;
                    endDateRange = null;
                  });
                  Navigator.pop(context);
                },
                child: Text(
                  AppLocalizations.of(context).translate('reset'),
                  style: AppTheme.getTextStyle(themeData.textTheme.headline6,
                      color: themeData.colorScheme.onPrimary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MySize.size20!),
                      side: BorderSide(color: themeData.colorScheme.primary)),
                  onPrimary: themeData.colorScheme.primary,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  AppLocalizations.of(context).translate('ok'),
                  style: AppTheme.getTextStyle(themeData.textTheme.headline6,
                      color: themeData.colorScheme.onPrimary),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  //recent sales listing widget
  Widget recentSellItem(
      {number,
      time,
      status,
      price,
      paid,
      isSynced,
      customerName,
      locationName,
      isQuotation,
      index}) {
    //Logic for row items
    double space = MySize.size12!;
    return Container(
      padding: EdgeInsets.only(top: space, right: space, left: space),
      margin: EdgeInsets.only(top: MySize.size0!, bottom: space),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(MySize.size8!)),
        color: customAppTheme.bgLayer1,
        border: Border.all(color: customAppTheme.bgLayer4, width: 1.2),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                time,
                style: AppTheme.getTextStyle(themeData.textTheme.bodyText2,
                    fontWeight: 600,
                    letterSpacing: -0.2,
                    color: themeData.colorScheme.onBackground.withAlpha(160)),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        (isQuotation == 0)
                            ? AppLocalizations.of(context)
                                    .translate('invoice_no') +
                                " $number"
                            : AppLocalizations.of(context).translate('ref_no') +
                                " $number",
                        style: AppTheme.getTextStyle(
                            themeData.textTheme.subtitle1,
                            fontWeight: 700,
                            letterSpacing: -0.2),
                      ),
                      Text(
                        AppLocalizations.of(context)
                                .translate('invoice_amount') +
                            " $symbol $price",
                        style: AppTheme.getTextStyle(
                            themeData.textTheme.bodyText2,
                            fontWeight: 600,
                            letterSpacing: 0),
                      ),
                      (isQuotation == 0)
                          ? Text(
                              AppLocalizations.of(context)
                                      .translate('paid_amount') +
                                  " $symbol $paid",
                              style: AppTheme.getTextStyle(
                                  themeData.textTheme.bodyText2,
                                  fontWeight: 600,
                                  letterSpacing: 0),
                            )
                          : SizedBox(),
                      Text(
                        AppLocalizations.of(context)
                                .translate('customer_name') +
                            ": $customerName",
                        style: AppTheme.getTextStyle(
                            themeData.textTheme.bodyText2,
                            fontWeight: 600,
                            letterSpacing: 0),
                      ),
                      Text(
                        AppLocalizations.of(context)
                                .translate('location_name') +
                            ": $locationName",
                        style: AppTheme.getTextStyle(
                            themeData.textTheme.bodyText2,
                            fontWeight: 600,
                            letterSpacing: 0),
                      ),
                    ],
                  ),
                ],
              ),
              Visibility(
                visible: index != null,
                child: Row(
                  children: [
                    (canEditSell)
                        ? IconButton(
                            icon: Icon(
                              MdiIcons.fileDocumentEditOutline,
                              color: themeData.colorScheme.onBackground,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/cart',
                                  arguments: Helper().argument(
                                      locId: sellList[index]['location_id'],
                                      sellId: sellList[index]['id'],
                                      isQuotation: sellList[index]
                                          ['is_quotation']));
                            })
                        : Container(),
                    (canDeleteSell)
                        ? IconButton(
                            icon: Icon(
                              MdiIcons.deleteOutline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Icon(
                                      MdiIcons.alert,
                                      color: Colors.red,
                                      size: MySize.size50,
                                    ),
                                    content: Text(
                                        AppLocalizations.of(context)
                                            .translate('are_you_sure'),
                                        textAlign: TextAlign.center,
                                        style: AppTheme.getTextStyle(
                                            themeData.textTheme.bodyText1,
                                            color: themeData
                                                .colorScheme.onBackground,
                                            fontWeight: 600,
                                            muted: true)),
                                    actions: <Widget>[
                                      TextButton(
                                          style: TextButton.styleFrom(
                                              backgroundColor: themeData
                                                  .colorScheme.onPrimary,
                                              primary: themeData
                                                  .colorScheme.primary),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                              AppLocalizations.of(context)
                                                  .translate('cancel'))),
                                      TextButton(
                                          style: TextButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              primary: themeData
                                                  .colorScheme.onError),
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            await SellDatabase().deleteSell(
                                                sellList[index]['id']);
                                            await SellApi().delete(
                                                sellList[index]
                                                    ['transaction_id']);
                                            sells();
                                          },
                                          child: Text(
                                              AppLocalizations.of(context)
                                                  .translate('ok')))
                                    ],
                                  );
                                },
                              );
                            })
                        : Container(),
                    IconButton(
                        icon: Icon(
                          MdiIcons.printerWireless,
                          color: Colors.deepPurple,
                        ),
                        onPressed: () async {
                          if (await Helper().checkConnectivity() &&
                              sellList[index]['invoice_url'] != null) {
                            final response = await http.Client()
                                .get(Uri.parse(sellList[index]['invoice_url']));
                            if (response.statusCode == 200) {
                              await Helper().printDocument(
                                  sellList[index]['id'],
                                  sellList[index]['tax_rate_id'],
                                  context,
                                  invoice: response.body);
                            } else {
                              await Helper().printDocument(
                                  sellList[index]['id'],
                                  sellList[index]['tax_rate_id'],
                                  context);
                            }
                          } else {
                            await Helper().printDocument(sellList[index]['id'],
                                sellList[index]['tax_rate_id'], context);
                          }
                        }),
                    IconButton(
                        icon: Icon(
                          MdiIcons.shareVariant,
                          color: themeData.colorScheme.primary,
                        ),
                        onPressed: () async {
                          if (await Helper().checkConnectivity() &&
                              sellList[index]['invoice_url'] != null) {
                            final response = await http.Client()
                                .get(Uri.parse(sellList[index]['invoice_url']));
                            if (response.statusCode == 200) {
                              await Helper().savePdf(
                                  sellList[index]['id'],
                                  sellList[index]['tax_rate_id'],
                                  context,
                                  sellList[index]['invoice_no'],
                                  invoice: response.body);
                            } else {
                              await Helper().savePdf(
                                  sellList[index]['id'],
                                  sellList[index]['tax_rate_id'],
                                  context,
                                  sellList[index]['invoice_no']);
                            }
                          } else {
                            await Helper().savePdf(
                                sellList[index]['id'],
                                sellList[index]['tax_rate_id'],
                                context,
                                sellList[index]['invoice_no']);
                          }
                        }),
                    ((sellList[index]['pending_amount'] > 0) && canEditSell)
                        ? IconButton(
                            icon: Icon(
                              MdiIcons.creditCardOutline,
                              color: Colors.purpleAccent,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/checkout',
                                  arguments: Helper().argument(
                                      invoiceAmount: sellList[index]
                                          ['invoice_amount'],
                                      customerId: sellList[index]['contact_id'],
                                      locId: sellList[index]['location_id'],
                                      discountAmount: sellList[index]
                                          ['discount_amount'],
                                      discountType: sellList[index]
                                          ['discount_type'],
                                      isQuotation: sellList[index]
                                          ['is_quotation'],
                                      taxId: sellList[index]['tax_rate_id'],
                                      sellId: sellList[index]['id']));
                            })
                        : Container(),
                    (((sellList[index]['pending_amount'] > 0) && canEditSell) &&
                            (sellList[index]['mobile'] != null))
                        ? IconButton(
                            icon: Icon(
                              Icons.call_outlined,
                              color: Colors.green,
                            ),
                            onPressed: () async {
                              // call
                              await launch('tel:${sellList[index]['mobile']}');
                            })
                        : Container()
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(MySize.size5!),
                    decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.all(Radius.circular(MySize.size4!)),
                        color: (isQuotation == 0)
                            ? checkStatusColor(status)
                            : Colors.yellowAccent),
                    child: Text(
                      (isQuotation == 0) ? status.toUpperCase() : 'QUOTATION',
                      style: AppTheme.getTextStyle(themeData.textTheme.caption,
                          fontSize: 14, fontWeight: 700, letterSpacing: 0.2),
                    ),
                  ),
                  Visibility(
                    visible: index != null,
                    child: Padding(
                      padding: EdgeInsets.all(MySize.size8!),
                      child: (isSynced == 0)
                          ? Icon(
                              MdiIcons.syncAlert,
                              color: Colors.black,
                            )
                          : Container(),
                    ),
                  )
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  //all sales listing widget
  Widget allSellItem(
      {number,
      time,
      status,
      price,
      paid,
      isSynced,
      customerName,
      locationName,
      isQuotation,
      index}) {
    //Logic for row items
    double space = MySize.size12!;
    return Container(
      padding: EdgeInsets.only(left: space, right: space, top: space),
      margin: EdgeInsets.only(top: MySize.size0!, bottom: space),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(MySize.size8!)),
        color: customAppTheme.bgLayer1,
        border: Border.all(color: customAppTheme.bgLayer4, width: 1.2),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(time,
                  style: AppTheme.getTextStyle(themeData.textTheme.bodyText2,
                      fontWeight: 600,
                      letterSpacing: -0.2,
                      color:
                          themeData.colorScheme.onBackground.withAlpha(160))),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        (isQuotation == 0)
                            ? AppLocalizations.of(context)
                                    .translate('invoice_no') +
                                " $number"
                            : AppLocalizations.of(context).translate('ref_no') +
                                " $number",
                        style: AppTheme.getTextStyle(
                            themeData.textTheme.subtitle1,
                            fontWeight: 700,
                            letterSpacing: -0.2),
                      ),
                      Text(
                        AppLocalizations.of(context)
                                .translate('invoice_amount') +
                            " $symbol $price",
                        style: AppTheme.getTextStyle(
                            themeData.textTheme.bodyText2,
                            fontWeight: 600,
                            letterSpacing: 0),
                      ),
                      (isQuotation == 0)
                          ? Text(
                              AppLocalizations.of(context)
                                      .translate('paid_amount') +
                                  " $symbol $paid",
                              style: AppTheme.getTextStyle(
                                  themeData.textTheme.bodyText2,
                                  fontWeight: 600,
                                  letterSpacing: 0),
                            )
                          : SizedBox(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${AppLocalizations.of(context).translate('customer_name')}: ",
                            style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyText2,
                                fontWeight: 600,
                                letterSpacing: 0),
                          ),
                          SizedBox(
                            width: MySize.screenWidth! * 0.6,
                            child: Text(
                              "$customerName",
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.getTextStyle(
                                  themeData.textTheme.bodyText2,
                                  fontWeight: 600,
                                  letterSpacing: 0),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        AppLocalizations.of(context)
                                .translate('location_name') +
                            ": $locationName",
                        maxLines: 3,
                        style: AppTheme.getTextStyle(
                            themeData.textTheme.bodyText2,
                            fontWeight: 600,
                            letterSpacing: 0),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Visibility(
                    visible: index != null,
                    child: Row(
                      children: [
                        // (canEditSell) ? IconButton(icon: Icon(MdiIcons.fileDocumentEditOutline, color: themeData.colorScheme.onBackground,), onPressed: () {Navigator.pushNamed(context, '/cart', arguments: Helper().argument(locId: sellList[index]['location_id'], sellId: sellList[index]['id'], isQuotation: sellList[index]['is_quotation']));}) : Container(),
                        (canDeleteSell)
                            ? IconButton(
                                icon: Icon(
                                  MdiIcons.deleteOutline,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  showDialog(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Icon(
                                          MdiIcons.alert,
                                          color: Colors.red,
                                          size: MySize.size50,
                                        ),
                                        content: Text(
                                            AppLocalizations.of(context)
                                                .translate('are_you_sure'),
                                            textAlign: TextAlign.center,
                                            style: AppTheme.getTextStyle(
                                                themeData.textTheme.bodyText1,
                                                color: themeData
                                                    .colorScheme.onBackground,
                                                fontWeight: 600,
                                                muted: true)),
                                        actions: <Widget>[
                                          TextButton(
                                              style: TextButton.styleFrom(
                                                  backgroundColor: themeData
                                                      .colorScheme.onPrimary,
                                                  primary: themeData
                                                      .colorScheme.primary),
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                  AppLocalizations.of(context)
                                                      .translate('cancel'))),
                                          TextButton(
                                              style: TextButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  primary: themeData
                                                      .colorScheme.onError),
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                await SellApi()
                                                    .delete(
                                                        allSalesListMap[index]
                                                            ['id'])
                                                    .then((value) {
                                                  if (value != null) {
                                                    setState(() {
                                                      allSalesListMap
                                                          .removeAt(index);
                                                    });
                                                    Fluttertoast.showToast(
                                                        msg: '${value['msg']}');
                                                  }
                                                });
                                              },
                                              child: Text(
                                                  AppLocalizations.of(context)
                                                      .translate('ok')))
                                        ],
                                      );
                                    },
                                  );
                                })
                            : Container(),
                        Visibility(
                          visible:
                              allSalesListMap[index]['invoice_url'] != null,
                          child: IconButton(
                              icon: Icon(
                                MdiIcons.printerWireless,
                                color: Colors.deepPurple,
                              ),
                              onPressed: () async {
                                if (await Helper().checkConnectivity()) {
                                  final response = await http.Client().get(
                                      Uri.parse(allSalesListMap[index]
                                          ['invoice_url']));
                                  if (response.statusCode == 200) {
                                    await Helper().printDocument(0, 0, context,
                                        invoice: response.body);
                                  } else {
                                    Fluttertoast.showToast(
                                        msg: AppLocalizations.of(context)
                                            .translate('something_went_wrong'));
                                  }
                                } else {
                                  Fluttertoast.showToast(
                                      msg: AppLocalizations.of(context)
                                          .translate('check_connectivity'));
                                }
                              }),
                        ),
                        Visibility(
                          visible:
                              allSalesListMap[index]['invoice_url'] != null,
                          child: IconButton(
                              icon: Icon(
                                MdiIcons.shareVariant,
                                color: themeData.colorScheme.primary,
                              ),
                              onPressed: () async {
                                if (await Helper().checkConnectivity()) {
                                  // print(allSalesListMap[index]
                                  // ['invoice_url']);
                                  final response = await http.Client().get(
                                      Uri.parse(allSalesListMap[index]
                                          ['invoice_url']));
                                  // print(response.body);
                                  if (response.statusCode == 200) {
                                    await Helper().savePdf(0, 0, context,
                                        allSalesListMap[index]['invoice_no'],
                                        invoice: response.body);
                                  } else {
                                    Fluttertoast.showToast(
                                        msg: AppLocalizations.of(context)
                                            .translate('something_went_wrong'));
                                  }
                                } else {
                                  Fluttertoast.showToast(
                                      msg: AppLocalizations.of(context)
                                          .translate('check_connectivity'));
                                }
                              }),
                        ),
                        Visibility(
                          visible: (allSalesListMap[index]['mobile'] != null &&
                              allSalesListMap[index]['status']
                                      .toString()
                                      .toLowerCase() !=
                                  'paid'),
                          child: IconButton(
                              icon: Icon(
                                Icons.call_outlined,
                                color: Colors.green,
                              ),
                              onPressed: () async {
                                await launch(
                                    'tel:${allSalesListMap[index]['mobile']}');
                              }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.only(
                    left: MySize.size12!,
                    right: MySize.size12!,
                    top: MySize.size8!,
                    bottom: MySize.size8!),
                decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.all(Radius.circular(MySize.size4!)),
                    color: (isQuotation == 0)
                        ? checkStatusColor(status)
                        : Colors.yellowAccent),
                child: Text(
                  (isQuotation == 0) ? status.toUpperCase() : 'QUOTATION',
                  style: AppTheme.getTextStyle(themeData.textTheme.caption,
                      fontSize: 12, fontWeight: 700, letterSpacing: 0.2),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget customers() {
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
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.getTextStyle(themeData.textTheme.bodyText2,
                      color: themeData.colorScheme.onBackground)),
            ));
      }).toList(),
      onChanged: (value) async {
        setState(() {
          selectedCustomer = jsonDecode(value);
        });
      },
      isExpanded: true,
    );
  }

  Widget locations() {
    return PopupMenuButton(
        onSelected: (Map<dynamic, dynamic> item) {
          setState(() {
            selectedLocation = item;
          });
        },
        itemBuilder: (BuildContext context) {
          return locationListMap.map((Map value) {
            return PopupMenuItem(
              value: value,
              child: Text(value['name'],
                  style: AppTheme.getTextStyle(themeData.textTheme.bodyText2,
                      color: themeData.colorScheme.onBackground)),
            );
          }).toList();
        },
        color: themeData.backgroundColor,
        child: Container(
          padding: EdgeInsets.all(MySize.size8!),
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

  Widget paymentStatus() {
    return PopupMenuButton(
      onSelected: (String item) {
        setState(() {
          selectedPaymentStatus = item;
        });
      },
      itemBuilder: (BuildContext context) {
        return paymentStatuses.map((String value) {
          return PopupMenuItem(
            value: value,
            child: Text(
                AppLocalizations.of(context).translate(value).toUpperCase(),
                style: AppTheme.getTextStyle(themeData.textTheme.bodyText2,
                    color: themeData.colorScheme.onBackground)),
          );
        }).toList();
      },
      color: themeData.backgroundColor,
      child: Container(
        padding: EdgeInsets.all(MySize.size8!),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(MySize.size8!)),
          color: customAppTheme.bgLayer1,
          border: Border.all(color: customAppTheme.bgLayer3, width: 1),
        ),
        child: Row(
          children: <Widget>[
            Text(
              AppLocalizations.of(context)
                  .translate(selectedPaymentStatus)
                  .toUpperCase(),
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

  Widget invoiceStatus() {
    return PopupMenuButton(
      onSelected: (item) {
        setState(() {
          // selectedInvoiceStatus = item;
        });
      },
      itemBuilder: (BuildContext context) {
        return invoiceStatuses.map((String value) {
          return PopupMenuItem(
            value: value,
            child: Text(
                AppLocalizations.of(context).translate(value).toUpperCase(),
                style: AppTheme.getTextStyle(themeData.textTheme.bodyText2,
                    color: themeData.colorScheme.onBackground)),
          );
        }).toList();
      },
      color: themeData.backgroundColor,
      child: Container(
        padding: EdgeInsets.all(MySize.size8!),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(MySize.size8!)),
          color: customAppTheme.bgLayer1,
          border: Border.all(color: customAppTheme.bgLayer3, width: 1),
        ),
        child: Row(
          children: <Widget>[
            Text(
              '',
              // AppLocalizations.of(context)
              //     .translate(selectedInvoiceStatus)
              //     .toUpperCase(),
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

  //status color
  Color checkStatusColor(String? status) {
    if (status != null) {
      if (status.toLowerCase() == 'paid')
        return Colors.green;
      else if (status.toLowerCase() == 'due')
        return Colors.red;
      else
        return Colors.orange;
    } else {
      return Colors.black12;
    }
  }

  //status status of recent sales
  String checkStatus(double invoiceAmount, double pendingAmount) {
    if (pendingAmount == invoiceAmount)
      return 'due';
    else if (pendingAmount >= 0.01)
      return 'partial';
    else
      return 'paid';
  }
}
