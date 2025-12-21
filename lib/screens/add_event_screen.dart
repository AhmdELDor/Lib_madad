import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../providers/library_provider.dart';

class AddEventScreen extends StatefulWidget {
  final Event? event;
  const AddEventScreen({super.key, this.event});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _eventDate = DateTime.now();
  final List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description ?? '';
      _eventDate = widget.event!.date;
      if (widget.event!.imagePaths != null) {
        _imagePaths.addAll(widget.event!.imagePaths!);
      }
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _imagePaths.addAll(pickedFiles.map((e) => e.path));
      });
    }
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      if (widget.event != null) {
        final updatedEvent = Event(
          id: widget.event!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          date: _eventDate,
          imagePaths: _imagePaths.isNotEmpty ? _imagePaths : null,
        );
        
        Provider.of<LibraryProvider>(context, listen: false).updateEvent(updatedEvent);
      } else {
        final newEvent = Event(
          title: _titleController.text,
          description: _descriptionController.text,
          date: _eventDate,
          imagePaths: _imagePaths.isNotEmpty ? _imagePaths : null,
        );

        Provider.of<LibraryProvider>(context, listen: false).addEvent(newEvent);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event != null ? 'تعديل الفعالية' : 'إضافة فعالية جديدة'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'عنوان الفعالية', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'يرجى إدخال العنوان' : null,
              ),
              const SizedBox(height: 20),
              
              ListTile(
                title: const Text('تاريخ ووقت الفعالية'),
                subtitle: Text(DateFormat('yyyy-MM-dd – kk:mm').format(_eventDate)),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5), side: const BorderSide(color: Colors.grey)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _eventDate,
                    firstDate: DateTime(2000), // Allow past dates for editing
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_eventDate),
                    );
                    if (time != null) {
                      setState(() {
                        _eventDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'وصف الفعالية', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('إضافة صور'),
              ),
              const SizedBox(height: 10),
              
              if (_imagePaths.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imagePaths.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            kIsWeb 
                                ? Image.network(_imagePaths[index], width: 100, height: 100, fit: BoxFit.cover)
                                : Image.file(File(_imagePaths[index]), width: 100, height: 100, fit: BoxFit.cover),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _imagePaths.removeAt(index);
                                  });
                                },
                                child: const CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close, size: 15, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveEvent,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                child: Text(widget.event != null ? 'حفظ التعديلات' : 'حفظ الفعالية', style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
