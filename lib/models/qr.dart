// import 'dart:typed_data';
// import 'dart:ui';
//
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:qr_flutter/qr_flutter.dart';
//
// import '../helpers/otherHelpers.dart';
// import '../locale/MyLocalizations.dart';
//
// class QR {
//   getQrData(
//       {context,
//       symbol,
//       businessName,
//       address,
//       taxLabel,
//       taxNumber,
//       invoiceNo,
//       date,
//       subTotal,
//       total,
//       tax,
//       discount,
//       customer}) {
//     String data = '';
//     if (businessName != null && businessName.toString().trim() != '') {
//       data +=
//           "${AppLocalizations.of(context).translate('business_name')}: $businessName";
//     }
//
//     if (address != null && address.toString().trim() != '') {
//       if (data != '') {
//         data += ',';
//       }
//       data +=
//           "${AppLocalizations.of(context).translate('address')}: ($address)";
//     }
//
//     if (taxLabel != null && taxLabel.toString().trim() != '') {
//       if (data != '') {
//         data += ',';
//       }
//       data += "$taxLabel $taxNumber";
//     }
//
//     if (invoiceNo != null && invoiceNo.toString().trim() != '') {
//       if (data != '') {
//         data += ',';
//       }
//       data +=
//           "${AppLocalizations.of(context).translate('invoice_no')}: $invoiceNo";
//     }
//
//     if (date != null && date.toString().trim() != '') {
//       if (data != '') {
//         data += ',';
//       }
//       data +=
//           "${AppLocalizations.of(context).translate('date')}: ${DateFormat("dd/MM/yyyy HH:mm:ss").format(date)}";
//     }
//
//     if (subTotal != null && subTotal.toString().trim() != '') {
//       if (data != '') {
//         data += ',';
//       }
//       data +=
//           "${AppLocalizations.of(context).translate('sub_total')}: $symbol ${Helper().formatCurrency(subTotal)}";
//     }
//
//     if (total != null && total.toString().trim() != '') {
//       if (data != '') {
//         data += ',';
//       }
//       data +=
//           "${AppLocalizations.of(context).translate('total')}: $symbol ${Helper().formatCurrency(total)}";
//     }
//
//     if (tax != null && tax.toString().trim() != '') {
//       if (data != '') {
//         data += ',';
//       }
//       data +=
//           "${AppLocalizations.of(context).translate('tax')}: $symbol ${Helper().formatCurrency(tax)}";
//     }
//
//     if (discount != null && discount.toString().trim() != '') {
//       if (data != '') {
//         data += ',';
//       }
//       data +=
//           "${AppLocalizations.of(context).translate('discount')}: $symbol ${Helper().formatCurrency(discount)}";
//     }
//
//     if (customer != null && customer.toString().trim() != '') {
//       if (data != '') {
//         data += ',';
//       }
//       data +=
//           "${AppLocalizations.of(context).translate('customer')}: $customer";
//     }
//     print(data);
//     return toQrImageData(data);
//   }
//
//   Future<Uint8List> toQrImageData(String text) async {
//     try {
//       final image = await QrPainter(
//         data: text,
//         version: QrVersions.auto,
//         gapless: false,
//         color: Colors.black,
//         emptyColor: Color(0xffffff),
//       ).toImage(100);
//       final a = await image.toByteData(format: ImageByteFormat.png);
//       return a!.buffer.asUint8List();
//     } catch (e) {
//       throw e;
//     }
//   }
// }
