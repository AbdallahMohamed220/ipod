import 'package:flutter/material.dart';

import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/style.dart' as style;
import '../locale/MyLocalizations.dart';

Widget posBottomBar(page, context, [call]) {
  ThemeData themeData = AppTheme.getThemeFromThemeMode(1);
  return Material(
    elevation: 0,
    child: Container(
      color: themeData.colorScheme.onPrimary,
      height: MySize.size56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          bottomBarMenu(
              context,
              '/home',
              AppLocalizations.of(context).translate('home'),
              page == "home",
              Icons.home,
              true),
          bottomBarMenu(
              context,
              '/products',
              AppLocalizations.of(context).translate('products'),
              page == "products",
              Icons.shop_two,
              true),
          bottomBarMenu(
              context,
              '/sale',
              AppLocalizations.of(context).translate('sales'),
              page == "sale",
              Icons.list,
              true),
        ],
      ),
    ),
  );
}

Widget bottomBarMenu(context, route, name, isSelected, icon,
    [replace, arguments]) {
  replace = (replace == null) ? false : replace;
  return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? style.StyleColors().mainColor(1) : null,
        shape: isSelected
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(40.0))
            : null,
      ),
      onPressed: () {
        if (replace)
          Navigator.pushReplacementNamed(context, route, arguments: arguments);
        else
          Navigator.pushNamed(context, route, arguments: arguments);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Icon(
            icon,
            color: (!isSelected)
                ? Colors.grey
                : Theme.of(context).colorScheme.surface,
          ),
          (isSelected)
              ? Padding(
            padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    name,
                    style: AppTheme.getTextStyle(
                        Theme.of(context).textTheme.bodyText1,
                        color: Theme.of(context).colorScheme.surface),
                  ),
                )
              : Container()
        ],
      ));
}

Widget cartBottomBar(route, name, context, [nextArguments]) {
  ThemeData themeData = AppTheme.getThemeFromThemeMode(1);
  //TODO: add some shadows.
  return Material(
    child: Container(
      color: themeData.colorScheme.onPrimary,
      height: 55,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          bottomBarMenu(context, route, name, true, Icons.arrow_forward, false,
              nextArguments),
        ],
      ),
    ),
  );
}

//syncAlert
syncing(time, context) {
  AlertDialog alert = AlertDialog(
    content: Row(
      children: [
        CircularProgressIndicator(),
        Container(
            margin: EdgeInsets.only(left: 5),
            child: Text("Sync in progress...")),
      ],
    ),
  );
  showDialog(
    barrierDismissible: true,
    context: context,
    builder: (BuildContext context) {
      Future.delayed(Duration(seconds: time), () {
        Navigator.of(context).pop(true);
      });
      return alert;
    },
  );
}
