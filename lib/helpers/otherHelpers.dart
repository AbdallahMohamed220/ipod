import 'dart:math';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:cached_network_image/cached_network_image.dart';

// import 'package:call_log/call_log.dart';
import 'package:connectivity/connectivity.dart';
import 'package:cron/cron.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../locale/MyLocalizations.dart';
import '../models/invoice.dart';
import '../models/system.dart';
import 'AppTheme.dart';
import 'SizeConfig.dart';

class Helper {
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  Widget loadingIndicator(context) {
    return Center(
      child: Card(
        elevation: MySize.size10,
        child: Container(
          padding: EdgeInsets.all(MySize.size28!),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MySize.size8!),
          ),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  //format currency
  String formatCurrency(amount) {
    double convertAmount = double.parse(amount.toString());

    var amt = NumberFormat.currency(
            symbol: '', decimalDigits: Config.currencyPrecision)
        .format(convertAmount);
    return amt;
  }

  double validateInput(String val) {
    try {
      double value = double.parse(val.toString());
      return value;
    } catch (e) {
      return 0.00;
    }
  }

  //format quantity
  String formatQuantity(amount) {
    double quantity = double.parse(amount.toString());
    var amt = NumberFormat.currency(
            symbol: '', decimalDigits: Config.quantityPrecision)
        .format(quantity);
    return amt;
  }

  //argument model
  Map argument(
      {int? sellId,
      int? locId,
      int? taxId,
      String? discountType,
      double? discountAmount,
      double? invoiceAmount,
      int? customerId,
      int? isQuotation}) {
    Map args = {
      'sellId': sellId,
      'locationId': locId,
      'taxId': taxId,
      'discountType': discountType,
      'discountAmount': discountAmount,
      'invoiceAmount': invoiceAmount,
      'customerId': customerId,
      'is_quotation': isQuotation
    };
    return args;
  }

  //check internet connectivity
  Future<bool> checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      return true;
    } else {
      return false;
    }
  }

  //get location name by location_id
  Future<String?> getLocationNameById(var id) async {
    String? locationName;
    var response = await System().get('location');
    response.forEach((element) {
      if (element['id'] == int.parse(id.toString())) {
        locationName = element['name'];
      }
    });
    return locationName;
  }

  //calculate inline tax and discount amount
  calculateTaxAndDiscount(
      {discountAmount, discountType, taxId, unitPrice}) async {
    double disAmt = 0.0, tax = 0.00, taxAmt = 0.00;
    await System().get('tax').then((value) {
      value.forEach((element) {
        if (element['id'] == taxId) {
          tax = double.parse(element['amount'].toString()) * 1.0;
        }
      });
    });

    if (discountType == 'fixed') {
      disAmt = discountAmount;
      taxAmt = ((unitPrice - discountAmount) * tax / 100);
    } else {
      disAmt = (unitPrice * discountAmount / 100);
      taxAmt = ((unitPrice - (unitPrice * discountAmount / 100)) * tax / 100);
    }
    return {'discountAmount': disAmt, 'taxAmount': taxAmt};
  }

  //calculate price including tax
  calculateTotal({unitPrice, discountType, discountAmount, taxId}) async {
    double tax = 0.00;
    double subTotal = 0.00;
    double amount = 0.0;
    unitPrice = double.parse(unitPrice.toString());
    discountAmount = double.parse(discountAmount.toString());
    //set tax
    await System().get('tax').then((value) {
      value.forEach((element) {
        if (element['id'] == taxId) {
          tax = double.parse(element['amount'].toString()) * 1.0;
        }
      });
    });
    //calculate subTotal according to discount type
    if (discountType == 'fixed') {
      amount = unitPrice - discountAmount;
    } else {
      amount = unitPrice - (unitPrice * discountAmount / 100);
    }
    //calculate subtotal
    subTotal = (amount + (amount * tax / 100));
    return subTotal.toStringAsFixed(2);
  }

  Future<String> barcodeScan() async {
    var result = await BarcodeScanner.scan();
    return result.rawContent.trimRight();
  }

