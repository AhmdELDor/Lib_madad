import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/library_provider.dart';

class AddBookScreen extends StatefulWidget {
  final Book? book;
  const AddBookScreen({super.key, this.book});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _genreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      _titleController.text = widget.book!.title;
      _authorController.text = widget.book!.author;
      _genreController.text = widget.book!.genre;
      _descriptionController.text = widget.book!.description ?? '';
      _quantityController.text = widget.book!.quantity.toString();
      _imagePath = widget.book!.imagePath;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  void _saveBook() {
    if (_formKey.currentState!.validate()) {
      final quantity = int.tryParse(_quantityController.text) ?? 1;
      
      if (widget.book != null) {
        // Update existing
        final availableQty = quantity - widget.book!.borrowCount;
        final updatedBook = Book(
          id: widget.book!.id,
          title: _titleController.text,
          author: _authorController.text,
          genre: _genreController.text,
          description: _descriptionController.text,
          imagePath: _imagePath,
          quantity: quantity,
          availableQuantity: availableQty > 0 ? availableQty : 0,
          isAvailable: availableQty > 0,
          borrowCount: widget.book!.borrowCount,
        );

        Provider.of<LibraryProvider>(context, listen: false).updateBook(updatedBook);
      } else {
        // Add new
        final newBook = Book(
          title: _titleController.text,
          author: _authorController.text,
          genre: _genreController.text,
          description: _descriptionController.text,
          imagePath: _imagePath,
          quantity: quantity,
          availableQuantity: quantity,
          isAvailable: quantity > 0,
          borrowCount: 0,
        );

        Provider.of<LibraryProvider>(context, listen: false).addBook(newBook);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book != null ? 'تعديل الكتاب' : 'إضافة كتاب جديد'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 160,
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _imagePath!.contains('assets') 
                                ? Image.asset(_imagePath!, fit: BoxFit.cover)
                                : (kIsWeb 
                                    ? Image.network(_imagePath!, fit: BoxFit.cover) 
                                    : Image.file(File(_imagePath!), fit: BoxFit.cover)),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('صورة الغلاف', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'عنوان الكتاب', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'يرجى إدخال العنوان' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'المؤلف', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'يرجى إدخال اسم المؤلف' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _genreController,
                decoration: const InputDecoration(labelText: 'التصنيف (مثال: رواية، تاريخ...)', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'يرجى إدخال التصنيف' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'الكمية المتوفرة (المخزون)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'يرجى إدخال الكمية';
                  if (int.tryParse(value) == null) return 'يرجى إدخال رقم صحيح';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'وصف الكتاب', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveBook,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(widget.book != null ? 'حفظ التعديلات' : 'حفظ الكتاب', style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
