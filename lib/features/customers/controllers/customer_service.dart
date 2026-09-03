
import '../../../storage/file_service.dart';
import '../models/customer_model.dart';

class CustomerService {
  final FileService _fileService = FileService();

  final String fileName = "customers.json";

  // =======================
  // 💾 حفظ الزبائن
  // =======================
  Future<void> saveCustomers(List<Customer> customers) async {
    final data = customers.map((e) => e.toJson()).toList();
    await _fileService.saveFile(fileName, data);
  }

  // =======================
  // 📥 قراءة الزبائن
  // =======================
  Future<List<Customer>> getCustomers() async {
    final data = await _fileService.readFile(fileName);

    return data.map<Customer>((e) {
      return Customer.fromJson(Map<String, dynamic>.from(e));
    }).toList();
  }
}

