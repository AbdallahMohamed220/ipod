import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/product_model.dart';
import '../models/sell.dart';
import '../models/sellDatabase.dart';
import '../models/system.dart';
import '../models/variations.dart';
import 'elements.dart';

class Cart extends StatefulWidget {
  @override
  CartState createState() => CartState();
}

class CartState extends State<Cart> {
  bool proceedNext = true, canEditPrice = false, canEditDiscount = false;
  int? selectedContactId, editItem, selectedTaxId = 0, sellingPriceGroupId = 0;
  double? maxDiscountValue, discountAmount = 0.00;
  List cartItems = [];
  Map? argument = {};
  String symbol = '';
  var sellDetail, selectedDiscountType = "fixed";
  final discountController = new TextEditingController();
  final searchController = new TextEditingController();
  var invoiceAmount,
      taxListMap = [
        {'id': 0, 'name': 'Tax rate', 'amount': 0}
      ];
  ThemeData themeData = AppTheme.getThemeFromThemeMode(1);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(1);

  @override
  void initState() {
    super.initState();
    getPermission();
    setTaxMap();
    getDefaultValues();
    getSellingPriceGroupId();
  }

  @override
  void didChangeDependencies() {
    argument = ModalRoute.of(context)!.settings.arguments as Map;

    if (argument!['sellId'] != null) editCart(argument!['sellId']);

    super.didChangeDependencies();

    cartList();
  }

  @override
  void dispose() {
    discountController.dispose();
    super.dispose();
  }

  cartList() async {
    cartItems = [];
    (argument!['sellId'] != null)
        ? cartItems = await SellDatabase().getInCompleteLines(
            argument!['locationId'],
            sellId: argument!['sellId'])
        : cartItems =
            await SellDatabase().getInCompleteLines(argument!['locationId']);
    if (this.mounted) {
      setState(() {
        if (editItem == null) {
          proceedNext = true;
        }
      });
    }
  }

