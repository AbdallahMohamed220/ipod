class ProductModel {
  var productMap;

  product(element, price) {
    productMap = {
      'variation_id': element['variation_id'],
      'product_id': element['product_id'],
      'tax_rate_id': element['tax_id'],
      'discount_type': element['discount_type'],
      'quantity': element['quantity'],
      'discount_amount': element['discount_amount'],
      'stock_available': element['stock_available'],
      'display_name': element['display_name'],
      'product_image_url': element['product_image_url'],
      'enable_stock': element['enable_stock'],
      'unit_price': price ?? element['sell_price_inc_tax']
    };
    return productMap;
  }
}
