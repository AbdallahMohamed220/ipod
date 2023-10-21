import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../apis/api.dart';
import '../apis/contact.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/contact_model.dart';
import '../models/system.dart';
import '../pages/forms.dart';

class Contacts extends StatefulWidget {
  @override
  _ContactsState createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isLoading = false,
      useOrderBy = false,
      orderByAsc = true,
      useSearchBy = false;
  int currentTabIndex = 0;

  List<Map> leadsList = [], customerList = [], suppliersList = [];

  ScrollController leadsListController = ScrollController(),
      customerListController = ScrollController(),
      suppliersListController = ScrollController();

  var searchController = new TextEditingController();
  String? fetchLeads = Api().apiUrl + "crm/leads?per_page=10",
      fetchCustomers = Api().apiUrl + "contactapi?type=customer&per_page=10",
      fetchSuppliers = Api().apiUrl + "contactapi?type=supplier&per_page=10";
  String orderByColumn = 'name', orderByDirection = 'asc';

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
    setAllList();
    leadsListController.addListener(() {
      if (leadsListController.position.pixels ==
          leadsListController.position.maxScrollExtent) {
        setLeadsList();
      }
    });
    customerListController.addListener(() {
      if (customerListController.position.pixels ==
          customerListController.position.maxScrollExtent) {
        setCustomersList();
      }
    });
    suppliersListController.addListener(() {
      if (suppliersListController.position.pixels ==
          suppliersListController.position.maxScrollExtent) {
        setSuppliersList();
      }
    });
    Helper().syncCallLogs();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: _filterDrawer(),
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
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: Icon(MdiIcons.filterVariant),
              onPressed: () {
                _scaffoldKey.currentState!.openEndDrawer();
              },
            )
          ],
          title: Text(AppLocalizations.of(context).translate('contacts'),
              style: AppTheme.getTextStyle(themeData.textTheme.headline6,
                  fontWeight: 600)),
          bottom: TabBar(
              onTap: (int val) {
                currentTabIndex = val;
                searchController.clear();
                sortContactList(tabIndex: val);
              },
              tabs: [
                Tab(
                    icon: Icon(MdiIcons.bookPlusMultipleOutline),
                    child:
                        Text(AppLocalizations.of(context).translate('leads'))),
                Tab(
                  icon: Icon(MdiIcons.accountGroupOutline),
                  child:
                      Text(AppLocalizations.of(context).translate('customer')),
                ),
                Tab(
                  icon: Icon(MdiIcons.accountMultipleOutline),
                  child:
                      Text(AppLocalizations.of(context).translate('suppliers')),
                )
              ]),
        ),
        body: TabBarView(
          children: [
            leadTab(leadsList),
            customerTab(customerList),
            supplierTab(suppliersList),
          ],
        ),
      ),
    );
  }

  //Retrieve leads list from api
  setLeadsList() async {
    setState(() {
      isLoading = false;
    });
    final dio = new Dio();
    var token = await System().getToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["Authorization"] = "Bearer $token";
    final response = await dio.get(fetchLeads!);
    List leads = response.data['data'];
    Map links = response.data['links'];
    setState(() {
      leads.forEach((element) {
        leadsList.add(element);
      });
    });
    isLoading = (links['next'] != null) ? true : false;
    fetchLeads = links['next'];
  }

  //Retrieve customers list from api
  setCustomersList() async {
    setState(() {
      isLoading = false;
    });
    final dio = new Dio();
    var token = await System().getToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["Authorization"] = "Bearer $token";
    final response = await dio.get(fetchCustomers!);
    List customers = response.data['data'];
    Map links = response.data['links'];
    setState(() {
      customers.forEach((element) {
        customerList.add(element);
      });
    });
    isLoading = (links['next'] != null) ? true : false;
    fetchCustomers = links['next'];
  }

  //Retrieve suppliers list from api
  setSuppliersList() async {
    setState(() {
      isLoading = false;
    });
    final dio = new Dio();
    var token = await System().getToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["Authorization"] = "Bearer $token";
    final response = await dio.get(fetchSuppliers!);
    List suppliers = response.data['data'];
    Map links = response.data['links'];
    setState(() {
      suppliers.forEach((element) {
        suppliersList.add(element);
      });
    });
    isLoading = (links['next'] != null) ? true : false;
    fetchSuppliers = links['next'];
  }

  //set initial list
  setAllList() async {
    fetchLeads = getUrl();
    setLeadsList();
    setCustomersList();
    setSuppliersList();
  }

  //lead widget
  Widget leadTab(leads) {
    return (leads.length > 0)
        ? ListView.builder(
            controller: leadsListController,
            padding: EdgeInsets.all(MySize.size12!),
            shrinkWrap: true,
            itemCount: leads.length + 1,
            itemBuilder: (context, index) {
              if (index == leads.length) {
                return (isLoading) ? _buildProgressIndicator() : Container();
              } else {}
              return Container(
                margin: EdgeInsets.only(bottom: MySize.size8!),
                padding: EdgeInsets.all(MySize.size8!),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.all(Radius.circular(MySize.size8!)),
                  color: customAppTheme.bgLayer1,
                  border:
                      Border.all(color: customAppTheme.bgLayer4, width: 1.2),
                ),
                child: contactBlock(leads[index]),
              );
            })
        : Helper().noDataWidget(context);
  }

  //customer widget
  Widget customerTab(customers) {
    return (customers.length > 0)
        ? ListView.builder(
            controller: customerListController,
            padding: EdgeInsets.all(MySize.size12!),
            shrinkWrap: true,
            itemCount: customers.length + 1,
            itemBuilder: (context, index) {
              if (index == customers.length) {
                return (isLoading) ? _buildProgressIndicator() : Container();
              } else {
                return Container(
                  margin: EdgeInsets.only(bottom: MySize.size8!),
                  padding: EdgeInsets.all(MySize.size8!),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.all(Radius.circular(MySize.size8!)),
                    color: customAppTheme.bgLayer1,
                    border:
                        Border.all(color: customAppTheme.bgLayer4, width: 1.2),
                  ),
                  child: contactBlock(customers[index]),
                );
              }
            })
        : Helper().noDataWidget(context);
  }

  //supplier widget
  Widget supplierTab(suppliers) {
    return (suppliers.length > 0)
        ? ListView.builder(
            controller: suppliersListController,
            padding: EdgeInsets.all(MySize.size12!),
            shrinkWrap: true,
            itemCount: suppliers.length + 1,
            itemBuilder: (context, index) {
              if (index == suppliers.length) {
                return (isLoading) ? _buildProgressIndicator() : Container();
              } else {
                return Container(
                  margin: EdgeInsets.only(bottom: MySize.size8!),
                  padding: EdgeInsets.all(MySize.size8!),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.all(Radius.circular(MySize.size8!)),
                    color: customAppTheme.bgLayer1,
                    border:
                        Border.all(color: customAppTheme.bgLayer4, width: 1.2),
                  ),
                  child: contactBlock(suppliers[index]),
                );
              }
            })
        : Helper().noDataWidget(context);
  }

  //filter widget
  Widget _filterDrawer() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(MySize.size12!),
        width: MediaQuery.of(context).size.width * 0.75,
        color: themeData.backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              // key: _formKey,
              child: TextFormField(
                  style: AppTheme.getTextStyle(themeData.textTheme.subtitle2,
                      letterSpacing: 0, fontWeight: 500),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).translate('search'),
                    hintStyle: AppTheme.getTextStyle(
                        themeData.textTheme.subtitle2,
                        letterSpacing: 0,
                        fontWeight: 500),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(MySize.size16!),
                        ),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(MySize.size16!),
                        ),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(MySize.size16!),
                        ),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: themeData.colorScheme.background,
                    prefixIcon: Icon(
                      MdiIcons.magnify,
                      color: themeData.colorScheme.onBackground.withAlpha(150),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.only(right: MySize.size16!),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  controller: searchController,
                  onEditingComplete: () {
                    setState(() {
                      sortContactList(
                        tabIndex: currentTabIndex,
                      );
                    });
                    //unFocus cursor from search area
                    FocusScopeNode currentFocus = FocusScope.of(context);
                    if (!currentFocus.hasPrimaryFocus) {
                      currentFocus.unfocus();
                    }
                    //call method
                  }),
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      useOrderBy = !useOrderBy;
                      sortContactList(
                        tabIndex: currentTabIndex,
                      );
                    });
                  },
                  icon: (useOrderBy)
                      ? Icon(Icons.keyboard_arrow_up_outlined)
                      : Icon(Icons.keyboard_arrow_down_outlined),
                  label: (useOrderBy)
                      ? Text(
                          "${AppLocalizations.of(context).translate('order_by')} :",
                          style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyText1,
                              fontWeight: 600,
                              letterSpacing: 0),
                        )
                      : Text(
                          AppLocalizations.of(context)
                              .translate('tap_for_order_by'),
                          style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyText1,
                              fontWeight: 600,
                              letterSpacing: 0),
                        ),
                ),
                Visibility(
                  visible: useOrderBy,
                  child: TextButton.icon(
                    onPressed: () {
                      orderByAsc = !orderByAsc;
                      setState(() {
                        orderByDirection = (orderByAsc) ? 'asc' : 'desc';
                        sortContactList(
                          tabIndex: currentTabIndex,
                        );
                      });
                    },
                    label: Text(
                      "$orderByDirection".toUpperCase(),
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyText1,
                          fontWeight: 500,
                          letterSpacing: 0),
                    ),
                    icon: (orderByAsc)
                        ? Icon(
                            MdiIcons.arrowUpCircleOutline,
                            color: Colors.black,
                          )
                        : Icon(MdiIcons.arrowDownCircleOutline,
                            color: Colors.black),
                  ),
                )
              ],
            ),
            Visibility(
              visible: useOrderBy,
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context).translate('name'),
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyText2,
                          fontWeight: 500,
                          letterSpacing: 0),
                    ),
                    leading: Radio(
                      value: 'name',
                      groupValue: orderByColumn,
                      onChanged: (value) {
                        setState(() {
                          orderByColumn = value.toString();
                          sortContactList(
                            tabIndex: currentTabIndex,
                          );
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context).translate('business_name'),
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyText2,
                          fontWeight: 500,
                          letterSpacing: 0),
                    ),
                    leading: Radio(
                      value: 'supplier_business_name',
                      groupValue: orderByColumn,
                      onChanged: (value) {
                        setState(() {
                          orderByColumn = value.toString();
                          sortContactList(
                            tabIndex: currentTabIndex,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Divider(),
            // RaisedButton.icon(
            //     onPressed: () {
            //       setState(() {
            //         sortContactList(
            //           tabIndex: currentTabIndex,
            //           searchText: searchController.text,
            //         );
            //       });
            //     },
            //     icon: Icon(Icons.margin),
            //     label: Text("APPLY"))
          ],
        ),
      ),
    );
  }

  //contact widget
  Widget contactBlock(contactDetails) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Visibility(
            visible:
                (contactDetails['supplier_business_name'].toString() != 'null'),
            child: Text(
              '${contactDetails['supplier_business_name']}',
              style: AppTheme.getTextStyle(
                themeData.textTheme.bodyText1,
                fontWeight: 600,
                color: themeData.colorScheme.onBackground,
              ),
            ),
          ),
          Visibility(
            visible: (contactDetails['name'].toString() != 'null' &&
                contactDetails['name'].toString().trim() != ''),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${AppLocalizations.of(context).translate('customer')} : ",
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyText1,
                    fontWeight: 600,
                    color: themeData.colorScheme.onBackground,
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    '${contactDetails['name']}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.bodyText2,
                      fontWeight: 500,
                      color: themeData.colorScheme.onBackground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: (contactDetails['last_follow_up'].toString() != 'null' &&
                contactDetails['last_follow_up'].toString().trim() != ''),
            child: Row(
              children: [
                Text(
                  "${AppLocalizations.of(context).translate('last')} : ",
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyText1,
                    fontWeight: 600,
                    color: themeData.colorScheme.onBackground,
                  ),
                ),
                Text(
                  (contactDetails['last_follow_up'].toString() != 'null')
                      ? '${contactDetails['last_follow_up']}'
                      : ' - ',
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyText2,
                    fontWeight: 500,
                    color: themeData.colorScheme.onBackground,
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: (contactDetails['upcoming_follow_up'].toString() !=
                    'null' &&
                contactDetails['upcoming_follow_up'].toString().trim() != ''),
            child: Row(
              children: [
                Text(
                  "${AppLocalizations.of(context).translate('upcoming')} : ",
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyText1,
                    fontWeight: 600,
                    color: themeData.colorScheme.onBackground,
                  ),
                ),
                Text(
                  (contactDetails['upcoming_follow_up'].toString() != 'null')
                      ? '${contactDetails['upcoming_follow_up']}'
                      : ' - ',
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyText2,
                    fontWeight: 500,
                    color: themeData.colorScheme.onBackground,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Helper().callDropdown(
                  context,
                  contactDetails,
                  [
                    contactDetails['mobile'],
                    contactDetails['alternate_number'],
                    contactDetails['landline']
                  ],
                  type: 'call'),
              SizedBox(
                height: MySize.size40!,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                FollowUpForm(contactDetails)));
                  },
                  icon: Icon(
                    Icons.add,
                    color: themeData.colorScheme.primary,
                  ),
                  label: Text(
                    AppLocalizations.of(context).translate('add_follow_up'),
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.bodyText1,
                      fontWeight: 600,
                      color: themeData.colorScheme.primary,
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  //filter list
  sortContactList({int? tabIndex}) {
    switch (tabIndex) {
      case 0:
        {
          leadsList = [];
          fetchLeads = getUrl();
          setLeadsList();
        }
        break;
      case 1:
        {
          customerList = [];
          fetchCustomers = getUrl();
          setCustomersList();
        }
        break;
      case 2:
        {
          suppliersList = [];
          fetchSuppliers = getUrl();
          setSuppliersList();
        }
        break;
    }
  }

  getUrl({String? perPage = '10'}) {
    String contactType = (currentTabIndex == 0) ? 'crm/leads?' : 'contactapi?';
    String url = Api().apiUrl + contactType;

    Map<String, dynamic> params = {};

    if (currentTabIndex == 1) {
      params['type'] = 'customer';
    }
    if (currentTabIndex == 2) {
      params['type'] = 'supplier';
    }
    if (searchController.text != '') {
      params['name'] = searchController.text;
      params['biz_name'] = searchController.text;
      params['mobile_num'] = searchController.text;
      params['contact_id'] = searchController.text;
    }

    if (perPage != null) {
      params['per_page'] = perPage;
    }

    if (useOrderBy) {
      params['order_by'] = '$orderByColumn';
      params['direction'] = '$orderByDirection';
    }

    String queryString = Uri(queryParameters: params).query;
    url += queryString;
    return url;
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
}
