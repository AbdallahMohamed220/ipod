import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/generators.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/product_model.dart';
import '../models/sell.dart';
import '../models/system.dart';
import '../models/variations.dart';
import 'elements.dart';

class Products extends StatefulWidget {
  @override
  _ProductsState createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  List products = [];
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  bool changeLocation = false,
      changePriceGroup = false,
      canChangeLocation = true,
      canMakeSell = false,
      inStock = true,
      gridView = false,
      canAddSell = false,
      canViewProducts = false,
      usePriceGroup = true;

  int selectedLocationId = 0,
      categoryId = 0,
      subCategoryId = 0,
      brandId = 0,
      cartCount = 0,
      sellingPriceGroupId = 0,
      offset = 0;
  int? byAlphabets, byPrice;

  List<DropdownMenuItem<int>> _categoryMenuItems = [],
      _subCategoryMenuItems = [],
      _brandsMenuItems = [];
  List<DropdownMenuItem<bool>> _priceGroupMenuItems = [];
  Map? argument;
  List<Map<String, dynamic>> locationListMap = [
    {'id': 0, 'name': 'set location', 'selling_price_group_id': 0}
  ];

  String symbol = '';
  final searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  ScrollController _scrollController = new ScrollController();

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    getPermission();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        productList();
      }
    });
    setLocationMap();
    categoryList();
    subCategoryList(categoryId);
    brandList();
    Helper().syncCallLogs();
  }

  @override
  Future<void> didChangeDependencies() async {
    argument = ModalRoute.of(context)!.settings.arguments as Map?;
    //Arguments sellId & locationId is send from edit.
    if (argument != null) {
      Future.delayed(Duration(milliseconds: 200), () {
        if (this.mounted) {
          setState(() {
            selectedLocationId = argument!['locationId'];
            canChangeLocation = false;
          });
        }
      });
    } else {
      canChangeLocation = true;
    }
    await setInitDetails(selectedLocationId);
    super.didChangeDependencies();
  }

  //Set location & product
  setInitDetails(selectedLocationId) async {
    //check subscription
    var activeSubscriptionDetails = await System().get('active-subscription');
    if (activeSubscriptionDetails.length > 0) {
      setState(() {
        canMakeSell = true;
      });
    } else {
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context).translate('no_subscription_found'));
    }
    await Helper().getFormattedBusinessDetails().then((value) {
      symbol = value['symbol'] + ' ';
    });
    await setDefaultLocation(selectedLocationId);
    products = [];
    offset = 0;
    productList();
  }

  //Fetch permission from database
  getPermission() async {
    if (await Helper().getPermission("direct_sell.access")) {
      canAddSell = true;
    }
    if (await Helper().getPermission("product.view")) {
      canViewProducts = true;
    }
  }

  //set selling Price Group Id
  findSellingPriceGroupId(locId) {
    if (usePriceGroup) {
      locationListMap.forEach((element) {
        if (element['id'] == selectedLocationId &&
            element['selling_price_group_id'] != null) {
          sellingPriceGroupId =
              int.parse(element['selling_price_group_id'].toString());
        } else if (element['id'] == selectedLocationId &&
            element['selling_price_group_id'] == null) {
          sellingPriceGroupId = 0;
        }
      });
    } else {
      sellingPriceGroupId = 0;
    }
  }

  //set product list
  productList() async {
    offset++;
    //check last sync, if difference is 10 minutes then sync again.
    String? lastSync = await System().getProductLastSync();
    final date2 = DateTime.now();
    if (lastSync == null ||
        (date2.difference(DateTime.parse(lastSync)).inMinutes > 10)) {
      if (await Helper().checkConnectivity()) {
        await Variations().refresh();
        await System().insertProductLastSyncDateTimeNow();
      }
    }

    findSellingPriceGroupId(selectedLocationId);
    await Variations()
        .get(
            brandId: brandId,
            categoryId: categoryId,
            subCategoryId: subCategoryId,
            inStock: inStock,
            locationId: selectedLocationId,
            searchTerm: searchController.text,
            offset: offset,
            byAlphabets: byAlphabets,
            byPrice: byPrice)
        .then((element) {
      element.forEach((product) {
        var price;
        if (product['selling_price_group'] != null) {
          jsonDecode(product['selling_price_group']).forEach((element) {
            if (element['key'] == sellingPriceGroupId) {
              price = double.parse(element['value'].toString());
            }
          });
        }
        setState(() {
          products.add(ProductModel().product(product, price));
        });
      });
    });
  }

  categoryList() async {
    List categories = await System().getCategories();

    _categoryMenuItems.add(
      DropdownMenuItem(
        child: Text(AppLocalizations.of(context).translate('select_category')),
        value: 0,
      ),
    );

    for (var category in categories) {
      _categoryMenuItems.add(
        DropdownMenuItem(
          child: Text(category['name']),
          value: category['id'],
        ),
      );
    }
  }

  subCategoryList(parentId) async {
    List subCategories = await System().getSubCategories(parentId);
    _subCategoryMenuItems = [];
    _subCategoryMenuItems.add(
      DropdownMenuItem(
        child:
            Text(AppLocalizations.of(context).translate('select_sub_category')),
        value: 0,
      ),
    );
    subCategories.forEach((element) {
      _subCategoryMenuItems.add(
        DropdownMenuItem(
          child: Text(jsonDecode(element['value'])['name']),
          value: jsonDecode(element['value'])['id'],
        ),
      );
    });
  }

  brandList() async {
    List brands = await System().getBrands();

    _brandsMenuItems.add(
      DropdownMenuItem(
        child: Text(AppLocalizations.of(context).translate('select_brand')),
        value: 0,
      ),
    );

    for (var brand in brands) {
      _brandsMenuItems.add(
        DropdownMenuItem(
          child: Text(brand['name']),
          value: brand['id'],
        ),
      );
    }
  }

  priceGroupList() async {
    setState(() {
      _priceGroupMenuItems = [];
      _priceGroupMenuItems.add(
        DropdownMenuItem(
          child: Text(AppLocalizations.of(context)
              .translate('no_price_group_selected')),
          value: false,
        ),
      );

      locationListMap.forEach((element) {
        if (element['id'] == selectedLocationId &&
            element['selling_price_group_id'] != null) {
          _priceGroupMenuItems.add(
            DropdownMenuItem(
              child: Text(AppLocalizations.of(context)
                  .translate('default_price_group')),
              value: true,
            ),
          );
        }
      });
    });
  }

  Future<String> getCartItemCount({isCompleted, sellId}) async {
    var counts =
        await Sell().cartItemCount(isCompleted: isCompleted, sellId: sellId);
    setState(() {
      cartCount = int.parse(counts);
    });
    return counts;
  }

  double findAspectRatio(double width) {
    //Logic for aspect ratio of grid view
    return (width / 2 - MySize.size24!) / ((width / 2 - MySize.size24!) + 60);
  }

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        backgroundColor: themeData.colorScheme.background,
        endDrawer: _filterDrawer(),
        appBar: AppBar(
          elevation: 0,
          title: Text(AppLocalizations.of(context).translate('products'),
              style: AppTheme.getTextStyle(themeData.textTheme.titleLarge,
                  fontWeight: 600)),
          leading: null,
          actions: <Widget>[
            locations(),
            Badge(
              backgroundColor: themeData.colorScheme.error,
              //shape: BadgeShape.circle,
              //borderRadius: BorderRadius.circular(MySize.size20!),
              //toAnimate: true,
              // position: BadgePosition.topStart(start: 5.0, top: 5.0),
              label: FutureBuilder(
                  future: (argument != null && argument!['sellId'] != null)
                      ? getCartItemCount(sellId: argument!['sellId'])
                      : getCartItemCount(isCompleted: 0),
                  builder: (context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasData) {
                      return Center(
                        child: Text('${snapshot.data}',
                            style: TextStyle(color: Colors.white)),
                      );
                    } else
                      return Center(
                        child: Text("0", style: TextStyle(color: Colors.white)),
                      );
                  }),
              child: IconButton(
                  icon: Icon(Icons.shopping_cart),
                  onPressed: () {
                    if (argument != null) {
                      Navigator.pushReplacementNamed(context, '/cart',
                          arguments: Helper().argument(
                              locId: argument!['locationId'],
                              sellId: argument!['sellId']));
                    } else {
                      if (selectedLocationId != 0 && cartCount > 0) {
                        Navigator.pushNamed(context, '/cart',
                            arguments:
                                Helper().argument(locId: selectedLocationId));
                      }

                      if (cartCount == 0) {
                        Fluttertoast.showToast(
                            msg: AppLocalizations.of(context)
                                .translate('no_items_added_to_cart'));
                      }
                    }
                  }),
            )
          ],
        ),
        body: (canViewProducts)
            ? ListView(
                physics: ClampingScrollPhysics(),
                controller: _scrollController,
                padding: EdgeInsets.all(0),
                children: [
                  Visibility(
                      visible: (selectedLocationId != 0),
                      child: filter(
                        _scaffoldKey,
                      )),
                  (selectedLocationId == 0)
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on),
                              Text(AppLocalizations.of(context)
                                  .translate('please_set_a_location')),
                            ],
                          ),
                        )
                      : _productsList(),
                ],
              )
            : Center(
                child: Text(
                  AppLocalizations.of(context).translate('unauthorised'),
                  style: TextStyle(color: Colors.black),
                ),
              ),
        bottomNavigationBar: Visibility(
            visible: argument == null,
            child: posBottomBar('products', context)),
      ),
    );
  }

  Widget _filterDrawer() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      padding: EdgeInsets.only(bottom: MySize.size14!),
      color: themeData.colorScheme.background,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding:
                  EdgeInsets.only(top: MySize.size24!, bottom: MySize.size24!),
              alignment: Alignment.center,
              child: Center(
                child: Text(
                  AppLocalizations.of(context).translate('sort'),
                  style: AppTheme.getTextStyle(themeData.textTheme.titleMedium,
                      fontWeight: 700, color: themeData.colorScheme.primary),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        setState(() {
                          if (byAlphabets == null) {
                            byAlphabets = 0;
                          } else if (byAlphabets == 0) {
                            byAlphabets = 1;
                          } else {
                            byAlphabets = null;
                          }
                        });
                        products = [];
                        offset = 0;
                        productList();
                      },
                      child: Container(
                        margin: EdgeInsets.only(left: MySize.size16!),
                        decoration: BoxDecoration(
                          color: themeData.colorScheme.background,
                          borderRadius:
                              BorderRadius.all(Radius.circular(MySize.size16!)),
                          boxShadow: [
                            BoxShadow(
                              color: themeData.cardTheme.shadowColor!
                                  .withAlpha(48),
                              blurRadius: (byAlphabets != null) ? 5 : 0,
                              offset: (byAlphabets != null)
                                  ? Offset(3, 3)
                                  : Offset(0, 0),
                            )
                          ],
                          // : null,
                        ),
                        padding: EdgeInsets.all(MySize.size12!),
                        child: Row(
                          children: [
                            Text(
                              "A",
                              style: AppTheme.getTextStyle(
                                  themeData.textTheme.titleMedium,
                                  fontWeight: 700,
                                  color: (byAlphabets != null)
                                      ? themeData.colorScheme.primary
                                      : Colors.grey),
                            ),
                            Icon(
                              (byAlphabets == 1)
                                  ? MdiIcons.arrowLeftBold
                                  : MdiIcons.arrowRightBold,
                              color: (byAlphabets != null)
                                  ? themeData.colorScheme.primary
                                  : Colors.grey,
                              size: 22,
                            ),
                            Text(
                              "Z",
                              style: AppTheme.getTextStyle(
                                  themeData.textTheme.titleMedium,
                                  fontWeight: 700,
                                  color: (byAlphabets != null)
                                      ? themeData.colorScheme.primary
                                      : Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        setState(() {
                          if (byPrice == null) {
                            byPrice = 0;
                          } else if (byPrice == 0) {
                            byPrice = 1;
                          } else {
                            byPrice = null;
                          }
                        });
                        products = [];
                        offset = 0;
                        productList();
                      },
                      child: Container(
                        margin: EdgeInsets.only(left: MySize.size16!),
                        decoration: BoxDecoration(
                          color: themeData.colorScheme.background,
                          borderRadius:
                              BorderRadius.all(Radius.circular(MySize.size16!)),
                          boxShadow: [
                            BoxShadow(
                              color: themeData.cardTheme.shadowColor!
                                  .withAlpha(48),
                              blurRadius: (byPrice != null) ? 5 : 0,
                              offset: (byPrice != null)
                                  ? Offset(3, 3)
                                  : Offset(0, 0),
                            )
                          ],
                          // : null,
                        ),
                        padding: EdgeInsets.all(MySize.size12!),
                        child: Row(
                          children: [
                            Text(
                              AppLocalizations.of(context).translate('price'),
                              style: AppTheme.getTextStyle(
                                  themeData.textTheme.titleMedium,
                                  fontWeight: 700,
                                  color: (byPrice != null)
                                      ? themeData.colorScheme.primary
                                      : Colors.grey),
                            ),
                            Icon(
                              (byPrice == 1)
                                  ? MdiIcons.arrowDownBold
                                  : MdiIcons.arrowUpBold,
                              color: (byPrice != null)
                                  ? themeData.colorScheme.primary
                                  : Colors.grey,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(),
              ],
            ),
            Container(
              alignment: Alignment.center,
              child: Center(
                child: Text(
                  AppLocalizations.of(context).translate('filter'),
                  style: AppTheme.getTextStyle(themeData.textTheme.titleMedium,
                      fontWeight: 700, color: themeData.colorScheme.primary),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                    padding: EdgeInsets.only(
                        left: MySize.size16!, right: MySize.size16!),
                    child: CheckboxListTile(
                      title: Text(
                          AppLocalizations.of(context).translate('in_stock')),
                      controlAffinity: ListTileControlAffinity.leading,
                      value: inStock,
                      onChanged: (newValue) {
                        setState(() {
                          inStock = newValue!;
                        });
                        products = [];
                        offset = 0;
                        productList();
                      },
                    )),
                Divider(),
                Container(
                  padding: EdgeInsets.only(
                      left: MySize.size16!,
                      right: MySize.size16!,
                      top: MySize.size16!),
                  child: Text(
                    AppLocalizations.of(context).translate('categories'),
                    style: AppTheme.getTextStyle(themeData.textTheme.bodyLarge,
                        fontWeight: 600, letterSpacing: 0),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(
                      left: MySize.size16!,
                      right: MySize.size16!,
                      top: MySize.size8!),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                        isExpanded: true,
                        dropdownColor: themeData.colorScheme.background,
                        icon: Icon(
                          Icons.arrow_drop_down,
                        ),
                        value: categoryId,
                        items: _categoryMenuItems,
                        onChanged: (int? newValue) {
                          setState(() {
                            subCategoryId = 0;
                            categoryId = newValue!;
                            subCategoryList(categoryId);
                          });

                          products = [];
                          offset = 0;
                          productList();
                        }),
                  ),
                ),
                Divider(),
                Container(
                  padding: EdgeInsets.only(
                      left: MySize.size16!,
                      right: MySize.size16!,
                      top: MySize.size16!),
                  child: Text(
                    AppLocalizations.of(context).translate('sub_categories'),
                    style: AppTheme.getTextStyle(themeData.textTheme.bodyLarge,
                        fontWeight: 600, letterSpacing: 0),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(
                      left: MySize.size16!,
                      right: MySize.size16!,
                      top: MySize.size8!),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                        isExpanded: true,
                        dropdownColor: themeData.colorScheme.background,
                        icon: Icon(
                          Icons.arrow_drop_down,
                        ),
                        value: subCategoryId,
                        items: _subCategoryMenuItems,
                        onChanged: (int? newValue) {
                          setState(() {
                            subCategoryId = newValue!;
                          });

                          products = [];
                          offset = 0;
                          productList();
                        }),
                  ),
                ),
                Divider(),
                Container(
                  padding: EdgeInsets.only(
                      left: MySize.size16!,
                      right: MySize.size16!,
                      top: MySize.size16!),
                  child: Text(
                    AppLocalizations.of(context).translate('brands'),
                    style: AppTheme.getTextStyle(themeData.textTheme.bodyLarge,
                        fontWeight: 600, letterSpacing: 0),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(
                      left: MySize.size16!, right: MySize.size16!, top: 0),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                        isExpanded: true,
                        dropdownColor: themeData.colorScheme.background,
                        icon: Icon(
                          Icons.arrow_drop_down,
                        ),
                        value: brandId,
                        items: _brandsMenuItems,
                        onChanged: (int? newValue) {
                          setState(() {
                            brandId = newValue!;
                          });
                          products = [];
                          offset = 0;
                          productList();
                        }),
                  ),
                ),
                Divider()
              ],
            ),
            Container(
              alignment: Alignment.center,
              child: Center(
                child: Text(
                  AppLocalizations.of(context).translate('group_prices'),
                  style: AppTheme.getTextStyle(themeData.textTheme.titleMedium,
                      fontWeight: 700, color: themeData.colorScheme.primary),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                  left: MySize.size16!, right: MySize.size16!, top: 0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton(
                    isExpanded: true,
                    dropdownColor: themeData.colorScheme.background,
                    icon: Icon(
                      Icons.arrow_drop_down,
                    ),
                    value: usePriceGroup,
                    items: _priceGroupMenuItems,
                    onChanged: (bool? newValue) async {
                      await _showCartResetDialogForPriceGroup();
                      setState(() {
                        usePriceGroup = newValue!;
                        if (changePriceGroup) {
                          //reset cart items
                          Sell().resetCart();
                          //reset all filters & search
                          brandId = 0;
                          categoryId = 0;
                          searchController.clear();
                          inStock = true;
                          cartCount = 0;

                          products = [];
                          offset = 0;
                          productList();
                        }
                      });
                    }),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget filter(_scaffoldKey) {
    return Padding(
      padding: EdgeInsets.all(MySize.size16!),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Form(
              key: _formKey,
              child: TextFormField(
                  style: AppTheme.getTextStyle(themeData.textTheme.titleSmall,
                      letterSpacing: 0, fontWeight: 500),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).translate('search'),
                    hintStyle: AppTheme.getTextStyle(
                        themeData.textTheme.titleSmall,
                        letterSpacing: 0,
                        fontWeight: 500),
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
                    prefixIcon: IconButton(
                      icon: Icon(
                        MdiIcons.magnify,
                        size: MySize.size22,
                        color:
                            themeData.colorScheme.onBackground.withAlpha(150),
                      ),
                      onPressed: () {},
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.only(right: MySize.size16!),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  controller: searchController,
                  onEditingComplete: () {
                    products = [];
                    offset = 0;
                    productList();
                  }),
            ),
          ),
          InkWell(
            onTap: () async {
              var barcode = await Helper().barcodeScan();
              await getScannedProduct(barcode);
            },
            child: Container(
              margin: EdgeInsets.only(left: MySize.size16!),
              decoration: BoxDecoration(
                color: themeData.colorScheme.background,
                borderRadius: BorderRadius.all(Radius.circular(MySize.size16!)),
                boxShadow: [
                  BoxShadow(
                    color: themeData.cardTheme.shadowColor!.withAlpha(48),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  )
                ],
              ),
              padding: EdgeInsets.all(MySize.size12!),
              child: Icon(
                MdiIcons.barcode,
                color: themeData.colorScheme.primary,
                size: 22,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              _scaffoldKey.currentState.openEndDrawer();
            },
            child: Container(
              margin: EdgeInsets.only(left: MySize.size16!),
              decoration: BoxDecoration(
                color: themeData.colorScheme.background,
                borderRadius: BorderRadius.all(Radius.circular(MySize.size16!)),
                boxShadow: [
                  BoxShadow(
                    color: themeData.cardTheme.shadowColor!.withAlpha(48),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  )
                ],
              ),
              padding: EdgeInsets.all(MySize.size12!),
              child: Icon(
                MdiIcons.tune,
                color: themeData.colorScheme.primary,
                size: 22,
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              setState(() {
                gridView = !gridView;
              });
            },
            child: Container(
              margin: EdgeInsets.only(left: MySize.size16!),
              decoration: BoxDecoration(
                color: themeData.colorScheme.background,
                borderRadius: BorderRadius.all(Radius.circular(MySize.size16!)),
                boxShadow: [
                  BoxShadow(
                    color: themeData.cardTheme.shadowColor!.withAlpha(48),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  )
                ],
              ),
              padding: EdgeInsets.all(MySize.size12!),
              child: Icon(
                (gridView) ? MdiIcons.viewList : MdiIcons.viewGrid,
                color: themeData.colorScheme.primary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //add product to cart after scanning barcode
  getScannedProduct(String barcode) async {
    if (canMakeSell) {
      await Variations()
          .get(
              locationId: selectedLocationId,
              barcode: barcode,
              offset: 0,
              searchTerm: searchController.text)
          .then((value) async {
        if (canAddSell) {
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
                  product, argument != null ? argument!['sellId'] : null);
              if (argument != null) {
                selectedLocationId = argument!['locationId'];
              }
            } else {
              Fluttertoast.showToast(
                  msg:
                      "${AppLocalizations.of(context).translate("out_of_stock")}");
            }
          } else {
            Fluttertoast.showToast(
                msg:
                    "${AppLocalizations.of(context).translate("no_product_found")}");
          }
        } else {
          Fluttertoast.showToast(
              msg:
                  "${AppLocalizations.of(context).translate("no_sells_permission")}");
        }
      });
    } else {
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context).translate('no_subscription_found'));
    }
  }

  Widget _productsList() {
    return (products.length == 0)
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty),
                Text(AppLocalizations.of(context)
                    .translate('no_products_found')),
              ],
            ),
          )
        : Container(
            child: (gridView)
                ? GridView.builder(
                    padding: EdgeInsets.only(
                        bottom: MySize.size16!,
                        left: MySize.size16!,
                        right: MySize.size16!),
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                    itemCount: products.length,
                    gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: MySize.size16!,
                      crossAxisSpacing: MySize.size16!,
                      childAspectRatio:
                          findAspectRatio(MediaQuery.of(context).size.width),
                    ),
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () async {
                          onTapProduct(index);
                        },
                        child: _ProductGridWidget(
                          name: products[index]['display_name'],
                          image: products[index]['product_image_url'],
                          qtyAvailable: (products[index]['enable_stock'] != 0)
                              ? products[index]['stock_available'].toString()
                              : '-',
                          price: double.parse(
                              products[index]['unit_price'].toString()),
                          symbol: symbol,
                        ),
                      );
                    },
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () async {
                          onTapProduct(index);
                        },
                        child: _ProductListWidget(
                          name: products[index]['display_name'],
                          image: products[index]['product_image_url'],
                          qtyAvailable: (products[index]['enable_stock'] != 0)
                              ? products[index]['stock_available'].toString()
                              : '-',
                          price: double.parse(
                              products[index]['unit_price'].toString()),
                          symbol: symbol,
                        ),
                      );
                    },
                  ),
          );
  }

  //onTap product
  onTapProduct(int index) async {
    if (canAddSell) {
      if (canMakeSell) {
        if (products[index]['stock_available'] > 0) {
          Fluttertoast.showToast(
              msg: AppLocalizations.of(context).translate('added_to_cart'));
          await Sell().addToCart(
              products[index], argument != null ? argument!['sellId'] : null);
          if (argument != null) {
            selectedLocationId = argument!['locationId'];
          }
        } else {
          Fluttertoast.showToast(
              msg: "${AppLocalizations.of(context).translate("out_of_stock")}");
        }
      } else {
        Fluttertoast.showToast(
            msg:
                "${AppLocalizations.of(context).translate("no_sells_permission")}");
      }
    } else {
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context).translate('no_subscription_found'));
    }
  }

  setLocationMap() async {
    await System().get('location').then((value) async {
      value.forEach((element) {
        if (element['is_active'].toString() == '1') {
          setState(() {
            locationListMap.add({
              'id': element['id'],
              'name': element['name'],
              'selling_price_group_id': element['selling_price_group_id']
            });
          });
        }
      });
      await priceGroupList();
    });
  }

  setDefaultLocation(defaultLocation) {
    if (defaultLocation != 0) {
      setState(() {
        selectedLocationId = defaultLocation;
      });
    } else if (locationListMap.length == 2) {
      setState(() {
        selectedLocationId = locationListMap[1]['id'] as int;
      });
    }
  }

  Widget locations() {
    return DropdownButtonHideUnderline(
      child: DropdownButton(
          dropdownColor: themeData.colorScheme.background,
          icon: Icon(
            Icons.arrow_drop_down,
          ),
          value: selectedLocationId,
          items: locationListMap.map<DropdownMenuItem<int>>((Map value) {
            return DropdownMenuItem<int>(
                value: value['id'],
                child: SizedBox(
                  width: MySize.screenWidth! * 0.4,
                  child: Text('${value['name']}',
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(fontSize: 15)),
                ));
          }).toList(),
          onTap: () {
            if (locationListMap.length <= 2) {
              canChangeLocation = false;
            }
          },
          onChanged: (int? newValue) async {
            // show a confirmation if there location is changed.
            if (canChangeLocation) {
              if (selectedLocationId == newValue) {
                changeLocation = false;
              } else if (selectedLocationId != 0) {
                await _showCartResetDialogForLocation();
                await priceGroupList();
              } else {
                changeLocation = true;
                await priceGroupList();
              }
              setState(() {
                if (changeLocation) {
                  //reset cart items
                  Sell().resetCart();
                  selectedLocationId = newValue!;
                  //reset all filters & search
                  brandId = 0;
                  categoryId = 0;
                  searchController.clear();
                  inStock = true;
                  cartCount = 0;

                  products = [];
                  offset = 0;
                  productList();
                }
              });
            } else {
              Fluttertoast.showToast(
                  msg: AppLocalizations.of(context)
                      .translate('cannot_change_location'));
            }
          }),
    );
  }

  Future<void> _showCartResetDialogForLocation() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text(AppLocalizations.of(context).translate('change_location')),
          content: Text(AppLocalizations.of(context)
              .translate('all_items_in_cart_will_be_remove')),
          actions: [
            TextButton(
                onPressed: () {
                  changeLocation = false;
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context).translate('no'))),
            TextButton(
                onPressed: () {
                  changeLocation = true;
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context).translate('yes')))
          ],
        );
      },
    );
  }

  Future<void> _showCartResetDialogForPriceGroup() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)
              .translate('change_selling_price_group')),
          content: Text(AppLocalizations.of(context)
              .translate('all_items_in_cart_will_be_remove')),
          actions: [
            TextButton(
                onPressed: () {
                  changePriceGroup = false;
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context).translate('no'))),
            TextButton(
                onPressed: () {
                  changePriceGroup = true;
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context).translate('yes')))
          ],
        );
      },
    );
  }
}

