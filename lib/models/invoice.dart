import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';

import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/paymentDatabase.dart';
import '../models/qr.dart';
import '../models/sellDatabase.dart';
import '../models/system.dart';
import 'contact_model.dart';

class InvoiceFormatter {
  double subTotal = 0;
  var taxName = 'taxRates';
  double inlineDiscountAmount = 0.0, inlineTaxAmount = 0.0, tax = 0;

  Future<String> generateProductDetails(sellId, context) async {
    //fetch products from sellLine by sellId
    List products = await SellDatabase().get(sellId: sellId);
    String product = '''
          <tr class="bb-lg">
               
               <th width="30%">
                     <p>${AppLocalizations.of(context).translate('products')}</p>
               </th>
               
               <th width="20%">
                     <p>${AppLocalizations.of(context).translate('quantity')}</p>
               </th>
               
               <th width="20%">
                     <p>${AppLocalizations.of(context).translate('unit_price')}</p>
               </th>
               
               <th width="20%">
                     <p>${AppLocalizations.of(context).translate('sub_total')}</p>
               </th>
               
            </tr>
    ''';
    subTotal = 0.00;
    for (int i = 0; i < products.length; i++) {
      String serialNumber = (i + 1).toString();
      String productName = products[i]['name'];
      String productSku = products[i]['sub_sku'];
      String productQuantity = products[i]['quantity'].toString();
      Map<String, dynamic> inlineAmounts = await Helper()
          .calculateTaxAndDiscount(
              discountAmount: products[i]['discount_amount'],
              discountType: products[i]['discount_type'],
              unitPrice: products[i]['unit_price'],
              taxId: products[i]['tax_rate_id']);
      inlineDiscountAmount += inlineAmounts['discountAmount'];
      inlineTaxAmount += inlineAmounts['taxAmount'];
      String productPrice = await Helper().calculateTotal(
          taxId: products[i]['tax_rate_id'],
          discountAmount: products[i]['discount_amount'],
          discountType: products[i]['discount_type'],
          unitPrice: products[i]['unit_price']);
      String totalProductsPrice =
          (products[i]['quantity'] * double.parse(productPrice)).toString();
      subTotal += double.parse(totalProductsPrice);
      product = product +
          '''
          <tr class="bb-lg">
          
               <td width="30%">               
                     <p>$productName, $productSku</p>
               </td>
               
               
               <td  width="20%">               
                     <p>${Helper().formatQuantity(productQuantity)}</p>
               </td>
               
               
               <td width="20%">               
                     <p>${Helper().formatCurrency(productPrice)}</p>
               </td>
               
               <td width="20%">               
                     <p>${Helper().formatCurrency(totalProductsPrice)}</p>
               </td>
               
            </tr>
    ''';
    }
    return product;
  }

  setTax(taxId) {
    System().get('tax').then((value) {
      value.forEach((element) {
        if (element['id'] == taxId) {
          taxName = element['name'];
          tax = double.parse(element['amount'].toString());
        }
      });
    });
  }

  Map<String, dynamic> getTotalAmount(
      {required String discountType,
      required double discountAmount,
      required String symbol}) {
    Map<String, dynamic> allAmounts = {};
    if (discountType == "fixed") {
      discountType = "$symbol $discountAmount";
      String tAmount = (subTotal - discountAmount).toString();
      allAmounts['taxAmount'] = Helper().formatCurrency(
          (double.parse(tAmount) * (tax / 100)).toStringAsFixed(2));
      allAmounts['totalAmount'] =
          (double.parse(tAmount) + double.parse(allAmounts['taxAmount']))
              .toString();
      allAmounts['discountAmount'] = discountAmount;
      allAmounts['discountType'] = discountType;
    } else if (discountType == "percentage") {
      discountType = discountAmount.toString() + " %";
      discountAmount = subTotal * (discountAmount / 100);
      String tAmount = (subTotal - discountAmount).toString();
      allAmounts['taxAmount'] = Helper().formatCurrency(
          (double.parse(tAmount) * (tax / 100)).toStringAsFixed(2));
      allAmounts['totalAmount'] =
          (double.parse(tAmount) + double.parse(allAmounts['taxAmount']))
              .toStringAsFixed(2);
      allAmounts['discountAmount'] = discountAmount;
      allAmounts['discountType'] = discountType;
    }
    return allAmounts;
  }

