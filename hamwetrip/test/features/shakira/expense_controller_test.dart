import 'package:flutter_test/flutter_test.dart';
import 'package:hamwetrip/features/shakira/presentation/demo/controllers/demo_expense_controller.dart';
import 'package:hamwetrip/features/shakira/data/demo/mock_expenses.dart';

void main() {
  late DemoExpenseController controller;

  setUp(() {
    controller = DemoExpenseController();
  });

  group('DemoExpenseController', () {
    test('initial load should have 5 expenses and 3 balances', () {
      expect(controller.expenses.length, 5);
      expect(controller.pendingBalances.length, 3);
    });

    test('totals should be calculated in RWF correctly', () {
      // 85k + 45k + 120k + 36k + 20k = 306,000 RWF
      expect(controller.totalSpent, 306000.0);

      // 20k (SK->RM) + 40k (KZ->RM) + 46k (AJ->RM) = 106,000 RWF
      expect(controller.totalOwed, 106000.0);
    });

    test('markExpenseSettled should track the state', () {
      expect(controller.isExpenseSettled('exp_1'), false);

      controller.markExpenseSettled('exp_1');

      expect(controller.isExpenseSettled('exp_1'), true);
      // Calling again shouldn't duplicate or cause issues
      controller.markExpenseSettled('exp_1');
      expect(controller.isExpenseSettled('exp_1'), true);
    });

    test('settleBalance should remove it from pending list', () {
      // Get the first balance (SK owes RM 20k)
      final balanceToSettle = mockBalances.first;
      expect(controller.pendingBalances.length, 3);

      controller.settleBalance(balanceToSettle);

      expect(controller.pendingBalances.length, 2);
      // Total owed should drop by 20,000
      expect(controller.totalOwed, 86000.0);
    });

    test('category filter should work', () {
      controller.setCategory('Food');

      // Should only show Lunch (exp_2) and Dinner (exp_4)
      expect(controller.expenses.length, 2);
      expect(controller.expenses.every((e) => e.category == 'Food'), true);
    });

    test('search should filter expenses by description', () {
      controller.search('van');

      expect(controller.expenses.length, 1);
      expect(controller.expenses.first.description.contains('van'), true);
    });

    test('search should filter expenses by paidByName', () {
      controller.search('Aime');

      expect(controller.expenses.length, 1);
      expect(controller.expenses.first.paidByName, 'Aime');
    });

    test('clearSearch should restore all expenses', () {
      controller.search('van');
      expect(controller.expenses.length, 1);

      controller.clearSearch();
      expect(controller.expenses.length, 5);
    });

    test('deleteExpense should remove it from the list', () {
      controller.deleteExpense('exp_1');

      expect(controller.expenses.length, 4);
      // Total spent should drop by 85,000
      expect(controller.totalSpent, 221000.0);
      expect(controller.expenses.any((e) => e.id == 'exp_1'), false);
    });
  });
}
