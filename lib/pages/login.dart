import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../apis/api.dart';
import '../apis/system.dart';
import '../apis/user.dart';
import '../config.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/contact_model.dart';
import '../models/database.dart';
import '../models/sellDatabase.dart';
import '../models/system.dart';
import '../models/variations.dart';

// ignore: non_constant_identifier_names
int? USERID;

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);

  final _formKey = GlobalKey<FormState>();
  Timer? timer;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    timer!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(0),
          children: <Widget>[
            Container(
              height: MediaQuery.of(context).size.height * 3 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  FittedBox(
                    fit: BoxFit.fill,
                    child: CachedNetworkImage(
                      imageUrl: Config().loginScreen,
                      placeholder: (context, url) => Transform.scale(
                        scale: 0.07,
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) =>
                          Image.asset('assets/images/login.jpg'),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Stack(
                      children: <Widget>[
                        // Stroked text as border.
                        Text(
                          AppLocalizations.of(context).translate('login'),
                          style: TextStyle(
                            fontSize: 40,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 4
                              ..color = Colors.blue,
                          ),
                        ),
                        // Solid text as fill.
                        Text(
                          AppLocalizations.of(context).translate('login'),
                          style: TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Form(
              key: _formKey,
              child: Container(
                margin: EdgeInsets.only(
                    left: MySize.size16!,
                    right: MySize.size16!,
                    top: MySize.size16!),
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: MySize.size12!,
                        left: MySize.size16!,
                        right: MySize.size16!,
                        bottom: MySize.size12!),
                    child: Column(children: <Widget>[
                      TextFormField(
                        style: AppTheme.getTextStyle(
                            themeData.textTheme.bodyLarge,
                            letterSpacing: 0.1,
                            color: themeData.colorScheme.onBackground,
                            fontWeight: 500),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)
                              .translate('username'),
                          hintStyle: AppTheme.getTextStyle(
                              themeData.textTheme.titleSmall,
                              letterSpacing: 0.1,
                              color: themeData.colorScheme.onBackground,
                              fontWeight: 500),
                          prefixIcon: Icon(MdiIcons.emailOutline),
                        ),
                        controller: usernameController,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return AppLocalizations.of(context)
                                .translate('please_enter_username');
                          }
                          return null;
                        },
                        autofocus: true,
                      ),
                      Container(
                        margin: EdgeInsets.only(top: MySize.size16!),
                        child: TextFormField(
                          keyboardType: TextInputType.visiblePassword,
                          style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyLarge,
                              letterSpacing: 0.1,
                              color: themeData.colorScheme.onBackground,
                              fontWeight: 500),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)
                                .translate('password'),
                            hintStyle: AppTheme.getTextStyle(
                                themeData.textTheme.titleSmall,
                                letterSpacing: 0.1,
                                color: themeData.colorScheme.onBackground,
                                fontWeight: 500),
                            prefixIcon: Icon(MdiIcons.lockOutline),
                            suffixIcon: IconButton(
                              icon: Icon(_passwordVisible
                                  ? MdiIcons.eyeOutline
                                  : MdiIcons.eyeOffOutline),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                          obscureText: !_passwordVisible,
                          controller: passwordController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return AppLocalizations.of(context)
                                  .translate('please_enter_password');
                            }
                            return null;
                          },
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: MySize.size16!),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.all(Radius.circular(MySize.size24!)),
                          boxShadow: [
                            BoxShadow(
                              color: themeData.colorScheme.primary,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: themeData.colorScheme.primary,
                              padding: EdgeInsets.only(
                                  left: MySize.size64!,
                                  right: MySize.size64!,
                                  top: MySize.size10!,
                                  bottom: MySize.size10!),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(MySize.size24!)),
                            ),
                            child: Text(
                                isLoading
                                    ? AppLocalizations.of(context)
                                        .translate('loading')
                                    : AppLocalizations.of(context)
                                        .translate('login'),
                                style: AppTheme.getTextStyle(
                                    themeData.textTheme.labelLarge,
                                    fontWeight: 600,
                                    color: themeData.colorScheme.onPrimary,
                                    letterSpacing: 0.5)),
                            onPressed: () async {
                              if (await Helper().checkConnectivity()) {
                                if (_formKey.currentState!.validate() &&
                                    !isLoading) {
                                  setState(() {
                                    isLoading = true;
                                  });

                                  Map? loginResponse = await Api().login(
                                      usernameController.text,
                                      passwordController.text);

                                  print(loginResponse);

                                  if (loginResponse!['success']) {
                                    //schedule job for syncing callLogs
                                    Helper().jobScheduler();
                                    //Get current logged in user details and save it.

                                    showLoadingDialogue();
                                    await loadAllData(loginResponse, context);
                                    Navigator.of(context).pop();

                                    //Take to home page
                                    Navigator.of(context).pushNamed('/home');
                                  } else {
                                    setState(() {
                                      isLoading = false;
                                    });

                                    Fluttertoast.showToast(
                                        msg: AppLocalizations.of(context)
                                            .translate('invalid_credentials'));
                                  }
                                }
                              }
                            }),
                      ),
                    ]),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  loadAllData(loginResponse, context) async {
    timer = Timer.periodic(Duration(seconds: 30), (Timer t) {
      (context != null)
          ? Fluttertoast.showToast(
              msg: AppLocalizations.of(context)
                  .translate('It_may_take_some_more_time_to_load'))
          : t.cancel();
      t.cancel();
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map loggedInUser = await User().get(loginResponse['access_token']);

    USERID = loggedInUser['id'];
    Config.userId = USERID;
    //saving userId in disk
    prefs.setInt('userId', USERID!);
    DbProvider().initializeDatabase(loggedInUser['id']);

    String? lastSync = await System().getProductLastSync();
    final date2 = DateTime.now();

    //delete system table before saving data
    System().empty();
    //delete contact table
    Contact().emptyContact();
    //save user details
    await System().insertUserDetails(loggedInUser);
    //Insert token
    System().insertToken(loginResponse['access_token']);
    //save system data
    await SystemApi().store();
    await System().insertProductLastSyncDateTimeNow();
    //check previous userId
    if (prefs.getInt('prevUserId') == null ||
        prefs.getInt('prevUserId') != prefs.getInt('userId')) {
      SellDatabase().deleteSellTables();
      await Variations().refresh();
    } else {
      //save variations if last sync is greater than 10hrs
      if (lastSync == null ||
          (date2.difference(DateTime.parse(lastSync)).inHours > 10)) {
        if (await Helper().checkConnectivity()) {
          await Variations().refresh();
          await System().insertProductLastSyncDateTimeNow();
          SellDatabase().deleteSellTables();
        }
      }
    }
    //Take to home page
    Navigator.of(context).pushReplacementNamed('/home');
    Navigator.of(context).pop();
  }

  Future<void> showLoadingDialogue() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              Container(
                  margin: EdgeInsets.only(left: 5),
                  child: Text(
                      AppLocalizations.of(context).translate('loading_data'))),
            ],
          ),
        );
      },
    );
  }
}
