// import 'package:call_log/call_log.dart';

import 'dart:convert';
import 'dart:io';

import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../apis/field_force.dart';
import '../apis/follow_up.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/contact_model.dart';

class VisitForm extends StatefulWidget {
  const VisitForm({Key? key, this.visit}) : super(key: key);
  final visit;

  @override
  _VisitFormState createState() => _VisitFormState();
}

class _VisitFormState extends State<VisitForm> {
  String visitStatus = '', location = '';
  XFile? _image;
  bool isLoading = false, showMeet2 = false, showMeet3 = false;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  LatLng? currentLoc;

  TextEditingController reasonController = new TextEditingController(),
      meetWith = new TextEditingController(),
      meetMobile = new TextEditingController(),
      meetDesignation = new TextEditingController(),
      meetWith2 = new TextEditingController(),
      meetMobile2 = new TextEditingController(),
      meetDesignation2 = new TextEditingController(),
      meetWith3 = new TextEditingController(),
      meetMobile3 = new TextEditingController(),
      meetDesignation3 = new TextEditingController(),
      discussionController = new TextEditingController();

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    visitStatus = widget.visit['status'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "${widget.visit['visit_id']}",
          style: AppTheme.getTextStyle(
            themeData.textTheme.subtitle1,
            fontWeight: 600,
            color: themeData.colorScheme.primaryVariant,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
        child: (isLoading)
            ? Helper().loadingIndicator(context)
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate('Did_you_meet_with_the_contact'),
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.headline6,
                            fontWeight: 600,
                            color: themeData.colorScheme.primaryVariant,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Radio(
                          value: 'met_contact',
                          groupValue: visitStatus,
                          onChanged: (String? value) {
                            setState(() {
                              visitStatus = value!;
                            });
                          },
                          toggleable: true,
                        ),
                        Padding(
                          padding: EdgeInsets.all(MySize.size6!),
                          child: Text(
                            AppLocalizations.of(context).translate('yes'),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(MySize.size14!),
                        ),
                        Radio(
                          value: 'did_not_meet_contact',
                          groupValue: visitStatus,
                          onChanged: (String? value) {
                            setState(() {
                              visitStatus = value!;
                            });
                          },
                          toggleable: true,
                        ),
                        Padding(
                          padding: EdgeInsets.all(MySize.size6!),
                          child: Text(
                              AppLocalizations.of(context).translate('no')),
                        )
                      ],
                    ),
                    Visibility(
                      visible: (visitStatus == 'did_not_meet_contact'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${AppLocalizations.of(context).translate('reason')} : ",
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.subtitle1,
                              fontWeight: 600,
                              color: themeData.colorScheme.primaryVariant,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                top: MySize.size4!, bottom: MySize.size10!),
                            child: TextFormField(
                              controller: reasonController,
                              validator: (value) {
                                if (visitStatus == "did_not_meet_contact" &&
                                    reasonController.text.trim() == "") {
                                  return "${AppLocalizations.of(context).translate('please_provide_reason')}";
                                } else {
                                  return null;
                                }
                              },
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
                    ),
                    Row(
                      children: [
                        Text(
                          "${AppLocalizations.of(context).translate('take_photo_of_the_contact_or_visited_place')}",
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.bodyText1,
                            fontWeight: 600,
                            color: themeData.colorScheme.primaryVariant,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            await _imgFromCamera();
                          },
                          child: Text(
                            "${AppLocalizations.of(context).translate('choose_file')}",
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyText2,
                              fontWeight: 600,
                              color: themeData.colorScheme.onBackground,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Visibility(
                            visible: _image != null,
                            child: Padding(
                              padding: EdgeInsets.all(MySize.size4!),
                              child: Text(
                                (_image != null) ? "${_image!.name}" : '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "${AppLocalizations.of(context).translate('meet_with')} :* ",
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.subtitle1,
                            fontWeight: 600,
                            color: themeData.colorScheme.primaryVariant,
                          ),
                        )
                      ],
                    ),
                    ListView(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(vertical: MySize.size4!),
                          height: MySize.size60,
                          child: TextFormField(
                            controller: meetWith,
                            decoration: InputDecoration(
                              labelText:
                                  "${AppLocalizations.of(context).translate('name')}",
                              border: themeData.inputDecorationTheme.border,
                              enabledBorder:
                                  themeData.inputDecorationTheme.border,
                              focusedBorder:
                                  themeData.inputDecorationTheme.focusedBorder,
                            ),
                            validator: (value) {
                              if (meetWith.text.trim() == "") {
                                return "${AppLocalizations.of(context).translate('please_provide_meet_with')}";
                              } else {
                                return null;
                              }
                            },
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyText1,
                              fontWeight: 500,
                              color: themeData.colorScheme.onBackground,
                            ),
                          ),
                        ),
                        Container(
                            margin:
                                EdgeInsets.symmetric(vertical: MySize.size4!),
                            height: MySize.size60,
                            child: TextFormField(
                              controller: meetMobile,
                              decoration: InputDecoration(
                                labelText:
                                    "${AppLocalizations.of(context).translate('mobile_no')}",
                                border: themeData.inputDecorationTheme.border,
                                enabledBorder:
                                    themeData.inputDecorationTheme.border,
                                focusedBorder: themeData
                                    .inputDecorationTheme.focusedBorder,
                              ),
                              validator: (value) {
                                if (meetMobile.text.trim() == "") {
                                  return "${AppLocalizations.of(context).translate('please_provide_meet_with_mobile_no')}";
                                } else {
                                  return null;
                                }
                              },
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyText1,
                                fontWeight: 500,
                                color: themeData.colorScheme.onBackground,
                              ),
                            )),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: MySize.size4!),
                          height: MySize.size60,
                          child: TextFormField(
                            controller: meetDesignation,
                            decoration: InputDecoration(
                              labelText:
                                  "${AppLocalizations.of(context).translate('designation')}",
                              border: themeData.inputDecorationTheme.border,
                              enabledBorder:
                                  themeData.inputDecorationTheme.border,
                              focusedBorder:
                                  themeData.inputDecorationTheme.focusedBorder,
                            ),
                            validator: (value) {
                              if (meetDesignation.text.trim() == "") {
                                return "${AppLocalizations.of(context).translate('please_provide_designation')}";
                              } else {
                                return null;
                              }
                            },
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
                    ListTile(
                      leading: Icon(
                        (showMeet2)
                            ? MdiIcons.minusCircle
                            : MdiIcons.plusCircle,
                        color: themeData.colorScheme.primary,
                      ),
                      title: Text(
                          "${AppLocalizations.of(context).translate('add_meet')} 2"),
                      onTap: () {
                        setState(() {
                          showMeet2 = !showMeet2;
                        });
                      },
                    ),
                    Visibility(
                      visible: showMeet2,
                      child: ListView(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: [
                          Container(
                            margin:
                                EdgeInsets.symmetric(vertical: MySize.size4!),
                            height: MySize.size60,
                            child: TextFormField(
                              controller: meetWith2,
                              decoration: InputDecoration(
                                labelText:
                                    "${AppLocalizations.of(context).translate('name')}",
                                border: themeData.inputDecorationTheme.border,
                                enabledBorder:
                                    themeData.inputDecorationTheme.border,
                                focusedBorder: themeData
                                    .inputDecorationTheme.focusedBorder,
                              ),
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyText1,
                                fontWeight: 500,
                                color: themeData.colorScheme.onBackground,
                              ),
                            ),
                          ),
                          Container(
                              margin:
                                  EdgeInsets.symmetric(vertical: MySize.size4!),
                              height: MySize.size60,
                              child: TextFormField(
                                controller: meetMobile2,
                                decoration: InputDecoration(
                                  labelText:
                                      "${AppLocalizations.of(context).translate('mobile_no')}",
                                  border: themeData.inputDecorationTheme.border,
                                  enabledBorder:
                                      themeData.inputDecorationTheme.border,
                                  focusedBorder: themeData
                                      .inputDecorationTheme.focusedBorder,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.bodyText1,
                                  fontWeight: 500,
                                  color: themeData.colorScheme.onBackground,
                                ),
                              )),
                          Container(
                            margin:
                                EdgeInsets.symmetric(vertical: MySize.size4!),
                            height: MySize.size60,
                            child: TextFormField(
                              controller: meetDesignation2,
                              decoration: InputDecoration(
                                labelText:
                                    "${AppLocalizations.of(context).translate('designation')}",
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
                    ),
                    ListTile(
                      leading: Icon(
                        (showMeet3)
                            ? MdiIcons.minusCircle
                            : MdiIcons.plusCircle,
                        color: themeData.colorScheme.primary,
                      ),
                      title: Text(
                          "${AppLocalizations.of(context).translate('add_meet')} 3"),
                      onTap: () {
                        setState(() {
                          showMeet3 = !showMeet3;
                        });
                      },
                    ),
                    Visibility(
                      visible: (showMeet3),
                      child: ListView(
                        padding: EdgeInsets.symmetric(vertical: MySize.size8!),
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: [
                          Container(
                            margin:
                                EdgeInsets.symmetric(vertical: MySize.size4!),
                            height: MySize.size60,
                            child: TextFormField(
                              controller: meetWith3,
                              decoration: InputDecoration(
                                labelText:
                                    "${AppLocalizations.of(context).translate('name')}",
                                border: themeData.inputDecorationTheme.border,
                                enabledBorder:
                                    themeData.inputDecorationTheme.border,
                                focusedBorder: themeData
                                    .inputDecorationTheme.focusedBorder,
                              ),
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyText1,
                                fontWeight: 500,
                                color: themeData.colorScheme.onBackground,
                              ),
                            ),
                          ),
                          Container(
                              margin:
                                  EdgeInsets.symmetric(vertical: MySize.size4!),
                              height: MySize.size60,
                              child: TextFormField(
                                controller: meetMobile3,
                                decoration: InputDecoration(
                                  labelText:
                                      "${AppLocalizations.of(context).translate('mobile_no')}",
                                  border: themeData.inputDecorationTheme.border,
                                  enabledBorder:
                                      themeData.inputDecorationTheme.border,
                                  focusedBorder: themeData
                                      .inputDecorationTheme.focusedBorder,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.bodyText1,
                                  fontWeight: 500,
                                  color: themeData.colorScheme.onBackground,
                                ),
                              )),
                          Container(
                            margin:
                                EdgeInsets.symmetric(vertical: MySize.size4!),
                            height: MySize.size60,
                            child: TextFormField(
                              controller: meetDesignation3,
                              decoration: InputDecoration(
                                labelText:
                                    "${AppLocalizations.of(context).translate('designation')}",
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
                    ),
                    Row(
                      children: [
                        Text(
                          "${AppLocalizations.of(context).translate('visited_address')} : ",
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.subtitle1,
                            fontWeight: 600,
                            color: themeData.colorScheme.primaryVariant,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            //get current location
                            try {
                              await Geolocator.getCurrentPosition(
                                      desiredAccuracy: LocationAccuracy.high)
                                  .then((Position position) {
                                currentLoc = LatLng(
                                    position.latitude, position.longitude);
                                if (currentLoc != null) {
                                  setState(() {
                                    location =
                                        "longitude: ${currentLoc!.longitude.toString()},"
                                        " latitude: ${currentLoc!.latitude.toString()}";
                                  });
                                }
                              });
                            } catch (e) {}
                          },
                          icon: Icon(MdiIcons.mapMarker),
                          label: Text(
                              "${AppLocalizations.of(context).translate('get_current_location')}"),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$location',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${AppLocalizations.of(context).translate('discussions_with_the_contact')} : ",
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.subtitle1,
                            fontWeight: 600,
                            color: themeData.colorScheme.primaryVariant,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              top: MySize.size4!, bottom: MySize.size10!),
                          child: TextFormField(
                            controller: discussionController,
                            minLines: 2,
                            maxLines: 6,
                            decoration: InputDecoration(
                              border: themeData.inputDecorationTheme.border,
                              enabledBorder:
                                  themeData.inputDecorationTheme.border,
                              focusedBorder:
                                  themeData.inputDecorationTheme.focusedBorder,
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
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 48),
                          backgroundColor: themeData.colorScheme.primary,
                        ),
                        onPressed: () async {
                          bool validated = true;
                          String? placeImage;
                          if (await Helper().checkConnectivity()) {
                            if (visitStatus == "assigned") {
                              validated = false;
                              Fluttertoast.showToast(
                                  msg: AppLocalizations.of(context)
                                      .translate('please_enter_visit_status'));
                            }

                            if (_image == null) {
                              validated = false;
                              Fluttertoast.showToast(
                                  msg: AppLocalizations.of(context).translate(
                                      'please_upload_image_of_visited_place'));
                            } else {
                              File imageFile = new File(_image!.path);
                              List<int> imageBytes =
                                  imageFile.readAsBytesSync();
                              placeImage = base64Encode(imageBytes);
                            }

                            if (currentLoc == null) {
                              validated = false;
                              Fluttertoast.showToast(
                                  msg: AppLocalizations.of(context).translate(
                                      'please_add_current_location'));
                            }

                            if (_formKey.currentState!.validate() &&
                                validated) {
                              setState(() {
                                isLoading = true;
                              });
                              Map visitDetails = {
                                'status': '$visitStatus',
                                if (visitStatus == "did_not_meet_contact")
                                  'reason_to_not_meet_contact':
                                      reasonController.text,
                                'visited_on': DateFormat('yyyy-MM-dd HH:mm:ss')
                                    .format(DateTime.now()),
                                'meet_with': meetWith.text,
                                'meet_with_mobileno': meetMobile.text,
                                'meet_with_designation': meetDesignation.text,
                                'meet_with2': meetWith2.text,
                                'meet_with_mobileno2': meetMobile2.text,
                                'meet_with_designation2': meetDesignation2.text,
                                'meet_with3': meetWith3.text,
                                'meet_with_mobileno3': meetMobile3.text,
                                'meet_with_designation3': meetDesignation3.text,
                                'latitude': currentLoc!.latitude.toString(),
                                'longitude': currentLoc!.longitude.toString(),
                                'comments': discussionController.text,
                                'photo': placeImage
                              };
                              FieldForceApi()
                                  .update(visitDetails, widget.visit['id'])
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
                            AppLocalizations.of(context).translate('update'),
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
    );
  }

  //image from camera
  _imgFromCamera() async {
    XFile? image = await _picker.pickImage(
        source: ImageSource.camera); //, imageQuality: 50);
    setState(() {
      _image = image;
    });
  }
}

class FollowUpForm extends StatefulWidget {
  final Map<String, dynamic> customerDetails;
  final bool? edit;

  FollowUpForm(this.customerDetails, {this.edit});

  @override
  _FollowUpFormState createState() => _FollowUpFormState();
}

class _FollowUpFormState extends State<FollowUpForm> {
  List<String> statusList = ['scheduled', 'open', 'cancelled', 'completed'],
      followUpTypeList = ['call', 'sms', 'meeting', 'email'];
  List<Map<String, dynamic>> followUpCategory = [
    {'id': 0, 'name': 'Please select'}
  ];
  String selectedStatus = 'completed',
      selectedFollowUpType = 'call',
      duration = '';
  Map<String, dynamic> selectedFollowUpCategory = {
    'id': 0,
    'name': 'Please select'
  };

  bool showError = false;

  TextEditingController titleController = new TextEditingController(),
      startDateController = new TextEditingController(),
      endDateController = new TextEditingController(),
      descriptionController = new TextEditingController();

  final _formKey = GlobalKey<FormState>();

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    getFollowUpCategories();
  }

  onEditFollowUp() async {
    if (widget.edit == true) {
      setState(() {
        titleController.text = widget.customerDetails['title'];
        selectedStatus = widget.customerDetails['status'] ?? 'scheduled';
        selectedFollowUpType = widget.customerDetails['schedule_type'];
        startDateController.text = widget.customerDetails['start_datetime'];
        endDateController.text = widget.customerDetails['end_datetime'];
        descriptionController.text = widget.customerDetails['description'];
      });
      followUpCategory.forEach((element) {
        if (widget.customerDetails['followup_category'] != null &&
            element['id'] ==
                widget.customerDetails['followup_category']['id']) {
          setState(() {
            selectedFollowUpCategory = element;
          });
        }
      });
    }
  }

  getFollowUpCategories() async {
    await FollowUpApi().getFollowUpCategories().then((value) async {
      value.forEach((element) {
        followUpCategory.add({
          'id': int.parse(element['id'].toString()),
          'name': element['name']
        });
        setState(() {});
      });
      await onEditFollowUp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
            (widget.edit == true)
                ? "${AppLocalizations.of(context).translate('edit_follow_up')}"
                : "${AppLocalizations.of(context).translate('add_follow_up')}",
            style: themeData.appBarTheme.textTheme!.headline6),
      ),
      body: Container(
        height: MySize.screenHeight,
        padding: EdgeInsets.all(MySize.size12!),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  Text(
                    "${AppLocalizations.of(context).translate('customer_name')}:",
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.bodyText2,
                      fontWeight: 500,
                      color: themeData.colorScheme.onBackground,
                    ),
                  ),
                  Text(
                    widget.customerDetails['name'],
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.bodyText1,
                      fontWeight: 600,
                      color: themeData.colorScheme.onBackground,
                    ),
                  )
                ],
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: MySize.size16!),
                      child: TextFormField(
                        onEditingComplete: () {
                          FocusScope.of(context).unfocus();
                        },
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyText1,
                          fontWeight: 500,
                          color: themeData.colorScheme.onBackground,
                        ),
                        validator: (value) {
                          if (value!.trim().length < 1) {
                            return "${AppLocalizations.of(context).translate('title')} "
                                "${AppLocalizations.of(context).translate('required')}";
                          } else {
                            return null;
                          }
                        },
                        decoration: InputDecoration(
                          labelText:
                              "${AppLocalizations.of(context).translate('title')}:",
                          hintText:
                              "${AppLocalizations.of(context).translate('title')}",
                          border: themeData.inputDecorationTheme.border,
                          enabledBorder: themeData.inputDecorationTheme.border,
                          focusedBorder:
                              themeData.inputDecorationTheme.focusedBorder,
                        ),
                        controller: titleController,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: MySize.size16!),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${AppLocalizations.of(context).translate('status')}:",
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.bodyText2,
                                  fontWeight: 500,
                                  color: themeData.colorScheme.onBackground,
                                ),
                              ),
                              Container(
                                width: MySize.screenWidth! * 0.45,
                                child: DropdownButtonFormField(
                                  value: selectedStatus,
                                  dropdownColor: themeData.backgroundColor,
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: themeData.colorScheme.onBackground,
                                  ),
                                  items: statusList
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value,
                                            style: AppTheme.getTextStyle(
                                                themeData.textTheme.bodyText1,
                                                color: themeData.colorScheme
                                                    .onBackground)));
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      selectedStatus = newValue.toString();
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null)
                                      return "${AppLocalizations.of(context).translate('status')} "
                                          "${AppLocalizations.of(context).translate('required')}";
                                    else
                                      return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${AppLocalizations.of(context).translate('follow_up_type')}:",
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.bodyText2,
                                  fontWeight: 500,
                                  color: themeData.colorScheme.onBackground,
                                ),
                              ),
                              Container(
                                width: MySize.screenWidth! * 0.45,
                                child: DropdownButtonFormField(
                                  value: selectedFollowUpType,
                                  hint: Text(
                                    "${AppLocalizations.of(context).translate('please_select')}",
                                    style: AppTheme.getTextStyle(
                                      themeData.textTheme.bodyText1,
                                      fontWeight: 500,
                                      color: themeData.colorScheme.onBackground,
                                    ),
                                  ),
                                  dropdownColor: themeData.backgroundColor,
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: themeData.colorScheme.onBackground,
                                  ),
                                  items: followUpTypeList
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value,
                                            style: AppTheme.getTextStyle(
                                                themeData.textTheme.bodyText1,
                                                color: themeData.colorScheme
                                                    .onBackground)));
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      selectedFollowUpType =
                                          newValue.toString();
                                      if ((newValue.toString().toLowerCase() ==
                                              'call' &&
                                          selectedStatus == 'completed')) {
                                        // getCallLogDetails();
                                      } else {
                                        setState(() {
                                          showError = false;
                                        });
                                      }
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null)
                                      return "${AppLocalizations.of(context).translate('follow_up_type')} "
                                          "${AppLocalizations.of(context).translate('required')}";
                                    else
                                      return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: MySize.size16!),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${AppLocalizations.of(context).translate('follow_up_category')}:",
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyText2,
                              fontWeight: 500,
                              color: themeData.colorScheme.onBackground,
                            ),
                          ),
                          SizedBox(
                            // width: MySize.screenWidth! * 0.8,
                            child: DropdownButtonFormField(
                              value: (followUpCategory
                                      .contains(selectedFollowUpCategory))
                                  ? selectedFollowUpCategory
                                  : followUpCategory[0],
                              hint: Text(
                                "${AppLocalizations.of(context).translate('please_select')}",
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.bodyText1,
                                  fontWeight: 500,
                                  color: themeData.colorScheme.onBackground,
                                ),
                              ),
                              dropdownColor: themeData.backgroundColor,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: themeData.colorScheme.onBackground,
                              ),
                              items: followUpCategory
                                  .map<DropdownMenuItem<Map<String, dynamic>>>(
                                      (Map<String, dynamic> value) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                    value: value,
                                    child: Text(value['name'],
                                        style: AppTheme.getTextStyle(
                                            themeData.textTheme.bodyText1,
                                            color: themeData
                                                .colorScheme.onBackground)));
                              }).toList(),
                              onChanged: (Map<String, dynamic>? newValue) {
                                setState(() {
                                  selectedFollowUpCategory = newValue!;
                                });
                              },
                              validator: (value) {
                                if (selectedFollowUpCategory['id'] == 0)
                                  return "${AppLocalizations.of(context).translate('follow_up_category')} "
                                      "${AppLocalizations.of(context).translate('required')}";
                                else
                                  return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: MySize.size16!),
                      child: DateTimePicker(
                        controller: startDateController,
                        type: DateTimePickerType.dateTime,
                        firstDate: DateTime.now().subtract(Duration(days: 366)),
                        lastDate: DateTime.now().add(Duration(days: 180)),
                        dateMask: 'yyyy-MM-dd    hh:mm a',
                        dateLabelText:
                            "${AppLocalizations.of(context).translate('start_datetime')}:",
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyText1,
                          fontWeight: 500,
                          color: themeData.colorScheme.onBackground,
                        ),
                        onChanged: (val) {
                          setState(() {
                            startDateController.text = val;
                          });
                        },
                        validator: (value) {
                          if (value == '')
                            return "${AppLocalizations.of(context).translate('start_datetime')} "
                                "${AppLocalizations.of(context).translate('required')}";
                          else
                            return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: MySize.size16!),
                      child: DateTimePicker(
                        controller: endDateController,
                        type: DateTimePickerType.dateTime,
                        firstDate: DateTime.now().subtract(Duration(days: 366)),
                        lastDate: DateTime.now().add(Duration(days: 180)),
                        dateMask: 'yyyy-MM-dd    hh:mm a',
                        dateLabelText:
                            "${AppLocalizations.of(context).translate('end_datetime')}:",
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyText1,
                          fontWeight: 500,
                          color: themeData.colorScheme.onBackground,
                        ),
                        onChanged: (val) {
                          setState(() {
                            endDateController.text = val;
                          });
                        },
                        validator: (value) {
                          if (value == '')
                            return "${AppLocalizations.of(context).translate('end_datetime')} "
                                "${AppLocalizations.of(context).translate('required')}";
                          else
                            return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: MySize.size16!),
                      child: TextFormField(
                        minLines: 2,
                        maxLines: 6,
                        decoration: InputDecoration(
                          alignLabelWithHint: true,
                          labelText:
                              "${AppLocalizations.of(context).translate('description')}:",
                          hintText:
                              "${AppLocalizations.of(context).translate('description')}",
                          border: themeData.inputDecorationTheme.border,
                          enabledBorder: themeData.inputDecorationTheme.border,
                          focusedBorder:
                              themeData.inputDecorationTheme.focusedBorder,
                        ),
                        controller: descriptionController,
                        textCapitalization: TextCapitalization.sentences,
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyText1,
                          fontWeight: 500,
                          color: themeData.colorScheme.onBackground,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: MySize.size8!),
                      child: Visibility(
                        visible: showError,
                        child: Row(
                          children: [
                            Container(
                              width: MySize.screenWidth! * 0.7,
                              child: Text(
                                "${AppLocalizations.of(context).translate('call_log_not_found')}*",
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.subtitle2,
                                  fontWeight: 500,
                                  color: themeData.colorScheme.error,
                                ),
                              ),
                            ),
                            Helper().callDropdown(
                                context,
                                widget.customerDetails,
                                [
                                  widget.customerDetails['mobile'],
                                  widget.customerDetails['landline'],
                                  widget.customerDetails['alternate_number']
                                ],
                                type: 'call')
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: MySize.size8!),
                      child: ElevatedButton(
                          child: Text(
                            AppLocalizations.of(context).translate('submit'),
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyText1,
                              fontWeight: 600,
                              color: themeData.colorScheme.onPrimary,
                            ),
                          ),
                          onPressed: () async {
                            //form validation
                            if (selectedFollowUpType == 'call' &&
                                selectedStatus == 'completed') {
                              onSubmit();
                              // getCallLogDetails().then((value) async {
                              //   onSubmit();
                              // });
                            } else {
                              onSubmit();
                            }
                          }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //get call logs from mobile
//   getCallLogDetails() async {
//     List<CallLogEntry> logs = [
//       await FollowUpModel().getLogs(widget.customerDetails['mobile']),
//       await FollowUpModel().getLogs(widget.customerDetails['landline']),
//       await FollowUpModel().getLogs(widget.customerDetails['alternate_number'])
//     ];
// //sort callLogs with respective of highest timestamp(last dialed number)
//     logs.sort((a, b) =>
//         ((a != null) ? a.timestamp : 0)
//             .compareTo((b != null) ? b.timestamp : 0));
//     CallLogEntry lastLog = logs.last;
//
//     if (lastLog != null) {
//       // get last call duration of selected customer
//       setState(() {
//         startDateController.text =
//             DateTime.fromMillisecondsSinceEpoch(lastLog.timestamp)
//                 .subtract(Duration(seconds: lastLog.duration))
//                 .toString();
//         endDateController.text =
//             DateTime.fromMillisecondsSinceEpoch(lastLog.timestamp).toString();
//         showError = false;
//       });
//       duration =
//       '${Duration(seconds: lastLog.duration).toString().substring(2, 7)}';
//     } else {
//       setState(() {
//         showError = true;
//       });
//     }
//   }

  //on submit
  onSubmit() async {
    if (_formKey.currentState!.validate() && showError == false) {
      Map followUp = FollowUpModel().submitFollowUp(
          title: titleController.text,
          description: '${descriptionController.text}',
          contactId: widget.customerDetails['id'],
          followUpCategoryId: selectedFollowUpCategory['id'],
          endDate: endDateController.text,
          startDate: startDateController.text,
          duration: (duration != '') ? '$duration' : null,
          scheduleType: selectedFollowUpType,
          status: selectedStatus);
      int response = (widget.edit == true)
          ? await FollowUpApi()
              .update(followUp, widget.customerDetails['followUpId'])
          : await FollowUpApi().addFollowUp(followUp);
      if (response == 201 || response == 200) {
        Navigator.pop(context);
        (widget.edit == true)
            ? Navigator.pushReplacementNamed(context, '/followUp')
            : Navigator.pushReplacementNamed(context, '/leads');
      } else {
        Fluttertoast.showToast(
            msg:
                "${AppLocalizations.of(context).translate('something_went_wrong')}");
      }
    }
  }
}
