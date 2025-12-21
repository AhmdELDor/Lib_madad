import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/borrowing.dart';
import '../models/book.dart';
import '../models/client.dart';
import '../providers/library_provider.dart';
import '../widgets/app_drawer.dart';
import 'add_borrowing_screen.dart';

class BorrowingScreen extends StatelessWidget {
  const BorrowingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الإعارات'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'إعارات نشطة'),
              Tab(text: 'سجل الإعارات'),
            ],
          ),
        ),
        drawer: const AppDrawer(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddBorrowingScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
        body: const TabBarView(
          children: [
            _ActiveBorrowingsList(),
            _HistoryBorrowingsList(),
          ],
        ),
      ),
    );
  }
}

void _confirmDelete(BuildContext context, LibraryProvider provider, Borrowing borrowing) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('حذف السجل'),
      content: const Text('هل أنت متأكد من حذف هذا السجل؟ سيتم تحديث مخزون الكتب إذا كانت الإعارة نشطة.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () async {
            await provider.deleteBorrowing(borrowing.id!);
            Navigator.pop(ctx);
          },
          child: const Text('حذف', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

class _ActiveBorrowingsList extends StatelessWidget {
  const _ActiveBorrowingsList();

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, provider, child) {
        final activeBorrowings = provider.borrowings.where((b) => !b.isReturned).toList();

        if (activeBorrowings.isEmpty) {
          return const Center(child: Text('لا توجد إعارات نشطة حالياً'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            childAspectRatio: 0.65,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: activeBorrowings.length,
          itemBuilder: (context, index) {
            final borrowing = activeBorrowings[index];
            final bookIndex = provider.books.indexWhere((b) => b.id == borrowing.bookId);
            final book = bookIndex != -1 
              ? provider.books[bookIndex] 
              : Book(title: 'كتاب محذوف', author: '', genre: '');
            final clientIndex = provider.clients.indexWhere((c) => c.id == borrowing.clientId);
            final client = clientIndex != -1 
              ? provider.clients[clientIndex] 
              : Client(name: 'عميل محذوف', phone: '');

            final isOverdue = DateTime.now().isAfter(borrowing.deadline);

            return Card(
              color: isOverdue ? Colors.red[50] : Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Section
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: book.imagePath != null
                          ? Image.file(
                              File(book.imagePath!),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.book, size: 40, color: Colors.grey),
                            ),
                    ),
                  ),
                  
                  // Details Section
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  client.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 12, color: isOverdue ? Colors.red : Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MM/dd').format(borrowing.deadline),
                                style: TextStyle(
                                  color: isOverdue ? Colors.red : Colors.grey[700],
                                  fontSize: 12,
                                  fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await provider.returnBook(borrowing);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 30),
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('إرجاع', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _confirmDelete(context, provider, borrowing),
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(Icons.delete, color: Colors.red, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HistoryBorrowingsList extends StatelessWidget {
  const _HistoryBorrowingsList();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LibraryProvider>(context);
    final historyBorrowings = provider.borrowings.where((b) => b.isReturned).toList();

    if (historyBorrowings.isEmpty) {
      return const Center(child: Text('سجل الإعارات فارغ'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: historyBorrowings.length,
      itemBuilder: (context, index) {
        final borrowing = historyBorrowings[index];
        final bookIndex = provider.books.indexWhere((b) => b.id == borrowing.bookId);
        final book = bookIndex != -1 
          ? provider.books[bookIndex] 
          : Book(title: 'كتاب محذوف', author: '', genre: '');
        final clientIndex = provider.clients.indexWhere((c) => c.id == borrowing.clientId);
        final client = clientIndex != -1 
          ? provider.clients[clientIndex] 
          : Client(name: 'عميل محذوف', phone: '');

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: book.imagePath != null
                      ? Image.file(
                          File(book.imagePath!),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.book, size: 40, color: Colors.grey),
                        ),
                ),
              ),
              
              // Details Section
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'المستعير: ${client.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'تم الإرجاع',
                          style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (borrowing.donationAmount != null && borrowing.donationAmount! > 0)
                            Expanded(
                              child: Text(
                                'تبرع: ${borrowing.donationAmount}',
                                style: const TextStyle(fontSize: 10, color: Colors.orange),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          InkWell(
                            onTap: () => _confirmDelete(context, provider, borrowing),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.delete, color: Colors.grey, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
