import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../apis/api.dart';
import '../config.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/field_force.dart';
import '../models/system.dart';
import 'add_visit.dart';
import 'forms.dart';

class FieldForce extends StatefulWidget {
  @override
  _FieldForceState createState() => _FieldForceState();
}

class _FieldForceState extends State<FieldForce> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<bool> toggleValue = [true, false, false];
  int selectedToggleValue = 0;
  int? showCustomerDetails;
  List fieldForceList = [];

  List<Map<String, String>> fieldForceStatusList = [
    {"key": "all", "value": "All"},
    {"key": "assigned", "value": "Assigned"},
    {"key": "finished", "value": "Finished"},
    {"key": "met_contact", "value": "Met contact"},
    {"key": "did_not_meet_contact", "value": "Did not meet contact"}
  ];

  String? fieldForceUrl =
      Api().apiUrl + "field-force?per_page=10&assigned_to=${Config.userId}";
  String selectedVisitStatus = "all";

  ScrollController fieldForceListController = ScrollController();
  bool isLoading = false, accessFieldVisit = false;

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    getPermission();
    fieldForceListController.addListener(() {
      if (fieldForceListController.position.pixels ==
          fieldForceListController.position.maxScrollExtent) {
        getFieldForceList();
      }
    });
    Helper().syncCallLogs();
  }

  getFieldForceList() async {
    setState(() {
      isLoading = false;
    });
    final dio = new Dio();
    var token = await System().getToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["Authorization"] = "Bearer $token";
    final response = await dio.get(fieldForceUrl!);
    List fieldVisits = response.data['data'];
    Map links = response.data['links'];
    setState(() {
      fieldVisits.forEach((element) {
        fieldForceList.add(FiledForceModel().getVisits(element));
      });
    });
    isLoading = (links['next'] != null) ? true : false;
    fieldForceUrl = links['next'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        endDrawer: _filterDrawer(),
        floatingActionButton: FloatingActionButton(
          child: Text("+ ${AppLocalizations.of(context).translate('add')}"),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => NewVisitForm()));
          },
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
          title: Text(
              AppLocalizations.of(context).translate('field_force_visits'),
              style: AppTheme.getTextStyle(themeData.textTheme.headline6,
                  fontWeight: 600)),
        ),
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ToggleButtons(
                  selectedColor: themeData.colorScheme.onPrimary,
                  borderRadius: BorderRadius.circular(MySize.size4!),
                  borderColor: themeData.colorScheme.primary,
                  selectedBorderColor: themeData.colorScheme.primary,
                  fillColor: themeData.colorScheme.primary,
                  color: themeData.colorScheme.primary,
                  textStyle: AppTheme.getTextStyle(
                      themeData.textTheme.bodyText1,
                      fontWeight: 600,
                      color: themeData.colorScheme.onBackground),
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(MySize.size10!),
                      child: Text(
                        AppLocalizations.of(context).translate('today'),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(MySize.size10!),
                      child: Text(
                        AppLocalizations.of(context).translate('tomorrow'),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(MySize.size10!),
                      child: Text(
                        AppLocalizations.of(context).translate('all'),
                      ),
                    ),
                  ],
                  onPressed: (int index) {
                    setState(() {
                      showCustomerDetails = null;
                      selectedToggleValue = index;
                      for (int i = 0; i < toggleValue.length; i++) {
                        toggleValue[i] = i == index;
                      }
                      onToggleFilter(index);
                    });
                  },
                  isSelected: toggleValue,
                ),
              ],
            ),
            Expanded(child: fieldForces()),
          ],
        ));
  }

  onToggleFilter(int index) {
    String? formattedDate;
    setState(() {
      fieldForceList = [];
    });
    if (index == 0) {
      formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    if (index == 1) {
      formattedDate = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().add(Duration(days: 1)));
    }
    fieldForceUrl = getFieldForceURL(
      endDate: formattedDate,
      startDate: formattedDate,
      visitStatus: selectedVisitStatus,
    );

    getFieldForceList();
  }

  Widget fieldForces() {
    return Column(
      children: [
        Expanded(
          child: (fieldForceList.length > 0)
              ? ListView.builder(
                  controller: fieldForceListController,
                  padding: EdgeInsets.all(MySize.size16!),
                  shrinkWrap: true,
                  itemCount: fieldForceList.length,
                  itemBuilder: (context, index) {
                    if (index == fieldForceList.length) {
                      return (isLoading)
                          ? _buildProgressIndicator()
                          : Container();
                    } else {
                      return Container(
                        margin: EdgeInsets.only(bottom: MySize.size8!),
                        padding: EdgeInsets.all(MySize.size8!),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.all(Radius.circular(MySize.size8!)),
                          color: customAppTheme.bgLayer1,
                          border: Border.all(
                              color: customAppTheme.bgLayer4, width: 1.2),
                        ),
                        child: Column(
                          children: [
                            visitBlock(fieldForceList[index]),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  child: Icon(
                                    (showCustomerDetails == index)
                                        ? MdiIcons.chevronUp
                                        : MdiIcons.chevronDown,
                                    color: themeData.colorScheme.primary,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      showCustomerDetails =
                                          (showCustomerDetails == index)
                                              ? null
                                              : index;
                                    });
                                  },
                                )
                              ],
                            ),
                            Row(
                              children: [
                                Visibility(
                                  visible: (showCustomerDetails == index),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Visibility(
                                        visible: (fieldForceList[index]
                                                ['visited_address'] ==
                                            null),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Visibility(
                                              visible: (fieldForceList[index]
                                                      ['contact']['name'] !=
                                                  null),
                                              child: Text(
                                                '${fieldForceList[index]['contact']['name']}',
                                                style: AppTheme.getTextStyle(
                                                  themeData.textTheme.bodyText1,
                                                  fontWeight: 500,
                                                  color: themeData
                                                      .colorScheme.onBackground,
                                                ),
                                              ),
                                            ),
                                            Visibility(
                                              visible: (fieldForceList[index]
                                                          ['contact'][
                                                      'supplier_business_name'] !=
                                                  null),
                                              child: Text(
                                                '${fieldForceList[index]['contact']['supplier_business_name']}',
                                                style: AppTheme.getTextStyle(
                                                  themeData.textTheme.bodyText1,
                                                  fontWeight: 500,
                                                  color: themeData
                                                      .colorScheme.onBackground,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  width: MySize.screenWidth! *
                                                      0.75,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Visibility(
                                                        visible: fieldForceList[
                                                                        index]
                                                                    ['contact']
                                                                ['address'] !=
                                                            null,
                                                        child: Text(
                                                          "${fieldForceList[index]['contact']['address'] ?? ''}",
                                                          style: AppTheme
                                                              .getTextStyle(
                                                            themeData.textTheme
                                                                .bodyText1,
                                                            fontWeight: 500,
                                                            color: themeData
                                                                .colorScheme
                                                                .onBackground,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 3,
                                                        ),
                                                      ),
                                                      Visibility(
                                                        visible: fieldForceList[
                                                                        index]
                                                                    ['contact']
                                                                ['email'] !=
                                                            '',
                                                        child: Text(
                                                          "${fieldForceList[index]['contact']['email'] ?? ''}",
                                                          style: AppTheme
                                                              .getTextStyle(
                                                            themeData.textTheme
                                                                .bodyText1,
                                                            fontWeight: 500,
                                                            color: themeData
                                                                .colorScheme
                                                                .onBackground,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 2,
                                                        ),
                                                      ),
                                                      Visibility(
                                                        visible: fieldForceList[
                                                                            index]
                                                                        [
                                                                        'contact']
                                                                    [
                                                                    'contact_numbers']
                                                                .length >
                                                            0,
                                                        child: Text(
                                                          "${fieldForceList[index]['contact']['contact_numbers'].join(', ')} ",
                                                          style: AppTheme
                                                              .getTextStyle(
                                                            themeData.textTheme
                                                                .bodyText1,
                                                            fontWeight: 500,
                                                            color: themeData
                                                                .colorScheme
                                                                .onBackground,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  child: Visibility(
                                                    visible: true,
                                                    // (visitDetails['assigned_to'] == Config.userId &&
                                                    //     visitDetails['status'] != 'finished'),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        MdiIcons
                                                            .mapMarkerRightOutline,
                                                        color: themeData
                                                            .colorScheme
                                                            .onBackground,
                                                      ),
                                                      onPressed: () async {
                                                        String fullAddress =
                                                            "${fieldForceList[index]['contact']['address']}";
                                                        String address =
                                                            Uri.encodeComponent(
                                                                fullAddress);
                                                        String googleUrl =
                                                            'https://maps.google.com/?q=$address';
                                                        await launch(
                                                            "$googleUrl");
                                                      },
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Visibility(
                                        visible: (fieldForceList[index]
                                                ['visited_address'] !=
                                            null),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: MySize.screenWidth! * 0.75,
                                              child: Text(
                                                (fieldForceList[index][
                                                            'visited_address'] !=
                                                        null)
                                                    ? '${fieldForceList[index]['visited_address']}'
                                                    : ' - ',
                                                style: AppTheme.getTextStyle(
                                                  themeData.textTheme.bodyText2,
                                                  fontWeight: 500,
                                                  color: themeData
                                                      .colorScheme.onBackground,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              child: Visibility(
                                                visible: (fieldForceList[index]
                                                        ['visited_address'] !=
                                                    null),
                                                child: IconButton(
                                                  icon: Icon(
                                                    MdiIcons
                                                        .mapMarkerRightOutline,
                                                    color: themeData.colorScheme
                                                        .onBackground,
                                                  ),
                                                  onPressed: () async {
                                                    String address = (fieldForceList[
                                                                        index][
                                                                    'visited_address_latitude'] !=
                                                                null &&
                                                            fieldForceList[
                                                                        index][
                                                                    'visited_address_latitude'] !=
                                                                null)
                                                        ? "loc:${fieldForceList[index]['visited_address_latitude']}+${fieldForceList[index]['visited_address_longitude']}"
                                                        : Uri.encodeComponent(
                                                            "${fieldForceList[index]['visited_address']}");
                                                    String googleUrl =
                                                        'https://maps.google.com/?q=$address';
                                                    await launch("$googleUrl");
                                                  },
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: MySize.size4!)),
                                      Text(
                                        '${AppLocalizations.of(context).translate('meet_with')} : ',
                                        style: AppTheme.getTextStyle(
                                          themeData.textTheme.bodyText1,
                                          fontWeight: 600,
                                          color: themeData
                                              .colorScheme.onBackground,
                                        ),
                                      ),
                                      meetValue(
                                          1,
                                          fieldForceList[index]['meet_with'],
                                          fieldForceList[index]
                                              ['meet_with_mobile_no'],
                                          fieldForceList[index]
                                              ['meet_with_designation']),
                                      meetValue(
                                          2,
                                          fieldForceList[index]['meet_with2'],
                                          fieldForceList[index]
                                              ['meet_with_mobile_no2'],
                                          fieldForceList[index]
                                              ['meet_with_designation2']),
                                      meetValue(
                                          3,
                                          fieldForceList[index]['meet_with3'],
                                          fieldForceList[index]
                                              ['meet_with_mobile_no3'],
                                          fieldForceList[index]
                                              ['meet_with_designation3']),
                                    ],
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      );
                    }
                  })
              : Helper().noDataWidget(context),
        ),
      ],
    );
  }

  //meet value
  Widget meetValue(
      int index, String? name, String? designation, String? mobile) {
    String meetDetails = '$index. ';
    if (name != null) {
      meetDetails += '$name';
    }
    if (designation != null) {
      meetDetails += ', $designation';
    }
    if (mobile != null) {
      meetDetails += ', $mobile';
    }
    return Visibility(
      visible: ((name != null) && (designation != null) && (mobile != null)),
      child: Padding(
        padding: EdgeInsets.only(left: MySize.size4!),
        child: SizedBox(
          width: MySize.screenWidth! * 0.8,
          child: Text(
            '$meetDetails',
            style: AppTheme.getTextStyle(
              themeData.textTheme.bodyText2,
              fontWeight: 600,
              color: themeData.colorScheme.onBackground,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

//contact widget
  Widget visitBlock(visitDetails) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Visibility(
            visible:
                (visitDetails['contact']['supplier_business_name'] != null),
            child: Text(
              '${visitDetails['contact']['supplier_business_name']}',
              style: AppTheme.getTextStyle(
                themeData.textTheme.headline6,
                fontWeight: 600,
                color: themeData.colorScheme.onBackground,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${visitDetails['visit_id']}",
                      style: AppTheme.getTextStyle(
                        themeData.textTheme.subtitle1,
                        fontWeight: 600,
                        color: themeData.colorScheme.primaryVariant,
                      ),
                    ),
                    Visibility(
                      visible: (visitDetails['contact_id'] != null),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Contact Id : ",
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyText1,
                              fontWeight: 600,
                              color: themeData.colorScheme.onBackground,
                            ),
                          ),
                          Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              '${visitDetails['contact_id']}',
                              maxLines: 2,
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
                      visible: (visitDetails['contact']['name'] != null),
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
                              '${visitDetails['contact']['name']}',
                              maxLines: 2,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "${AppLocalizations.of(context).translate('assigned_to')} : ",
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyText1,
                                fontWeight: 600,
                                color: themeData.colorScheme.onBackground,
                              ),
                            ),
                            Flexible(
                              fit: FlexFit.loose,
                              child: Text(
                                "${visitDetails['user']['name']}",
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.bodyText2,
                                  fontWeight: 500,
                                  color: themeData.colorScheme.onBackground,
                                ),
                              ),
                            )
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              "${AppLocalizations.of(context).translate('status')} : ",
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyText1,
                                fontWeight: 600,
                                color: themeData.colorScheme.onBackground,
                              ),
                            ),
                            Text(
                              (visitDetails['status'] != null)
                                  ? '${visitDetails['status'].toUpperCase()}'
                                  : '-',
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyText2,
                                fontWeight: 500,
                                color: themeData.colorScheme.onBackground,
                              ),
                            )
                          ],
                        ),
                        Visibility(
                          visible: (visitDetails['visited_on'] == null),
                          child: Row(
                            children: [
                              Text(
                                '${AppLocalizations.of(context).translate('visit_on')} : ',
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.bodyText1,
                                  fontWeight: 600,
                                  color: themeData.colorScheme.onBackground,
                                ),
                              ),
                              Text(
                                (visitDetails['visit_on'] != null)
                                    ? '${visitDetails['visit_on']}'
                                    : ' - ',
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
                          visible: (visitDetails['visited_on'] != null),
                          child: Row(
                            children: [
                              Text(
                                '${AppLocalizations.of(context).translate('visited_on')} : ',
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.bodyText1,
                                  fontWeight: 600,
                                  color: themeData.colorScheme.onBackground,
                                ),
                              ),
                              Text(
                                (visitDetails['visited_on'] != null)
                                    ? '${visitDetails['visited_on']}'
                                    : ' - ',
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.bodyText2,
                                  fontWeight: 500,
                                  color: themeData.colorScheme.onBackground,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Visibility(
                      visible: (visitDetails['assigned_to'] == Config.userId &&
                          visitDetails['status'] == 'assigned'),
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      VisitForm(visit: visitDetails)));
                        },
                        child: Icon(
                          MdiIcons.squareEditOutline,
                          color: themeData.colorScheme.onBackground,
                        ),
                      ),
                    ),
                    Visibility(
                      visible:
                          (visitDetails['contact']['contact_numbers'].length >
                              0),
                      child: Helper().callDropdown(context, visitDetails,
                          visitDetails['contact']['contact_numbers'],
                          type: 'whatsApp'),
                    ),
                    Visibility(
                      visible:
                          (visitDetails['contact']['contact_numbers'].length >
                              0),
                      child: Helper().callDropdown(context, visitDetails,
                          visitDetails['contact']['contact_numbers'],
                          type: 'call'),
                    ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(MySize.size8!),
                  child: Text(
                    AppLocalizations.of(context).translate('filter'),
                    style: AppTheme.getTextStyle(themeData.textTheme.headline6,
                        fontWeight: 600,
                        color: themeData.colorScheme.onBackground),
                  ),
                ),
              ],
            ),
            Divider(),
            Text(
              "${AppLocalizations.of(context).translate('visit_status')} : ",
              style: AppTheme.getTextStyle(themeData.textTheme.bodyText1,
                  fontWeight: 600, color: themeData.colorScheme.onBackground),
            ),
            fieldVisitStatus(),
            Divider(),
          ],
        ),
      ),
    );
  }

  getFieldForceURL(
      {String? perPage = '10',
      String? startDate,
      String? endDate,
      String? visitStatus}) {
    String url = Api().apiUrl + "field-force?";

    Map<String, dynamic> params = {
      'per_page': perPage,
      'assigned_to': '${Config.userId}'
    };

    if (startDate != null) {
      params['start_date'] = startDate;
    }

    if (endDate != null) {
      params['end_date'] = startDate;
    }

    if (visitStatus != 'all') {
      params['status'] = visitStatus;
    }

    String queryString = Uri(queryParameters: params).query;
    url += queryString;
    return url;
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

//Fetch permission from database
  getPermission() async {
    // if (await Helper().getPermission("crm.access_all_schedule") ||
    //     await Helper().getPermission("crm.access_own_schedule")) {
    // accessFieldVisit = true;
    onToggleFilter(selectedToggleValue);
    // }
  }

  Widget fieldVisitStatus() {
    return DropdownButtonHideUnderline(
      child: DropdownButton(
          dropdownColor: themeData.backgroundColor,
          icon: Icon(
            Icons.arrow_drop_down,
          ),
          value: selectedVisitStatus,
          items: fieldForceStatusList
              .map<DropdownMenuItem<String>>((Map<String, String> value) {
            return DropdownMenuItem<String>(
                value: value['key'],
                child: Text(
                  '${value['value']}',
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.getTextStyle(themeData.textTheme.bodyText2,
                      fontWeight: 500,
                      color: themeData.colorScheme.onBackground),
                ));
          }).toList(),
          onChanged: (String? newValue) async {
            setState(() {
              selectedVisitStatus = newValue!;
              onToggleFilter(selectedToggleValue);
            });
          }),
    );
  }
}
