import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/transaction/transaction_runner.dart';

class DriftTransactionRunner implements TransactionRunner {
  const DriftTransactionRunner(this._database);
  final AppDatabase _database;

  @override
  Future<T> run<T>(Future<T> Function() action) =>
      _database.transaction(action);
}
