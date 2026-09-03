
import '../../../storage/file_service.dart';
import '../models/supplier_model.dart';

class SupplierService {
  final FileService _fileService = FileService();

  final String fileName = "suppliers.json";

  Future<void> saveSuppliers(List<Supplier> suppliers) async {
    final data = suppliers.map((e) => e.toJson()).toList();
    await _fileService.saveFile(fileName, data);
  }

  Future<List<Supplier>> getSuppliers() async {
    final data = await _fileService.readFile(fileName);

    return data.map<Supplier>((e) {
      return Supplier.fromJson(Map<String, dynamic>.from(e));
    }).toList();
  }
}