class _ProductGridWidget extends StatefulWidget {
  final String? name, image, symbol;
  final String? qtyAvailable;
  final double? price;

  const _ProductGridWidget(
      {Key? key,
      @required this.name,
      @required this.image,
      @required this.qtyAvailable,
      @required this.price,
      @required this.symbol})
      : super(key: key);

  @override
  _ProductGridWidgetState createState() => _ProductGridWidgetState();
}

class _ProductGridWidgetState extends State<_ProductGridWidget> {
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);

  @override
  Widget build(BuildContext context) {
    String key = Generator.randomString(10);
    themeData = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: themeData.cardTheme.color,
        borderRadius: BorderRadius.all(Radius.circular(MySize.size8!)),
        boxShadow: [
          BoxShadow(
            color: themeData.cardTheme.shadowColor!.withAlpha(12),
            blurRadius: 4,
            spreadRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(MySize.size2!),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Hero(
                tag: key,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(MySize.size8!),
                      topRight: Radius.circular(MySize.size8!)),
                  child: CachedNetworkImage(
                      width: MediaQuery.of(context).size.width,
                      height: MySize.size140,
                      fit: BoxFit.fitHeight,
                      errorWidget: (context, url, error) =>
                          Image.asset('assets/images/default_product.png'),
                      placeholder: (context, url) =>
                          Image.asset('assets/images/default_product.png'),
                      imageUrl: widget.image ?? ''),
                ),
              ),
            ],
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.only(left: MySize.size2!, right: MySize.size2!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(widget.name!,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.getTextStyle(themeData.textTheme.titleSmall,
                        fontWeight: 500, letterSpacing: 0)),
                Container(
                  margin: EdgeInsets.only(top: MySize.size4!),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        widget.symbol! + Helper().formatCurrency(widget.price),
                        style: AppTheme.getTextStyle(
                            themeData.textTheme.bodyMedium,
                            fontWeight: 700,
                            letterSpacing: 0),
                      ),
                      Container(
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
                          children: <Widget>[
                            Icon(
                              MdiIcons.stocking,
                              color: themeData.colorScheme.onPrimary,
                              size: MySize.size12,
                            ),
                            Container(
                              margin: EdgeInsets.only(left: MySize.size4!),
                              child: (widget.qtyAvailable != '-')
                                  ? Text(
                                      Helper()
                                          .formatQuantity(widget.qtyAvailable),
                                      style: AppTheme.getTextStyle(
                                          themeData.textTheme.bodySmall,
                                          fontSize: 11,
                                          color:
                                              themeData.colorScheme.onPrimary,
                                          fontWeight: 600))
                                  : Text('-'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductListWidget extends StatefulWidget {
  final String? name, image, symbol;
  final String? qtyAvailable;
  final double? price;

  const _ProductListWidget(
      {Key? key,
      @required this.name,
      @required this.image,
      @required this.qtyAvailable,
      @required this.price,
      @required this.symbol})
      : super(key: key);

  @override
  _ProductListWidgetState createState() => _ProductListWidgetState();
}

class _ProductListWidgetState extends State<_ProductListWidget> {
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: themeData.cardTheme.color,
        borderRadius: BorderRadius.all(Radius.circular(MySize.size8!)),
        boxShadow: [
          BoxShadow(
            color: themeData.cardTheme.shadowColor!.withAlpha(12),
            blurRadius: 4,
            spreadRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(MySize.size8!),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(MySize.size30!),
          child: CachedNetworkImage(
              errorWidget: (context, url, error) =>
                  Image.asset('assets/images/default_product.png'),
              placeholder: (context, url) =>
                  Image.asset('assets/images/default_product.png'),
              imageUrl: widget.image ?? ''),
        ),
        title: Text(widget.name!,
            style: AppTheme.getTextStyle(themeData.textTheme.titleSmall,
                fontWeight: 500, letterSpacing: 0)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Text(
              widget.symbol! + Helper().formatCurrency(widget.price),
              style: AppTheme.getTextStyle(themeData.textTheme.bodyMedium,
                  fontWeight: 700, letterSpacing: 0),
            ),
            Container(
              width: MySize.size80,
              decoration: BoxDecoration(
                  color: themeData.colorScheme.primary,
                  borderRadius:
                      BorderRadius.all(Radius.circular(MySize.size4!))),
              padding: EdgeInsets.only(
                  left: MySize.size6!,
                  right: MySize.size8!,
                  top: MySize.size2!,
                  bottom: MySize.getScaledSizeHeight(3.5)),
              child: Row(
                children: <Widget>[
                  Icon(
                    MdiIcons.stocking,
                    color: themeData.colorScheme.onPrimary,
                    size: MySize.size12,
                  ),
                  Container(
                    margin: EdgeInsets.only(left: MySize.size4!),
                    child: (widget.qtyAvailable != '-')
                        ? Text(Helper().formatQuantity(widget.qtyAvailable),
                            style: AppTheme.getTextStyle(
                                themeData.textTheme.bodySmall,
                                fontSize: 11,
                                color: themeData.colorScheme.onPrimary,
                                fontWeight: 600))
                        : Text('-'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