  editCart(sellId) async {
    sellDetail = await SellDatabase().getSellBySellId(sellId);
    selectedTaxId = (sellDetail[0]['tax_rate_id'] != null)
        ? sellDetail[0]['tax_rate_id']
        : 0;
    selectedContactId = sellDetail[0]['contact_id'];
    selectedDiscountType = sellDetail[0]['discount_type'];
    discountAmount = sellDetail[0]['discount_amount'];
    discountController.text = discountAmount.toString();
    calculateSubtotal(selectedTaxId, selectedDiscountType, discountAmount);
    if (this.mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(AppLocalizations.of(context).translate('cart'),
            style: AppTheme.getTextStyle(themeData.textTheme.headline6,
                fontWeight: 600)),
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              (argument!['sellId'] == null)
                  ? Navigator.pop(context)
                  : Navigator.pushReplacementNamed(context, '/products',
                      arguments: Helper().argument(
                        sellId: argument!['sellId'],
                        locId: argument!['locationId'],
                      ));
            }),
        actions: [
          InkWell(
            onTap: () async {
              var barcode = await Helper().barcodeScan();
              await getScannedProduct(barcode);
            },
            child: Container(
              margin: EdgeInsets.only(
                  right: MySize.size16!,
                  bottom: MySize.size8!,
                  top: MySize.size8!),
              decoration: BoxDecoration(
                color: themeData.backgroundColor,
                borderRadius: BorderRadius.all(Radius.circular(MySize.size16!)),
                boxShadow: [
                  BoxShadow(
                    color: themeData.cardTheme.shadowColor!.withAlpha(48),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  )
                ],
              ),
              padding:
                  EdgeInsets.only(left: MySize.size12!, right: MySize.size12!),
              child: Icon(
                MdiIcons.barcode,
                color: themeData.colorScheme.primary,
              ),
            ),
          ),
          searchDropdown()
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: <Widget>[
          Container(
              height: MySize.safeHeight! * 0.65,
              color: customAppTheme.bgLayer1,
              child: (cartItems.length > 0)
                  ? itemList()
                  : Center(
                      child: Text(AppLocalizations.of(context)
                          .translate('add_item_to_cart')))),
          Divider(),
          Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(
                    left: MySize.size24!, right: MySize.size24!),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                        AppLocalizations.of(context).translate('sub_total') +
                            ' : ',
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.subtitle1,
                          fontWeight: 700,
                          color: themeData.colorScheme.onBackground,
                        )),
                    Text(symbol + Helper().formatCurrency(calculateSubTotal()),
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.subtitle1,
                          fontWeight: 700,
                          color: themeData.colorScheme.onBackground,
                        )),
                  ],
                ),
              )
            ],
          ),
          Container(
            padding:
                EdgeInsets.only(left: MySize.size24!, right: MySize.size24!),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  AppLocalizations.of(context).translate('discount') + ' : ',
                  style: AppTheme.getTextStyle(themeData.textTheme.bodyText1,
                      color: themeData.colorScheme.onBackground,
                      fontWeight: 600,
                      muted: true),
                ),
                discount(),
                Expanded(
                  child: Container(
                    height: MySize.size50,
                    child: TextFormField(
                      controller: discountController,
                      decoration: InputDecoration(
                        prefix: Text(
                            (selectedDiscountType == 'fixed') ? symbol : ''),
                        labelText: AppLocalizations.of(context)
                            .translate('discount_amount'),
                        border: themeData.inputDecorationTheme.border,
                        enabledBorder: themeData.inputDecorationTheme.border,
                        focusedBorder:
                            themeData.inputDecorationTheme.focusedBorder,
                      ),
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.subtitle2,
                          fontWeight: 400,
                          letterSpacing: -0.2),
                      textAlign: TextAlign.end,
                      inputFormatters: [
                        // ignore: deprecated_member_use
                        FilteringTextInputFormatter(
                            RegExp(r'^(\d+)?\.?\d{0,2}'),
                            allow: true)
                      ],
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          discountAmount = Helper().validateInput(value);
                          if (maxDiscountValue != null &&
                              discountAmount! > maxDiscountValue!) {
                            Fluttertoast.showToast(
                                msg: AppLocalizations.of(context)
                                        .translate('discount_error_message') +
                                    " $maxDiscountValue");
                            proceedNext = false;
                          } else {
                            proceedNext = true;
                          }
                        });
                      },
                    ),
                  ),
                )
              ],
            ),
          ),
          Container(
            padding:
                EdgeInsets.only(left: MySize.size24!, right: MySize.size24!),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  AppLocalizations.of(context).translate('tax') + ' : ',
                  style: AppTheme.getTextStyle(themeData.textTheme.bodyText1,
                      color: themeData.colorScheme.onBackground,
                      fontWeight: 600,
                      muted: true),
                ),
                taxes(),
                Text(
                  AppLocalizations.of(context).translate('total') + ' : ',
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.subtitle1,
                    fontWeight: 700,
                    color: themeData.colorScheme.onBackground,
                  ),
                ),
                Text(
                    symbol +
                        Helper().formatCurrency(calculateSubtotal(selectedTaxId,
                            selectedDiscountType, discountAmount)),
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.subtitle1,
                      fontWeight: 700,
                      color: themeData.colorScheme.onBackground,
                      letterSpacing: 0,
                    ))
              ],
            ),
          ),
        ]),
      ),
      bottomNavigationBar: Visibility(
        visible: (cartItems.length > 0 && proceedNext == true),
        child: cartBottomBar(
            '/customer',
            AppLocalizations.of(context).translate('customer'),
            context,
            Helper().argument(
                locId: argument!['locationId'],
                taxId: selectedTaxId,
                discountType: selectedDiscountType,
                discountAmount: discountAmount,
                invoiceAmount: calculateSubtotal(
                    selectedTaxId, selectedDiscountType, discountAmount),
                sellId: argument!['sellId'],
                isQuotation: argument!['is_quotation'],
                customerId:
                    (argument!['sellId'] != null) ? selectedContactId : null)),
      ),
    );
  }

  //filter dropdown
  Widget searchDropdown() {
    return Container(
      margin: EdgeInsets.only(right: MySize.size10!, top: MySize.size8!),
      width: MySize.screenWidth! * 0.45,
      child: TextFormField(
        style: AppTheme.getTextStyle(themeData.textTheme.subtitle2,
            letterSpacing: 0, fontWeight: 500),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).translate('search'),
          hintStyle: AppTheme.getTextStyle(themeData.textTheme.subtitle2,
              letterSpacing: 0, fontWeight: 500),
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
            size: MySize.size22,
            color: themeData.colorScheme.onBackground.withAlpha(150),
          ),
          isDense: true,
          contentPadding: EdgeInsets.only(right: MySize.size16!),
        ),
        textCapitalization: TextCapitalization.sentences,
        controller: searchController,
        onEditingComplete: () async {
          await getSearchItemList(searchController.text)
              .then((value) => itemDialog(value));
          FocusScope.of(context).requestFocus(FocusNode());
        },
      ),
    );
  }

  //show items dialog list
  itemDialog(List items) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: customAppTheme.bgLayer1,
          content: Container(
            color: customAppTheme.bgLayer1,
            height: MySize.screenHeight! * 0.8,
            width: MySize.screenWidth! * 0.8,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: (items.length != 0) ? items.length : 0,
                itemBuilder: ((context, index) {
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.all(MySize.size4!),
                    child: ListTile(
                      title: Text(items[index]['display_name']),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            symbol +
                                Helper()
                                    .formatCurrency(items[index]['unit_price']),
                            style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyText2,
                                fontWeight: 700,
                                letterSpacing: 0),
                          ),
                          Container(
                            width: MySize.size80,
                            decoration: BoxDecoration(
                                color: themeData.colorScheme.primary,
                                borderRadius: BorderRadius.all(
                                    Radius.circular(MySize.size4!))),
                            padding: EdgeInsets.only(
                                left: MySize.size6!,
                                right: MySize.size8!,
                                top: MySize.size2!,
                                bottom: MySize.getScaledSizeHeight(3.5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Icon(
                                  MdiIcons.stocking,
                                  color: themeData.colorScheme.onPrimary,
                                  size: MySize.size12,
                                ),
                                Container(
                                  margin: EdgeInsets.only(left: MySize.size4!),
                                  child: Text(
                                      Helper().formatQuantity(
                                          items[index]['stock_available']),
                                      style: AppTheme.getTextStyle(
                                          themeData.textTheme.caption,
                                          fontSize: 11,
                                          color:
                                              themeData.colorScheme.onPrimary,
                                          fontWeight: 600)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () async {
                        Fluttertoast.showToast(
                            msg: AppLocalizations.of(context)
                                .translate('added_to_cart'));
                        await Sell().addToCart(items[index],
                            argument != null ? argument!['sellId'] : null);
                        setState(() {
                          cartList();
                        });
                      },
                    ),
                  );
                })),
          ),
        );
      },
    );
  }

  //get search items list
  Future<List> getSearchItemList(String searchText) async {
    List products = [];
    var price;
    await Variations()
        .get(
            locationId: argument!['locationId'],
            offset: 0,
            inStock: true,
            searchTerm: '$searchText')
        .then((value) {
      value.forEach((element) {
        if (element['selling_price_group'] != null) {
          jsonDecode(element['selling_price_group']).forEach((element) {
            if (element['key'] == sellingPriceGroupId) {
              price = element['value'];
            }
          });
        }
        setState(() {
          products.add(ProductModel().product(element, price));
        });
      });
    });
    return products;
  }

  //set selling price group Id
  getSellingPriceGroupId() async {
    await System().get('location').then((value) {
      value.forEach((element) {
        if (element['id'] == argument!['locationId'] &&
            element['selling_price_group_id'] != null) {
          sellingPriceGroupId =
              int.parse(element['selling_price_group_id'].toString());
        }
      });
    });
  }

  //add product to cart after scanning barcode
  getScannedProduct(String barcode) async {
    await Variations()
        .get(
            locationId: argument!['locationId'],
            offset: 0,
            barcode: barcode,
            searchTerm: '')
        .then((value) async {
      if (value.length > 0) {
        var price;
        var product;
        if (value[0]['selling_price_group'] != null) {
          jsonDecode(value[0]['selling_price_group']).forEach((element) {
            if (element['key'] == sellingPriceGroupId) {
              price = element['value'];
            }
          });
        }
        setState(() {
          product = ProductModel().product(value[0], price);
        });
        if (product != null && product['stock_available'] > 0) {
          Fluttertoast.showToast(
              msg: AppLocalizations.of(context).translate('added_to_cart'));
          await Sell().addToCart(
              product, (argument != null) ? argument!['sellId'] : null);
          cartList();
        } else {
          Fluttertoast.showToast(msg: "Out of Stock");
        }
      } else {
        Fluttertoast.showToast(msg: "No product found");
      }
    });
  }

  Widget itemList() {
    int themeType = 1;
    ThemeData themeData;
    CustomAppTheme customAppTheme;
    themeData = AppTheme.getThemeFromThemeMode(themeType);
    customAppTheme = AppTheme.getCustomAppTheme(themeType);

    return ListView.builder(
      shrinkWrap: true,
      itemCount: cartItems.length,
      padding: EdgeInsets.only(
        top: MySize.size16!,
      ),
      itemBuilder: (context, index) {
        return Padding(
            padding: EdgeInsets.only(
                left: MySize.size8!,
                right: MySize.size8!,
                bottom: MySize.size8!),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      blurRadius: MySize.size8!,
                      color: customAppTheme.shadowColor,
                      offset: Offset(0, MySize.size4!))
                ],
              ),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                          color: themeData.cardTheme.shadowColor!.withAlpha(10),
                          blurRadius: MySize.size16!)
                    ],
                    color: customAppTheme.bgLayer1,
                    borderRadius:
                        BorderRadius.all(Radius.circular(MySize.size16!))),
                padding: EdgeInsets.only(right: MySize.size16!),
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.all(MySize.size8!),
                      child: Text(
                        cartItems[index]['name'],
                        overflow: (editItem == index)
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: AppTheme.getTextStyle(
                            themeData.textTheme.bodyText1,
                            color: themeData.colorScheme.onBackground,
                            fontWeight: 600),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            // height: MySize.safeHeight *
                            //     (editItem == index ? 0.37 : 0.15),
                            margin: EdgeInsets.only(left: MySize.size20!),
                            child: Column(
                              children: [
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                          Text(
                                            symbol +
                                                Helper().formatCurrency(
                                                    cartItems[index]
                                                        ['unit_price']),
                                            style: AppTheme.getTextStyle(
                                                themeData.textTheme.bodyText1,
                                                color: themeData
                                                    .colorScheme.onBackground,
                                                fontWeight: 600,
                                                letterSpacing: -0.2,
                                                muted: true),
                                          ),
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(AppLocalizations.of(context)
                                                        .translate('total') +
                                                    ' : ' +
                                                    symbol +
                                                    Helper().formatCurrency((double.parse(
                                                            calculateInlineUnitPrice(
                                                                cartItems[index]
                                                                    [
                                                                    'unit_price'],
                                                                cartItems[index]
                                                                    [
                                                                    'tax_rate_id'],
                                                                cartItems[index]
                                                                    [
                                                                    'discount_type'],
                                                                cartItems[index]
                                                                    [
                                                                    'discount_amount'])) *
                                                        cartItems[index]
                                                            ['quantity']))),
                                              ]),
                                          Row(
                                            children: [
                                              IconButton(
                                                  icon: Icon(
                                                    MdiIcons.pencil,
                                                    size: MySize.size20,
                                                  ),
                                                  color: themeData
                                                      .colorScheme.onBackground,
                                                  onPressed: () {
                                                    setState(() {
                                                      (editItem == index)
                                                          ? editItem = null
                                                          : editItem = index;
                                                    });
                                                  }),
                                              IconButton(
                                                  icon: Icon(MdiIcons.delete,
                                                      size: MySize.size20),
                                                  color: themeData
                                                      .colorScheme.onBackground,
                                                  onPressed: () {
                                                    showDialog(
                                                      barrierDismissible: true,
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return AlertDialog(
                                                          title: Row(
                                                            children: <Widget>[
                                                              Padding(
                                                                padding: EdgeInsets
                                                                    .all(MySize
                                                                        .size5!),
                                                                child: Icon(
                                                                  MdiIcons
                                                                      .alertCircle,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                              ),
                                                              Text(
                                                                AppLocalizations.of(
                                                                        context)
                                                                    .translate(
                                                                        'delete_item_message'),
                                                                style: AppTheme.getTextStyle(
                                                                    themeData
                                                                        .textTheme
                                                                        .headline6,
                                                                    color: themeData
                                                                        .colorScheme
                                                                        .onBackground,
                                                                    fontWeight:
                                                                        600),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ],
                                                          ),
                                                          actions: <Widget>[
                                                            TextButton(
                                                                onPressed: () {
                                                                  (argument!['sellId'] ==
                                                                          null)
                                                                      ? SellDatabase().delete(
                                                                          cartItems[index]
                                                                              [
                                                                              'variation_id'],
                                                                          cartItems[index]
                                                                              [
                                                                              'product_id'])
                                                                      : SellDatabase().delete(
                                                                          cartItems[index]
                                                                              [
                                                                              'variation_id'],
                                                                          cartItems[index]
                                                                              [
                                                                              'product_id'],
                                                                          sellId:
                                                                              argument!['sellId']);
                                                                  editItem =
                                                                      null;
                                                                  cartList();
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                child: Text(AppLocalizations.of(
                                                                        context)
                                                                    .translate(
                                                                        'yes'))),
                                                            TextButton(
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                child: Text(AppLocalizations.of(
                                                                        context)
                                                                    .translate(
                                                                        'no')))
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  })
                                            ],
                                          )
                                        ])),
                                    Container(
                                        alignment: Alignment.centerRight,
                                        width: MySize.screenWidth! * 0.25,
                                        height: MySize.screenHeight! * 0.05,
                                        child: (editItem != index)
                                            ? Text(
                                                "${AppLocalizations.of(context).translate('quantity')}:${cartItems[index]['quantity'].toString()}")
                                            : TextFormField(
                                                controller: (editItem != index)
                                                    ? TextEditingController(
                                                        text: cartItems[index]
                                                                ['quantity']
                                                            .toString())
                                                    : null,
                                                initialValue:
                                                    (editItem == index)
                                                        ? cartItems[index]
                                                                ['quantity']
                                                            .toString()
                                                        : null,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter(
                                                      RegExp(
                                                          r'^(\d+)?\.?\d{0,2}'),
                                                      allow: true)
                                                ],
                                                keyboardType: TextInputType
                                                    .numberWithOptions(
                                                        decimal: true),
                                                textAlign: TextAlign.end,
                                                decoration: InputDecoration(
                                                  labelText: AppLocalizations
                                                          .of(context)
                                                      .translate('quantity'),
                                                ),
                                                onChanged: (newQuantity) {
                                                  if (newQuantity != "" &&
                                                      double.parse(
                                                              newQuantity) >
                                                          0) {
                                                    if (!proceedNext)
                                                      proceedNext = true;
                                                    if (cartItems[index][
                                                            'stock_available'] >=
                                                        double.parse(
                                                            newQuantity)) {
                                                      SellDatabase().update(
                                                          cartItems[index]
                                                              ['id'],
                                                          {
                                                            'quantity':
                                                                double.parse(
                                                                    newQuantity)
                                                          });
                                                      cartList();
                                                    } else {
                                                      Fluttertoast.showToast(
                                                          msg: "${cartItems[index]['stock_available']}" +
                                                              AppLocalizations.of(
                                                                      context)
                                                                  .translate(
                                                                      'stock_available'));
                                                    }
                                                  } else if (newQuantity ==
                                                      "") {
                                                    setState(() {
                                                      proceedNext = false;
                                                    });
                                                    Fluttertoast.showToast(
                                                        msg: AppLocalizations
                                                                .of(context)
                                                            .translate(
                                                                'please_enter_a_valid_quantity'));
                                                  }
                                                },
                                              )),
                                    Container(
                                      margin:
                                          EdgeInsets.only(left: MySize.size24!),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: <Widget>[
                                          InkWell(
                                            onTap: () {
                                              if (cartItems[index]
                                                      ['stock_available'] >
                                                  cartItems[index]
                                                      ['quantity']) {
                                                SellDatabase().update(
                                                    cartItems[index]['id'], {
                                                  'quantity': cartItems[index]
                                                          ['quantity'] +
                                                      1
                                                });
                                                cartList();
                                              } else {
                                                var stockAvailable =
                                                    cartItems[index]
                                                        ['stock_available'];
                                                Fluttertoast.showToast(
                                                    msg: "$stockAvailable" +
                                                        AppLocalizations.of(
                                                                context)
                                                            .translate(
                                                                'stock_available'));
                                              }
                                            },
                                            child: Container(
                                              padding:
                                                  EdgeInsets.all(MySize.size6!),
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      customAppTheme.bgLayer3,
                                                  boxShadow: [
                                                    BoxShadow(
                                                        color: themeData
                                                            .cardTheme
                                                            .shadowColor!
                                                            .withAlpha(8),
                                                        blurRadius:
                                                            MySize.size8!)
                                                  ]),
                                              child: Icon(
                                                MdiIcons.plus,
                                                size: MySize.size20,
                                                color: themeData
                                                    .colorScheme.onBackground,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              if (cartItems[index]['quantity'] >
                                                  1) {
                                                SellDatabase().update(
                                                    cartItems[index]['id'], {
                                                  'quantity': cartItems[index]
                                                          ['quantity'] -
                                                      1
                                                });
                                                cartList();
                                              }
                                            },
                                            child: Container(
                                              padding:
                                                  EdgeInsets.all(MySize.size6!),
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      customAppTheme.bgLayer3,
                                                  boxShadow: [
                                                    BoxShadow(
                                                        color: themeData
                                                            .cardTheme
                                                            .shadowColor!
                                                            .withAlpha(10),
                                                        blurRadius:
                                                            MySize.size8!)
                                                  ]),
                                              child: Icon(
                                                MdiIcons.minus,
                                                size: MySize.size20,
                                                color: themeData
                                                    .colorScheme.onBackground,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Visibility(
                                    visible: (editItem == index),
                                    child: edit(cartItems[index])),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ));
      },
    );
  }

  //edit cart item
  Widget edit(index) {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              (canEditPrice)
                  ? SizedBox(
                      width: MySize.size160,
                      height: MySize.size50,
                      child: TextFormField(
                          initialValue: index['unit_price'].toStringAsFixed(2),
                          decoration: InputDecoration(
                            prefix: Text(symbol),
                            labelText: AppLocalizations.of(context)
                                .translate('unit_price'),
                            border: themeData.inputDecorationTheme.border,
                            enabledBorder:
                                themeData.inputDecorationTheme.border,
                            focusedBorder:
                                themeData.inputDecorationTheme.focusedBorder,
                          ),
                          style: AppTheme.getTextStyle(
                              themeData.textTheme.subtitle2,
                              fontWeight: 400,
                              letterSpacing: -0.2),
                          textAlign: TextAlign.end,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^(\d+)?\.?\d{0,2}'))
                          ],
                          keyboardType: TextInputType.number,
                          onChanged: (newValue) {
                            double value = Helper().validateInput(newValue);
                            SellDatabase()
                                .update(index['id'], {'unit_price': '$value'});
                            cartList();
                          }),
                    )
                  : Container(),
              (canEditDiscount)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(AppLocalizations.of(context)
                                .translate('discount_type') +
                            ' : '),
                        inLineDiscount(index),
                      ],
                    )
                  : Container(),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              (canEditDiscount)
                  ? SizedBox(
                      width: MySize.size160,
                      height: MySize.size50,
                      child: TextFormField(
                          initialValue: index['discount_amount'].toString(),
                          decoration: InputDecoration(
                            prefix: Text(symbol),
                            labelText: AppLocalizations.of(context)
                                .translate('discount_amount'),
                            border: themeData.inputDecorationTheme.border,
                            enabledBorder:
                                themeData.inputDecorationTheme.border,
                            focusedBorder:
                                themeData.inputDecorationTheme.focusedBorder,
                          ),
                          style: AppTheme.getTextStyle(
                              themeData.textTheme.subtitle2,
                              fontWeight: 400,
                              letterSpacing: -0.2),
                          textAlign: TextAlign.end,
                          inputFormatters: [
                            // ignore: deprecated_member_use
                            FilteringTextInputFormatter(
                                RegExp(r'^(\d+)?\.?\d{0,2}'),
                                allow: true)
                          ],
                          keyboardType: TextInputType.number,
                          onChanged: (newValue) {
                            double value = Helper().validateInput(newValue);
                            SellDatabase().update(
                                index['id'], {'discount_amount': '$value'});
                            cartList();
                          }),
                    )
                  : Container(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(AppLocalizations.of(context).translate('tax') + ' : '),
                  inLineTax(index),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  setTaxMap() {
    System().get('tax').then((value) {
      value.forEach((element) {
        taxListMap.add({
          'id': element['id'],
          'name': element['name'],
          'amount': double.parse(element['amount'].toString())
        });
      });
    });
  }

  //inLine tax widget
  Widget inLineTax(index) {
    //['tax_rate_id'], index['variation_id']
    //taxId, varId
    return DropdownButtonHideUnderline(
      child: DropdownButton(
          dropdownColor: themeData.backgroundColor,
          icon: Icon(
            Icons.arrow_drop_down,
          ),
          value: (index['tax_rate_id'] != null) ? index['tax_rate_id'] : 0,
          items: taxListMap.map<DropdownMenuItem<int>>((Map value) {
            return DropdownMenuItem<int>(
                value: value['id'],
                child: Text(
                  value['name'],
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ));
          }).toList(),
          onChanged: (newValue) {
            SellDatabase().update(index['id'],
                {'tax_rate_id': (newValue == 0) ? null : newValue});
            cartList();
          }),
    );
  }

  //inLine discount widget
  Widget inLineDiscount(index) {
    return DropdownButtonHideUnderline(
      child: DropdownButton(
          dropdownColor: themeData.backgroundColor,
          icon: Icon(
            Icons.arrow_drop_down,
          ),
          value: index['discount_type'],
          items: <String>['fixed', 'percentage']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            SellDatabase().update(index['id'], {'discount_type': '$newValue'});
            cartList();
          }),
    );
  }

  //discount widget
  Widget discount() {
    return DropdownButtonHideUnderline(
      child: DropdownButton(
          dropdownColor: themeData.backgroundColor,
          icon: Icon(
            Icons.arrow_drop_down,
          ),
          value: selectedDiscountType,
          items: <String>['fixed', 'percentage']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              selectedDiscountType = newValue.toString();
              calculateSubtotal(
                  selectedTaxId, selectedDiscountType, discountAmount);
            });
          }),
    );
  }

  //dropdown tax widget
  Widget taxes() {
    return DropdownButtonHideUnderline(
      child: DropdownButton(
          dropdownColor: themeData.backgroundColor,
          icon: Icon(
            Icons.arrow_drop_down,
          ),
          value: selectedTaxId,
          items: taxListMap.map<DropdownMenuItem<int>>((Map value) {
            return DropdownMenuItem<int>(
                value: value['id'],
                child: Text(
                  value['name'],
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ));
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              selectedTaxId = int.parse(newValue.toString());
            });
          }),
    );
  }

  //calculate inline total
  String calculateInlineUnitPrice(price, taxId, discountType, discountAmount) {
    double subTotal;
    var taxAmount;
    taxListMap.forEach((value) {
      if (value['id'] == taxId) {
        taxAmount = value['amount'];
      }
    });
    if (taxAmount == null) {
      taxAmount = 0;
    }
    if (discountType == 'fixed') {
      var unitPrice = price - discountAmount;
      subTotal = unitPrice + (unitPrice * taxAmount / 100);
    } else {
      var unitPrice = price - (price * discountAmount / 100);
      subTotal = unitPrice + (unitPrice * taxAmount / 100);
    }
    return subTotal.toString();
  }

  //calculate subTotal
  double calculateSubTotal() {
    var subTotal = 0.0;
    cartItems.forEach((element) {
      subTotal += (double.parse(calculateInlineUnitPrice(
              element['unit_price'],
              element['tax_rate_id'],
              element['discount_type'],
              element['discount_amount'])) *
          element['quantity']);
    });
    return subTotal;
  }

  //calculate total
  double calculateSubtotal(taxId, discountType, discountAmount) {
    double subTotal = calculateSubTotal();
    var finalTotal;
    var taxAmount;
    taxListMap.forEach((value) {
      if (value['id'] == taxId) {
        taxAmount = value['amount'];
      }
    });

    if (taxAmount == null) {
      taxAmount = 0;
    }
    if (discountType == 'fixed') {
      var total = subTotal - discountAmount;
      finalTotal = total + (total * taxAmount / 100);
    } else {
      var total = subTotal - (subTotal * discountAmount / 100);
      finalTotal = total + (total * taxAmount / 100);
    }
    invoiceAmount = finalTotal;
    return finalTotal;
  }

  //fetch default discount and tax from database
  getDefaultValues() async {
    var businessDetails = await System().get('business');
    await Helper().getFormattedBusinessDetails().then((value) {
      symbol = "${value['symbol']} ";
    });
    var userDetails = await System().get('loggedInUser');
    setState(() {
      if (userDetails['max_sales_discount_percent'] != null)
        maxDiscountValue =
            double.parse(userDetails['max_sales_discount_percent']);
    });
    if (sellDetail == null && businessDetails[0]['default_sales_tax'] != null) {
      setState(() {
        selectedTaxId =
            int.parse(businessDetails[0]['default_sales_tax'].toString());
      });
    }
    if (sellDetail == null &&
        businessDetails[0]['default_sales_discount'] != null) {
      setState(() {
        selectedDiscountType = 'percentage';
        discountAmount =
            double.parse(businessDetails[0]['default_sales_discount']);
        discountController.text = discountAmount.toString();
        if (maxDiscountValue != null && discountAmount! > maxDiscountValue!) {
          Fluttertoast.showToast(
              msg: AppLocalizations.of(context)
                      .translate('discount_error_message') +
                  " $maxDiscountValue");
          proceedNext = false;
        }
      });
    }
  }

  //Fetch permission from database
  getPermission() async {
    canEditPrice =
        await Helper().getPermission("edit_product_price_from_pos_screen");
    canEditDiscount =
        await Helper().getPermission("edit_product_discount_from_pos_screen");
  }
}
