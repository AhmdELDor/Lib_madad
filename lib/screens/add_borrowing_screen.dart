import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/borrowing.dart';
import '../models/book.dart';
import '../models/client.dart';
import '../providers/library_provider.dart';

class AddBorrowingScreen extends StatefulWidget {
  final int? initialBookId;
  final int? initialClientId;

  const AddBorrowingScreen({super.key, this.initialBookId, this.initialClientId});

  @override
  State<AddBorrowingScreen> createState() => _AddBorrowingScreenState();
}

class _AddBorrowingScreenState extends State<AddBorrowingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  int? _selectedBookId;
  int? _selectedClientId;
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  final _donationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedBookId = widget.initialBookId;
    _selectedClientId = widget.initialClientId;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LibraryProvider>(context);
    final availableBooks = provider.books.where((b) => b.isAvailable).toList();
    final clients = provider.clients;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل إعارة جديدة'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Client Dropdown
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'اختر العميل', border: OutlineInputBorder()),
                value: _selectedClientId,
                items: clients.map((Client client) {
                  return DropdownMenuItem<int>(
                    value: client.id,
                    child: Text(client.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClientId = value;
                  });
                },
                validator: (value) => value == null ? 'يرجى اختيار العميل' : null,
              ),
              const SizedBox(height: 20),

              // Book Dropdown
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'اختر الكتاب', border: OutlineInputBorder()),
                value: _selectedBookId,
                items: availableBooks.map((Book book) {
                  return DropdownMenuItem<int>(
                    value: book.id,
                    child: Text(book.title),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBookId = value;
                  });
                },
                validator: (value) => value == null ? 'يرجى اختيار الكتاب' : null,
              ),
              const SizedBox(height: 20),

              // Deadline Picker
              ListTile(
                title: const Text('تاريخ الإرجاع'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(_deadline)),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5), side: const BorderSide(color: Colors.grey)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _deadline,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _deadline = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Donation Field
              TextFormField(
                controller: _donationController,
                decoration: const InputDecoration(
                  labelText: 'مبلغ التبرع (اختياري)',
                  border: OutlineInputBorder(),
                  suffixText: 'د.أ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final borrowing = Borrowing(
                      bookId: _selectedBookId!,
                      clientId: _selectedClientId!,
                      borrowDate: DateTime.now(),
                      deadline: _deadline,
                      donationAmount: double.tryParse(_donationController.text),
                      isReturned: false,
                    );

                    Provider.of<LibraryProvider>(context, listen: false).borrowBook(borrowing);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                child: const Text('تأكيد الإعارة', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
