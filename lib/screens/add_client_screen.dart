import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../providers/library_provider.dart';

class AddClientScreen extends StatefulWidget {
  final Client? client;
  const AddClientScreen({super.key, this.client});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.client != null) {
      _nameController.text = widget.client!.name;
      _phoneController.text = widget.client!.phone;
    }
  }

  void _saveClient() {
    if (_formKey.currentState!.validate()) {
      if (widget.client != null) {
        final updatedClient = Client(
          id: widget.client!.id,
          name: _nameController.text,
          phone: _phoneController.text,
          borrowCount: widget.client!.borrowCount,
        );
        
        Provider.of<LibraryProvider>(context, listen: false).updateClient(updatedClient);
      } else {
        final newClient = Client(
          name: _nameController.text,
          phone: _phoneController.text,
          borrowCount: 0,
        );

        Provider.of<LibraryProvider>(context, listen: false).addClient(newClient);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client != null ? 'تعديل بيانات العميل' : 'إضافة عميل جديد'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم العميل', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'يرجى إدخال الاسم' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'يرجى إدخال رقم الهاتف' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveClient,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(widget.client != null ? 'حفظ التعديلات' : 'حفظ العميل', style: const TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
