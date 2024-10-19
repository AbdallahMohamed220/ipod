import 'dart:ui';
//import 'package:google_maps_flutter/google_maps_flutter.dart';

class Config {
  //static String baseUrl = 'https://devxpos.idiib.com/';
  //static String baseUrl = 'https://quixcelerp.com/';
  static String baseUrl = 'http://pm.quixcelerp.com/';
  static int? userId;
  String clientId = '16',
      //clientSecret = 'lDzqLvBHjrGSKPqV8MVTzPsc09cLkT2MA8pGYWL5',
      clientSecret = 'B4UNLqT18Os4CFcwLNvK2NQQHeShD5LVxkTbkbPO',
      copyright = '\u00a9',
      appName = 'pos',
      version = 'V 2.0',
      splashScreen = '${Config.baseUrl}uploads/mobile/welcome.jpg',
      loginScreen = '${Config.baseUrl}uploads/mobile/login.jpg',
      noDataImage = '${Config.baseUrl}uploads/mobile/no_data.jpg',
      defaultBusinessImage = '${Config.baseUrl}uploads/business_default.jpg';
  final bool syncCallLog = false, showRegister = false, showFieldForce = false;

  //quantity precision       //currency precision   //call_log sync duration
  static int quantityPrecision = 2,
      currencyPrecision = 2,
      callLogSyncDuration = 10;

  //List of locale language code
  List locale = ['en', 'ar', 'de', 'fr', 'es', 'tr', 'id', 'my'];
  String defaultLanguage = 'en';

  //List of locales included
  List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('ar', ''),
    Locale('de', ''),
    Locale('fr', ''),
    Locale('es', ''),
    Locale('tr', ''),
    Locale('id', ''),
    Locale('my', '')
  ];

  //dropdown items for changing language
  List<Map<String, dynamic>> lang = [
    {'languageCode': 'en', 'countryCode': 'US', 'name': 'English'},
    {'languageCode': 'ar', 'countryCode': '', 'name': 'العربي'},
    {'languageCode': 'de', 'countryCode': '', 'name': 'Deutsche'},
    {'languageCode': 'fr', 'countryCode': '', 'name': 'Français'},
    {'languageCode': 'es', 'countryCode': '', 'name': 'Española'},
    {'languageCode': 'tr', 'countryCode': '', 'name': 'Türkçe'},
    {'languageCode': 'id', 'countryCode': '', 'name': 'Indonesian'},
    {'languageCode': 'my', 'countryCode': '', 'name': 'မြန်မာ'}
  ];

  //final initialPosition = LatLng(20.46752985010792, 82.92005813910752);
  final String googleAPIKey = 'YOUR_GOOGLE_API_KEY';
}
