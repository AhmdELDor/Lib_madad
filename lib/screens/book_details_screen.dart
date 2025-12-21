import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/feedback.dart';
import '../models/client.dart';
import '../models/book.dart';
import '../providers/library_provider.dart';
import 'add_book_screen.dart';

class BookDetailsScreen extends StatefulWidget {
  final int bookId;

  const BookDetailsScreen({super.key, required this.bookId});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final _commentController = TextEditingController();
  double _rating = 3.0;

  void _confirmDelete(BuildContext context, LibraryProvider provider, Book book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الكتاب'),
        content: Text('هل أنت متأكد من حذف كتاب "${book.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await provider.deleteBook(book.id!);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close details screen
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LibraryProvider>(context);
    // Handle case where book might be deleted
    final bookIndex = provider.books.indexWhere((b) => b.id == widget.bookId);
    if (bookIndex == -1) {
      return const Scaffold(body: Center(child: Text('الكتاب غير موجود')));
    }
    final book = provider.books[bookIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'تعديل',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddBookScreen(book: book)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'حذف',
            onPressed: () => _confirmDelete(context, provider, book),
          ),
        ],
      ),
      body: FutureBuilder<List<BookFeedback>>(
        future: provider.getFeedbacks(widget.bookId),
        builder: (context, snapshot) {
          final feedbacks = snapshot.data ?? [];
          final bookBorrowings = provider.borrowings.where((b) => b.bookId == widget.bookId).toList();
          bookBorrowings.sort((a, b) => b.borrowDate.compareTo(a.borrowDate));
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Section: Image (Left) + Details (Right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Side: Book Cover
                    Container(
                      width: 200,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: book.imagePath != null
                            ? (book.imagePath!.contains('assets') 
                                ? Image.asset(book.imagePath!, fit: BoxFit.cover)
                                : (kIsWeb 
                                    ? Image.network(book.imagePath!, fit: BoxFit.cover) 
                                    : Image.file(File(book.imagePath!), fit: BoxFit.cover)))
                            : const Center(child: Icon(FontAwesomeIcons.book, size: 60, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 30),
                    
                    // Right Side: Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Author
                          Text(
                            book.title,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'المؤلف: ${book.author}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 20),
                          
                          // Status & Stats
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: book.isAvailable ? Colors.green[100] : Colors.red[100],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: book.isAvailable ? Colors.green : Colors.red),
                                ),
                                child: Text(
                                  book.isAvailable 
                                      ? 'متاح (${book.availableQuantity}/${book.quantity})' 
                                      : 'غير متوفر (0/${book.quantity})',
                                  style: TextStyle(
                                    color: book.isAvailable ? Colors.green[800] : Colors.red[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.repeat, size: 16, color: Colors.blue),
                                    const SizedBox(width: 5),
                                    Text(
                                      'مرات الاستعارة: ${book.borrowCount}',
                                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          
                          // Description
                          const Text('نبذة عن الكتاب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 10),
                          Text(
                            book.description ?? 'لا يوجد وصف متاح.',
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                
                const Divider(height: 50),

                // Borrowing History Section
                const Text('سجل الاستعارة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 20),
                if (bookBorrowings.isEmpty)
                  const Text('لم يتم استعارة هذا الكتاب من قبل.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bookBorrowings.length,
                    itemBuilder: (context, index) {
                      final borrowing = bookBorrowings[index];
                      final clientIndex = provider.clients.indexWhere((c) => c.id == borrowing.clientId);
                      final client = clientIndex != -1 
                        ? provider.clients[clientIndex] 
                        : Client(name: 'عميل غير معروف', phone: '');
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: borrowing.isReturned ? Colors.green[100] : Colors.orange[100],
                            child: Icon(
                              borrowing.isReturned ? Icons.check : Icons.access_time,
                              color: borrowing.isReturned ? Colors.green : Colors.orange,
                            ),
                          ),
                          title: Text(client.name),
                          subtitle: Text(
                            'تاريخ الاستعارة: ${borrowing.borrowDate.toString().split(' ')[0]}\n'
                            'الموعد المحدد: ${borrowing.deadline.toString().split(' ')[0]}',
                          ),
                          trailing: Text(
                            borrowing.isReturned ? 'تم الإرجاع' : 'لم يتم الإرجاع',
                            style: TextStyle(
                              color: borrowing.isReturned ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                const Divider(height: 50),
                
                // Feedbacks Section
                const Text('التقييمات والآراء:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 20),
                      
                if (feedbacks.isEmpty)
                  const Text('لا توجد تقييمات بعد.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: feedbacks.length,
                    itemBuilder: (context, index) {
                      final feedback = feedbacks[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: RatingBarIndicator(
                          rating: feedback.rating,
                          itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                          itemCount: 5,
                          itemSize: 15.0,
                          direction: Axis.horizontal,
                        ),
                        subtitle: Text(feedback.comment ?? ''),
                      );
                    },
                  ),
                  
                const SizedBox(height: 20),
                const Text('أضف تقييمك:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                // Add Feedback Form
                RatingBar.builder(
                  initialRating: 3,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) {
                    _rating = rating;
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'اكتب تعليقك هنا...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (_commentController.text.isNotEmpty) {
                      final feedback = BookFeedback(
                        bookId: widget.bookId,
                        rating: _rating,
                        comment: _commentController.text,
                      );
                        
                      await provider.addFeedback(feedback);
                      _commentController.clear();
                      // No need to setState because provider notifies listeners
                    }
                  },
                  child: const Text('إرسال التقييم'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
