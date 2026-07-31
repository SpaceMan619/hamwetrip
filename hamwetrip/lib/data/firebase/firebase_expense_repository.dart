import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../../core/error/app_error.dart';
import '../../data/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import 'firebase_error_mapper.dart';

/// Firebase-backed [ExpenseRepository].
///
/// Expenses live as a subcollection under each trip:
/// `trips/{tripId}/expenses/{expenseId}`.
/// Balances live as a subcollection:
/// `trips/{tripId}/balances/{balanceId}`.
class FirebaseExpenseRepository implements ExpenseRepository {
  FirebaseExpenseRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final fb_auth.FirebaseAuth _auth;

  CollectionReference<Map<String, Object?>> _expensesOf(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('expenses');

  CollectionReference<Map<String, Object?>> _balancesOf(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('balances');

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AuthError(message: 'You need to be signed in to do that.');
    }
    return uid;
  }

  @override
  Stream<List<Expense>> watchExpenses(String tripId) {
    return _expensesOf(tripId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Expense.fromMap(d.id, d.data())).toList(),
        )
        .mapFirebaseErrors();
  }

  @override
  Stream<List<Balance>> watchBalances(String tripId) {
    return _balancesOf(tripId)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final data = d.data();
            return Balance(
              fromInitials: data['fromInitials'] as String? ?? '',
              fromName: data['fromName'] as String? ?? '',
              toInitials: data['toInitials'] as String? ?? '',
              toName: data['toName'] as String? ?? '',
              amount: (data['amount'] as num?)?.toDouble() ?? 0,
            );
          }).toList(),
        )
        .mapFirebaseErrors();
  }

  @override
  Future<Expense> createExpense({
    required String tripId,
    required String description,
    required double amount,
    required String paidByInitials,
    required String paidByName,
    required String categoryEmoji,
    required String category,
    required List<String> splitAmongInitials,
  }) async {
    _requireUid();
    try {
      final ref = _expensesOf(tripId).doc();
      final expense = Expense(
        id: ref.id,
        description: description,
        amount: amount,
        paidByInitials: paidByInitials,
        paidByName: paidByName,
        categoryEmoji: categoryEmoji,
        category: category,
        splitAmongInitials: splitAmongInitials,
        date: DateTime.now(),
      );
      final data = expense.toMap()
        ..['createdAt'] = FieldValue.serverTimestamp();
      await ref.set(data);
      return expense;
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<void> settleExpense({
    required String tripId,
    required String expenseId,
  }) async {
    _requireUid();
    try {
      await _expensesOf(tripId).doc(expenseId).update({'isSettled': true});
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<void> settleBalance({
    required String tripId,
    required Balance balance,
  }) async {
    _requireUid();
    try {
      // Mark the balance as settled by deleting it (or marking it).
      final query = await _balancesOf(tripId)
          .where('fromInitials', isEqualTo: balance.fromInitials)
          .where('toInitials', isEqualTo: balance.toInitials)
          .get();
      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<void> deleteExpense({
    required String tripId,
    required String expenseId,
  }) async {
    _requireUid();
    try {
      await _expensesOf(tripId).doc(expenseId).delete();
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }
}
