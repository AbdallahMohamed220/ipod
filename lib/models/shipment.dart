class ShipmentModel {
  List<String> _shipmentStatus = [
    'Ordered',
    'Packed',
    'Shipped',
    'Delivered',
    'Cancelled'
  ];

  List<String> get shipmentStatus => _shipmentStatus;

  updateShipment({int? id, String? status, String? deliveredTo}) {
    Map<String, dynamic> shipment = {
      'id': id,
      'shipping_status': status!.toLowerCase(),
      'delivered_to': deliveredTo
    };
    return shipment;
  }
}
