import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../apis/api.dart';
import '../apis/follow_up.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/contact_model.dart';
import '../models/system.dart';
import 'forms.dart';

class FollowUp extends StatefulWidget {
  @override
  _FollowUpState createState() => _FollowUpState();
}

class _FollowUpState extends State<FollowUp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<bool> toggleValue = [true, false, false];
  int selectedToggleValue = 0;
  int? showCustomerDetails;
  List followUpList = [];

  List<String> followUpStatusList = [
        "All",
        "Scheduled",
        "Open",
        "Canceled",
        "Completed"
      ],
      followUpTypeList = ["All", "Call", "Sms", "Meeting", "Email"];

  String? followUpUrl = Api().apiUrl + "crm/follow-ups?per_page=10";
  String selectedFollowUpType = "All", selectedFollowUpStatus = "All";

  ScrollController followUpListController = ScrollController();
  bool isLoading = false, accessFollowUp = false;

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    getPermission();
    followUpListController.addListener(() {
      if (followUpListController.position.pixels ==
          followUpListController.position.maxScrollExtent) {
        getFollowUpList();
      }
    });
    Helper().syncCallLogs();
  }

  getFollowUpList() async {
    setState(() {
      isLoading = false;
    });
    final dio = new Dio();
    var token = await System().getToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["Authorization"] = "Bearer $token";
    final response = await dio.get(followUpUrl!);
    List followUps = response.data['data'];
    Map links = response.data['links'];
    setState(() {
      followUps.forEach((element) {
        followUpList.add(element);
      });
    });
    isLoading = (links['next'] != null) ? true : false;
    followUpUrl = links['next'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _filterDrawer(),
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
        title: Text(AppLocalizations.of(context).translate('follow_ups'),
            style: AppTheme.getTextStyle(themeData.textTheme.headline6,
                fontWeight: 600)),
      ),
      body: (accessFollowUp)
          ? followUps()
          : Center(
              child: Text(
                AppLocalizations.of(context).translate('unauthorised'),
              ),
            ),
    );
  }

  Widget followUps() {
    return Column(
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
              textStyle: AppTheme.getTextStyle(themeData.textTheme.bodyText1,
                  fontWeight: 600, color: themeData.colorScheme.onBackground),
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
        Expanded(
          child: (followUpList.length > 0)
              ? ListView.builder(
                  controller: followUpListController,
                  padding: EdgeInsets.all(MySize.size16!),
                  shrinkWrap: true,
                  itemCount:
                      (followUpList.isNotEmpty) ? followUpList.length : 0,
                  itemBuilder: (context, index) {
                    if (index == followUpList.length) {
                      return (isLoading)
                          ? _buildProgressIndicator()
                          : Container();
                    } else {
                      return Container(
                          margin: EdgeInsets.only(bottom: MySize.size8!),
                          padding: EdgeInsets.all(MySize.size8!),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(
                                Radius.circular(MySize.size8!)),
                            color: customAppTheme.bgLayer1,
                            border: Border.all(
                                color: customAppTheme.bgLayer4, width: 1.2),
                          ),
                          child: Column(
                            children: [
                              contactBlock(followUpList[index]),
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
                                          visible: (followUpList[index]
                                                      ['customer']['name'] !=
                                                  null &&
                                              followUpList[index]['customer']
                                                          ['name']
                                                      .toString()
                                                      .trim() !=
                                                  ''),
                                          child: Text(
                                            '${followUpList[index]['customer']['name']}',
                                            style: AppTheme.getTextStyle(
                                              themeData.textTheme.bodyText1,
                                              fontWeight: 500,
                                              color: themeData
                                                  .colorScheme.onBackground,
                                            ),
                                          ),
                                        ),
                                        Visibility(
                                          visible: (followUpList[index]
                                                          ['customer'][
                                                      'supplier_business_name'] !=
                                                  null &&
                                              followUpList[index]['customer'][
                                                          'supplier_business_name']
                                                      .toString()
                                                      .trim() !=
                                                  ''),
                                          child: Text(
                                            '${followUpList[index]['customer']['supplier_business_name']}',
                                            style: AppTheme.getTextStyle(
                                              themeData.textTheme.bodyText1,
                                              fontWeight: 500,
                                              color: themeData
                                                  .colorScheme.onBackground,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: MySize.screenWidth! * 0.8,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              (followUpList[index]['customer']
                                                          ['address_line_1'] !=
                                                      null)
                                                  ? Text(
                                                      "${followUpList[index]['customer']['address_line_1'] ?? ''}",
                                                      style:
                                                          AppTheme.getTextStyle(
                                                        themeData.textTheme
                                                            .bodyText1,
                                                        fontWeight: 500,
                                                        color: themeData
                                                            .colorScheme
                                                            .onBackground,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                    )
                                                  : Container(),
                                              (followUpList[index]['customer']
                                                          ['address_line_2'] !=
                                                      null)
                                                  ? Text(
                                                      "${followUpList[index]['customer']['address_line_2'] ?? ''}",
                                                      style:
                                                          AppTheme.getTextStyle(
                                                        themeData.textTheme
                                                            .bodyText1,
                                                        fontWeight: 500,
                                                        color: themeData
                                                            .colorScheme
                                                            .onBackground,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                    )
                                                  : Container(),
                                              Text(
                                                "${followUpList[index]['customer']['city'] ?? ''} "
                                                "${followUpList[index]['customer']['state'] ?? ''} "
                                                "${followUpList[index]['customer']['country'] ?? ''} "
                                                "${followUpList[index]['customer']['zip_code'] ?? ''} ",
                                                style: AppTheme.getTextStyle(
                                                  themeData.textTheme.bodyText1,
                                                  fontWeight: 500,
                                                  color: themeData
                                                      .colorScheme.onBackground,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                              (followUpList[index]['customer']
                                                          ['email'] !=
                                                      null)
                                                  ? Text(
                                                      "${followUpList[index]['customer']['email'] ?? ''}",
                                                      style:
                                                          AppTheme.getTextStyle(
                                                        themeData.textTheme
                                                            .bodyText1,
                                                        fontWeight: 500,
                                                        color: themeData
                                                            .colorScheme
                                                            .onBackground,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                    )
                                                  : Container(),
                                              (followUpList[index]['customer']
                                                          ['mobile'] !=
                                                      null)
                                                  ? Text(
                                                      "${followUpList[index]['customer']['mobile'] ?? ''} "
                                                      "${followUpList[index]['customer']['alternate_number'] ?? ''} "
                                                      "${followUpList[index]['customer']['landline'] ?? ''} ",
                                                      style:
                                                          AppTheme.getTextStyle(
                                                        themeData.textTheme
                                                            .bodyText1,
                                                        fontWeight: 500,
                                                        color: themeData
                                                            .colorScheme
                                                            .onBackground,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                    )
                                                  : Container(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              )
                            ],
                          ));
                    }
                  })
              : Helper().noDataWidget(context),
        ),
      ],
    );
  }

//contact widget
  Widget contactBlock(followUpDetails) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Visibility(
            visible: (followUpDetails['customer']['supplier_business_name'] !=
                    null &&
                followUpDetails['customer']['supplier_business_name']
                        .toString()
                        .trim() !=
                    ''),
            child: Text(
              '${followUpDetails['customer']['supplier_business_name']}',
              style: AppTheme.getTextStyle(
                themeData.textTheme.headline6,
                fontWeight: 600,
                color: themeData.colorScheme.onBackground,
              ),
            ),
          ),
          Text(
            '${followUpDetails['title']}',
            style: AppTheme.getTextStyle(
              themeData.textTheme.subtitle1,
              fontWeight: 600,
              color: themeData.colorScheme.primaryVariant,
            ),
          ),
          Visibility(
            visible: (followUpDetails['customer']['name'] != null &&
                followUpDetails['customer']['name'].toString().trim() != ''),
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
                    '${followUpDetails['customer']['name']}',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "${AppLocalizations.of(context).translate('follow_up_type')} : ",
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyText1,
                          fontWeight: 600,
                          color: themeData.colorScheme.onBackground,
                        ),
                      ),
                      Text(
                        '${followUpDetails['schedule_type'].toUpperCase()}',
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyText2,
                          fontWeight: 500,
                          color: themeData.colorScheme.onBackground,
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
                        (followUpDetails['status'] != null)
                            ? '${followUpDetails['status'].toUpperCase()}'
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
                    visible: (followUpDetails['followup_category'] != null),
                    child: Row(
                      children: [
                        Text(
                          '${AppLocalizations.of(context).translate('follow_up_category')} : ',
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.bodyText1,
                            fontWeight: 600,
                            color: themeData.colorScheme.onBackground,
                          ),
                        ),
                        Text(
                          (followUpDetails['followup_category'] != null)
                              ? followUpDetails['followup_category']['name']
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
                    visible: (followUpDetails['start_datetime'].toString() !=
                            'null' &&
                        followUpDetails['start_datetime'].toString().trim() !=
                            ''),
                    child: Row(
                      children: [
                        Text(
                          '${AppLocalizations.of(context).translate('start')} : ',
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.bodyText1,
                            fontWeight: 600,
                            color: themeData.colorScheme.onBackground,
                          ),
                        ),
                        Text(
                          (followUpDetails['start_datetime'].toString() !=
                                  'null')
                              ? '${followUpDetails['start_datetime']}'
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
                    visible:
                        (followUpDetails['end_datetime'].toString() != 'null' &&
                            followUpDetails['end_datetime'].toString().trim() !=
                                ''),
                    child: Row(
                      children: [
                        Text(
                          '${AppLocalizations.of(context).translate('end')} : ',
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.bodyText1,
                            fontWeight: 600,
                            color: themeData.colorScheme.onBackground,
                          ),
                        ),
                        Text(
                          (followUpDetails['end_datetime'].toString() != 'null')
                              ? '${followUpDetails['end_datetime']}'
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
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Visibility(
                    visible: (followUpDetails['status'] == 'open'),
                    child: GestureDetector(
                      onTap: () async {
                        await FollowUpApi()
                            .getSpecifiedFollowUp(followUpDetails['id'])
                            .then((value) {
                          var customerDetails =
                              FollowUpModel().followUpForm(value);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowUpForm(
                                customerDetails,
                                edit: true,
                              ),
                            ),
                          );
                        });
                      },
                      child: Icon(
                        MdiIcons.fileDocumentEditOutline,
                        color: themeData.colorScheme.onBackground,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: (followUpDetails['schedule_type'] == 'call' &&
                        followUpDetails['status'] == 'open'),
                    child: Helper().callDropdown(
                        context,
                        followUpDetails,
                        [
                          followUpDetails['customer']['mobile'],
                          followUpDetails['customer']['alternate_number'],
                          followUpDetails['customer']['landline']
                        ],
                        type: 'whatsApp'),
                  ),
                  Visibility(
                    visible: (followUpDetails['schedule_type'] == 'call' &&
                        followUpDetails['status'] == 'open'),
                    child: Helper().callDropdown(
                        context,
                        followUpDetails,
                        [
                          followUpDetails['customer']['mobile'],
                          followUpDetails['customer']['alternate_number'],
                          followUpDetails['customer']['landline']
                        ],
                        type: 'call'),
                  ),
                ],
              ),
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
              "${AppLocalizations.of(context).translate('follow_up_status')} : ",
              style: AppTheme.getTextStyle(themeData.textTheme.bodyText1,
                  fontWeight: 600, color: themeData.colorScheme.onBackground),
            ),
            followUpStatus(),
            Divider(),
            Text(
              "${AppLocalizations.of(context).translate('follow_up_type')} : ",
              style: AppTheme.getTextStyle(themeData.textTheme.bodyText1,
                  fontWeight: 600, color: themeData.colorScheme.onBackground),
            ),
            followUpType(),
            Divider(),
          ],
        ),
      ),
    );
  }

  onToggleFilter(int index) {
    String? formattedDate;
    setState(() {
      followUpList = [];
    });
    if (index == 0) {
      formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    if (index == 1) {
      formattedDate = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().add(Duration(days: 1)));
    }
    followUpUrl = getFollowUpURL(
        endDate: formattedDate,
        startDate: formattedDate,
        followUpStatus: selectedFollowUpStatus.toLowerCase(),
        followUpType: selectedFollowUpType.toLowerCase());

    getFollowUpList();
  }

  getFollowUpURL(
      {String? perPage = '10',
      String? startDate,
      String? endDate,
      String? followUpType,
      String? followUpStatus}) {
    String url = Api().apiUrl + "crm/follow-ups?";

    Map<String, dynamic> params = {
      'order_by': 'start_datetime',
      'direction': 'desc'
    };
    if (perPage != null) {
      params['per_page'] = perPage;
    }

    if (startDate != null) {
      params['start_date'] = startDate;
    }

    if (endDate != null) {
      params['end_date'] = startDate;
    }

    if (followUpType != 'all') {
      params['follow_up_type'] = followUpType;
    }

    if (followUpStatus != 'all') {
      params['status'] = followUpStatus;
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
    if (await Helper().getPermission("crm.access_all_schedule") ||
        await Helper().getPermission("crm.access_own_schedule")) {
      accessFollowUp = true;
      onToggleFilter(selectedToggleValue);
    }
  }

  Widget followUpStatus() {
    return DropdownButtonHideUnderline(
      child: DropdownButton(
          dropdownColor: themeData.backgroundColor,
          icon: Icon(
            Icons.arrow_drop_down,
          ),
          value: selectedFollowUpStatus,
          items:
              followUpStatusList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  '$value',
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.getTextStyle(themeData.textTheme.bodyText2,
                      fontWeight: 500,
                      color: themeData.colorScheme.onBackground),
                ));
          }).toList(),
          onChanged: (newValue) async {
            setState(() {
              selectedFollowUpStatus = newValue.toString();
              onToggleFilter(selectedToggleValue);
            });
          }),
    );
  }

  Widget followUpType() {
    return DropdownButtonHideUnderline(
      child: DropdownButton(
          dropdownColor: themeData.backgroundColor,
          icon: Icon(
            Icons.arrow_drop_down,
          ),
          value: selectedFollowUpType,
          items: followUpTypeList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  '$value',
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.getTextStyle(themeData.textTheme.bodyText2,
                      fontWeight: 500,
                      color: themeData.colorScheme.onBackground),
                ));
          }).toList(),
          onChanged: (newValue) async {
            setState(() {
              selectedFollowUpType = newValue.toString();
              onToggleFilter(selectedToggleValue);
            });
          }),
    );
  }
}
