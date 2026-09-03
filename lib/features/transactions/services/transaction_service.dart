
import '../../../storage/file_service.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FileService _fileService = FileService();

  final String fileName = "transactions.json";

  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final data = transactions.map((e) => e.toJson()).toList();
    await _fileService.saveFile(fileName, data);
  }

  Future<List<TransactionModel>> getTransactions() async {
    final data = await _fileService.readFile(fileName);

    return data.map<TransactionModel>((e) {
      return TransactionModel.fromJson(
        Map<String, dynamic>.from(e),
      );
    }).toList();
  }
}

