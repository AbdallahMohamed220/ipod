import 'package:intl/intl.dart';

class ExpenseManagement {
  //create expense map
  Map<String, dynamic> createExpense(
      {int? locId,
      double? finalTotal,
      int? taxId,
      String? note,
      double? amount,
      int? accountId,
      int? expenseCategoryId,
      int? expenseSubCategoryId,
      String? method}) {
    Map<String, dynamic> expense = {
      'location_id': locId,
      'final_total': finalTotal,
      'transaction_date':
          DateFormat('yyyy-MM-dd hh:mm:ss').format(DateTime.now()),
      'tax_rate_id': taxId,
      'additional_notes': note,
      if (expenseCategoryId != 0) 'expense_category_id': expenseCategoryId,
      if (expenseSubCategoryId != 0)
        'expense_sub_category_id': expenseSubCategoryId,
      "payment": [
        {"amount": amount, "method": method, "account_id": accountId}
      ]
    };
    return expense;
  }
}
