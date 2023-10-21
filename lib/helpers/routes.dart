import '../pages/cart.dart';
import '../pages/checkout.dart';
import '../pages/contact_payment.dart';
import '../pages/contacts.dart';
import '../pages/customer.dart';
import '../pages/expenses.dart';
import '../pages/follow_up.dart';
import '../pages/field_force.dart';
import '../pages/home.dart';
import '../pages/login.dart';
import '../pages/products.dart';
import '../pages/sales.dart';
import '../pages/shipment.dart';
import '../pages/splash.dart';

class Routes {
  static generateRoute() {
    return {
      '/splash': (context) => Splash(),
      '/login': (context) => Login(),
      '/home': (context) => Home(),
      '/products': (context) => Products(),
      '/sale': (context) => Sales(),
      '/cart': (context) => Cart(),
      '/customer': (context) => Customer(),
      '/checkout': (context) => CheckOut(),
      '/expense': (context) => Expense(),
      '/contactPayment': (context) => ContactPayment(),
      '/shipment': (context) => Shipment(),
      '/leads': (context) => Contacts(),
      '/followUp': (context) => FollowUp(),
      '/fieldForce': (context) => FieldForce()
    };
  }
}