  Future<String> generateInvoice(sellId, taxId, context) async {
    var symbol = '';
    var businessName = '';
    String taxHtml = '';
    String inlineTaxesHtml = '';
    String inlineDiscountHtml = '';
    String discountHtml = '';
    String dueHtml = '';
    String shippingHtml = '';
    String taxLabel = '';
    String taxNumber = '';
    setTax(taxId);
    String products = await generateProductDetails(sellId, context);
    List sells = await SellDatabase().getSellBySellId(sellId);
    var customer =
        await Contact().getCustomerDetailById(sells[0]['contact_id']);
    var landmark = '',
        city = '',
        state = '',
        zipCode = '',
        country = '',
        businessMobile = '';
    List locations = await System().get('location');
    var location;
    locations.forEach((element) {
      if (element['id'] == sells[0]['location_id']) {
        location = element;
        landmark =
            (location['landmark'] != null) ? location['landmark'] + ',' : '';
        city = (location['city'] != null) ? location['city'] + ',' : '';
        state = (location['state'] != null) ? location['state'] + ',' : '';
        zipCode =
            (location['zip_code'] != null) ? location['zip_code'] + ',' : '';
        country =
            (location['country'] != null) ? location['country'] + ',' : '';
        businessMobile =
            (location['mobile'] != null) ? location['mobile'] + ',' : '';
      }
    });
    String invoiceNo = sells[0]['invoice_no'];
    var dateTime = DateTime.parse(sells[0]['transaction_date']);
    var date = DateFormat("dd/MM/yyyy").format(dateTime);
    var discountType = sells[0]['discount_type'];
    var discountAmount = sells[0]['discount_amount'];
    await Helper().getFormattedBusinessDetails().then((value) {
      symbol = value['symbol'];
      businessName = value['name'];
      taxLabel = value['taxLabel'];
      taxNumber = value['taxNumber'];
    });
    var customerName = customer['name'];
    var customerAddress1 = (customer['address_line_1'] != null)
        ? customer['address_line_1'] + ','
        : '';
    var customerAddress2 = (customer['address_line_2'] != null)
        ? customer['address_line_2'] + ','
        : '';
    var customerCity = (customer['city'] != null) ? customer['city'] + ',' : '';
    var customerState =
    (customer['state'] != null) ? customer['state'] + ',' : '';
    var customerCountry =
    (customer['country'] != null) ? customer['country'] : '';
    var customerMobile = customer['mobile'];
    List paymentList =
    await PaymentDatabase().get(sells[0]['id'], allColumns: true);
    double totalPaidAmount = 0.0;
    String payments = '';
    paymentList.forEach((element) {
      var sign;
      if (element['is_return'] == 0) {
        sign = '+';
        totalPaidAmount += element['amount'];
      } else {
        sign = '-';
        totalPaidAmount -= element['amount'];
      }
      var method = element['method'];
      var paidAmount = element['amount'];
      if (element['amount'] > 0) {
        payments += '''
        <div class="flex-box">
         <p class="width-50 text-left">$method ($sign) ($date) </p>
         <p class="width-50 text-right">$symbol ${Helper().formatCurrency(paidAmount)}</p>
      </div>
      ''';
      }
    });

    Map<String, dynamic> getAmounts = getTotalAmount(
        discountType: discountType,
        discountAmount: discountAmount,
        symbol: symbol);

    discountAmount = getAmounts['discountAmount'];
    discountType = getAmounts['discountType'];
    String taxAmount = getAmounts['taxAmount'];
    String totalAmount =
        (double.parse(getAmounts['totalAmount']) + sells[0]['shipping_charges'])
            .toStringAsFixed(2);
    String sTotal = subTotal.toString();
    var totalReceived;
    var returnAmount;
    var dueAmount;
    if (totalPaidAmount > double.parse(totalAmount)) {
      returnAmount = totalPaidAmount - double.parse(totalAmount);
      totalReceived = totalAmount;
      dueAmount = 0.00;
    } else if (double.parse(totalAmount) > totalPaidAmount) {
      dueAmount = double.parse(totalAmount) - totalPaidAmount;
      returnAmount = 0.00;
    } else {
      dueAmount = 0.00;
      returnAmount = 0.00;
    }
    returnAmount = Helper().formatCurrency(returnAmount);
    totalAmount = Helper().formatCurrency(totalAmount);
    totalReceived = Helper().formatCurrency(totalPaidAmount);

    //structure of discount row
    if (discountAmount > 0) {
      discountAmount = Helper().formatCurrency(discountAmount);
      discountHtml = '''
      <div class="flex-box">
         <p class="width-50 text-left">
            ${AppLocalizations.of(context).translate('discount')} <small>($discountType)</small> :
         </p>
         <p class="width-50 text-right">
            (-) $symbol $discountAmount
         </p>
      </div>
      ''';
    }

    //structure of inline discount row
    if (inlineDiscountAmount > 0) {
      String inlineDiscount = Helper().formatCurrency(inlineDiscountAmount);
      inlineDiscountHtml = '''
      <div class="flex-box">
         <p class="width-50 text-left">
            ${AppLocalizations.of(context).translate('discount')} :
         </p>
         <p class="width-50 text-right">
            (-) $symbol $inlineDiscount
         </p>
      </div>
      ''';
    }

    //structure of shippingCharge row
    if (sells[0]['shipping_charges'] >= 0.01) {
      shippingHtml += '''
      <div class="flex-box">
         <p class="width-50 text-left">
            ${AppLocalizations.of(context).translate('shipping_charges')}:
         </p>
         <p class="width-50 text-right">
            $symbol ${Helper().formatCurrency(sells[0]['shipping_charges'])}
         </p>
      </div>
      ''';
    }

    //structure of tax row
    if (taxName != "taxRates") {
      taxHtml = '''
      <div class="flex-box">
         <p class="width-50 text-left">
            ${AppLocalizations.of(context).translate('tax')} ($taxName):
         </p>
         <p class="width-50 text-right">
            (+) $symbol $taxAmount
         </p>
      </div>
      ''';
    }

    //structure of inline tax row
    if (inlineTaxAmount > 0) {
      String inlineTax = Helper().formatCurrency(inlineTaxAmount);
      inlineTaxesHtml = '''
      <div class="flex-box">
         <p class="width-50 text-left">
            ${AppLocalizations.of(context).translate('tax')} :
         </p>
         <p class="width-50 text-right">
            (+) $symbol $inlineTax
         </p>
      </div>
      ''';
    }

    //structure of due
    if (dueAmount > 0) {
      dueAmount = Helper().formatCurrency(dueAmount);
      dueHtml = '''
      <div class="flex-box">
         <p class="width-50 text-left">
            ${AppLocalizations.of(context).translate('total')} ${AppLocalizations.of(context).translate('due')}
         </p>
         <p class="width-50 text-right">
            $symbol $dueAmount
         </p>
      </div>
    ''';
    }
    String address =
            "$customerAddress1 $customerAddress2 $customerCity $customerState $customerCountry",
        totalTax =
            '${(inlineTaxAmount + double.parse(taxAmount.toString())).toString()}',
        totalDiscount =
            '${(inlineDiscountAmount + double.parse(discountAmount.toString())).toString()}';

    // qr code generation
    // Uint8List qr = await QR().getQrData(
    //     symbol: symbol,
    //     address: address,
    //     businessName: businessName,
    //     context: context,
    //     customer: customerName,
    //     date: dateTime,
    //     discount: totalDiscount,
    //     invoiceNo: invoiceNo,
    //     subTotal: subTotal,
    //     tax: totalTax,
    //     taxLabel: taxLabel,
    //     taxNumber: taxNumber,
    //     total: totalAmount);

    // String base64Image = base64Encode(qr);

    //structure
    String invoice = '''
    <section class="invoice print_section" id="receipt_section">
   <!-- business information here -->
   <meta charset="UTF-8">
   <meta name="viewport" content="width=device-width, initial-scale=1.0">
   <meta http-equiv="X-UA-Compatible" content="ie=edge">
   <!-- <link rel="stylesheet" href="style.css"> -->
   <title>Receipt-$invoiceNo</title>
   <div class="ticket">
      <div class="text-box">
         <!-- Logo -->
         <p class=" centered ">
            <!-- Header text -->
            <!-- business information here -->
            <span class="headings">
            $businessName
            </span>
            <br>
            $landmark $city $state $zipCode $country $businessMobile
            <br>
            <b>$taxLabel </b> $taxNumber
         </p>
      </div>
      <div class="border-top textbox-info">
         <p class="f-left"><strong>${AppLocalizations.of(context).translate('invoice_no')}</strong>&nbsp&nbsp$invoiceNo</p>
      </div>
      <div class="textbox-info">
         <p class="f-left"><strong>${AppLocalizations.of(context).translate('date')}</strong>&nbsp&nbsp$dateTime</p>
      </div>
      <!-- Waiter info -->
      <!-- customer info -->
      <div class="textbox-info">
         <p style="vertical-align: top;"><strong>
            ${AppLocalizations.of(context).translate('customer')}
            </strong>
         </p>
         <p>
            $customerName
         </p>
         <div class="bw">
            $customerAddress1 $customerAddress2 $customerCity $customerState $customerCountry<br>$customerMobile
         </div>
         <p></p>
      </div>
      <div class="bb-lg mb-10"></div>
      <table style="padding-top: 5px !important" class="border-bottom width-100 table-f-12 mb-10">
         <tbody>
            <!--Products-->
            $products
         </tbody>
      </table>
      <div class="flex-box">
         <p class="left text-left">
            <strong>${AppLocalizations.of(context).translate('sub_total')}:</strong>
         </p>
         <p class="width-50 text-right">
            <strong>$symbol ${Helper().formatCurrency(sTotal)}</strong>
         </p>
      </div>
      <!-- Shipping Charges -->
      $shippingHtml
      <!-- Discount -->
      $discountHtml
      
      $inlineDiscountHtml
      
      $taxHtml
      
      $inlineTaxesHtml
      <div class="flex-box">
         <p class="width-50 text-left">
            <strong>${AppLocalizations.of(context).translate('total')}:</strong>
         </p>
         <p class="width-50 text-right">
            <strong>$symbol $totalAmount</strong>
         </p>
      </div>
      <!-- Payments -->
      $payments
      <!-- Total Paid-->
      <div class="flex-box">
         <p class="width-50 text-left">
            ${AppLocalizations.of(context).translate('total')} ${AppLocalizations.of(context).translate('paid')}
         </p>
         <p class="width-50 text-right">
            $symbol $totalReceived
         </p>
      </div>
      <!-- Total Due-->
      $dueHtml
      
      <div class="border-bottom width-100">&nbsp;</div>
      <!-- tax -->
   </div>
   <!-- <button id="btnPrint" class="hidden-print">Print</button>
      <script src="script.js"></script> -->
   <style type="text/css">
   
      @media  print {
      * {
      font-size: 12px;
      font-family: 'Times New Roman';
      word-break: break-all;
      }
      .headings{
      font-size: 16px;
      font-weight: 700;
      text-transform: uppercase;
      }
      .sub-headings{
      font-size: 15px;
      font-weight: 700;
      }
      .border-top{
      border-top: 1px solid #242424;
      }
      .border-bottom{
      border-bottom: 1px solid #242424;
      }
      .border-bottom-dotted{
      border-bottom: 1px dotted darkgray;
      }
      td.serial_number, th.serial_number{
      width: 5%;
      max-width: 5%;
      }
      td.description,
      th.description {
      width: 35%;
      max-width: 35%;
      word-break: break-all;
      }
      td.quantity,
      th.quantity {
      width: 15%;
      max-width: 15%;
      word-break: break-all;
      }
      td.unit_price, th.unit_price{
      width: 25%;
      max-width: 25%;
      word-break: break-all;
      }
      td.price,
      th.price {
      width: 20%;
      max-width: 20%;
      word-break: break-all;
      }
      .centered {
      text-align: center;
      align-content: center;
      }
      .ticket {
      width: 100%;
      max-width: 100%;
      }
      img {
      max-width: inherit;
      width: auto;
      }
      .hidden-print,
      .hidden-print * {
      display: none !important;
      }
      }
      .table-info {
      width: 100%;
      }
      .table-info tr:first-child td, .table-info tr:first-child th {
      padding-top: 8px;
      }
      .table-info th {
      text-align: left;
      }
      .table-info td {
      text-align: right;
      }
      .logo {
      float: left;
      width:35%;
      padding: 10px;
      }
      .text-with-image {
      float: left;
      width:65%;
      }
      .text-box {
      width: 100%;
      height: auto;
      }
      .m-0 {
      margin:0;
      }
      .textbox-info {
      clear: both;
      }
      .textbox-info p {
      margin-bottom: 0px
      }
      .flex-box {
      display: flex;
      width: 100%;
      }
      .flex-box p {
      width: 50%;
      margin-bottom: 0px;
      white-space: nowrap;
      }
      .table-f-12 th, .table-f-12 td {
      font-size: 12px;
      word-break: break-word;
      }
      .bw {
      word-break: break-word;
      }
      .bb-lg {
      border-bottom: 1px solid lightgray;
      }
   </style>
</section>
    ''';
    return invoice;
  }
}