  //function for formatting invoice
  Future<void> printDocument(sellId, taxId, context, {invoice}) async {
    String _invoice = (invoice != null)
        ? invoice
        : await InvoiceFormatter().generateInvoice(sellId, taxId, context);
    Printing.layoutPdf(onLayout: (pageFormat) async {
      final doc = pw.Document();
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => await Printing.convertHtml(
                format: format,
                html: _invoice,
              ));

      return doc.save();
    });
  }

  // //request permissions
  requestAppPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.storage,
      Permission.camera,
      // Permission.phone
    ].request();
    return statuses;
  }

  //job scheduler
  jobScheduler() {
    if (Config().syncCallLog) {
      final cron = Cron();
      cron.schedule(Schedule.parse('*/${Config.callLogSyncDuration} * * * *'),
          () async {
        syncCallLogs();
      });
    }
  }

  //post call_logs in api
  syncCallLogs() async {
    if (await Permission.phone.status == PermissionStatus.granted) {
      if (Config().syncCallLog && await Helper().checkConnectivity()) {
        // ignore: unused_local_variable
        List recentLogs = [];
        //get last sync time
        var lastSync = await System().callLogLastSyncDateTime();
        //difference between time now and last sync
        int getLogBefore = (lastSync != null)
            ? DateTime.now().difference(DateTime.parse(lastSync)).inMinutes
            : 1440;
        //set 'from' duration for call_log query
        // ignore: unused_local_variable
        int from = DateTime.now()
            .subtract(
                Duration(minutes: (getLogBefore > 1440) ? 1440 : getLogBefore))
            .millisecondsSinceEpoch;
        try {
          // //fetch call_log
          // await CallLog.query(dateFrom: from).then((value) async {
          //   if (value.isNotEmpty) {
          //     value.forEach((element) {
          //       recentLogs.add(CallLogModel().createLog(element));
          //     });
          //     //     //save call_log in api
          //     await FollowUpApi()
          //         .syncCallLog({'call_logs': recentLogs}).then((value) async {
          //       if (value == true) {
          //         System().callLogLastSyncDateTime(true);
          //       }
          //     });
          //   }
          // });
        } catch (e) {}
      }
    }
  }

  //share invoice
  savePdf(sellId, taxId, context, invoiceNo, {invoice}) async {
    String _invoice = (invoice != null)
        ? invoice
        : await InvoiceFormatter().generateInvoice(sellId, taxId, context);
    var targetPath = await getTemporaryDirectory();
    var targetFileName = "invoice_no: ${Random().nextInt(100)}";

    var generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
        _invoice, targetPath.path, targetFileName);

    await Share.shareFiles([generatedPdfFile.path]);
    //to get file path use generatedPdfFile.path
  }

  //fetch formatted business details
  Future<Map<String, dynamic>> getFormattedBusinessDetails() async {
    List business = await System().get('business');
    String? symbol = business[0]['currency']['symbol'],
        name = business[0]['name'],
        logo = business[0]['logo'],
        taxLabel = business[0]['tax_label_1'],
        taxNumber = business[0]['tax_number_1'];
    int? currencyPrecision = business[0]['currency_precision'],
        quantityPrecision = business[0]['quantity_precision'];
    return {
      'symbol': symbol ?? '',
      'name': name ?? '',
      'logo': logo ?? Config().defaultBusinessImage,
      'currencyPrecision': currencyPrecision ?? Config.currencyPrecision,
      'quantityPrecision': quantityPrecision ?? Config.quantityPrecision,
      'taxLabel': (taxLabel != null) ? '$taxLabel : ' : '',
      'taxNumber': (taxNumber != null) ? '$taxNumber' : ''
    };
  }

  //Fetch permission from database
  Future<bool> getPermission(String permissionFor) async {
    bool permission = false;
    await System().getPermission().then((value) {
      if (value[0] == 'all' || value.contains("$permissionFor")) {
        permission = true;
      }
    });
    return permission;
  }

  //call widget
  Widget callDropdown(context, followUpDetails, List numbers,
      {required String type}) {
    numbers.removeWhere((element) => element.toString() == 'null');
    return Container(
      height: MySize.size36,
      child: PopupMenuButton<String>(
        icon: Icon(
          (type == 'call') ? MdiIcons.phone : MdiIcons.whatsapp,
          color:
              (type == 'call') ? themeData.colorScheme.primary : Colors.green,
        ),
        onSelected: (value) async {
          if (type == 'call') {
            await launch('tel:$value');
          }

          if (type == 'whatsApp') {
            await launch("https://wa.me/$value");
          }
        },
        itemBuilder: (BuildContext context) {
          return numbers.map((item) {
            return PopupMenuItem<String>(
              value: item,
              child: Text(
                '$item',
                style: TextStyle(color: Colors.black),
              ),
            );
          }).toList();
        },
      ),
    );
  }

  //noData widget
  noDataWidget(context) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: CachedNetworkImage(
            imageUrl: Config().noDataImage,
            errorWidget: (context, url, error) =>
                Image.asset('assets/images/noData.png'),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            AppLocalizations.of(context).translate('no_data'),
            style: AppTheme.getTextStyle(
              themeData.textTheme.headline5,
              fontWeight: 600,
              color: themeData.colorScheme.onBackground,
            ),
          ),
        )
      ],
    );
  }
}
