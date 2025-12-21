import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/client.dart';
import '../models/borrowing.dart';
import '../models/feedback.dart';
import '../providers/library_provider.dart';
import 'add_client_screen.dart';

class ClientDetailsScreen extends StatelessWidget {
  final int clientId;

  const ClientDetailsScreen({super.key, required this.clientId});

  void _confirmDelete(BuildContext context, LibraryProvider provider, Client client) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف العميل'),
        content: Text('هل أنت متأكد من حذف العميل "${client.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await provider.deleteClient(client.id!);
              Navigator.pop(ctx);
              Navigator.pop(context);
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
    final clientIndex = provider.clients.indexWhere((c) => c.id == clientId);
    
    if (clientIndex == -1) {
      return const Scaffold(body: Center(child: Text('العميل غير موجود')));
    }
    
    final client = provider.clients[clientIndex];

    final borrowings = provider.getClientBorrowings(clientId);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(client.name),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddClientScreen(client: client)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context, provider, client),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'سجل الإعارات'),
              Tab(text: 'التقييمات'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Client Info Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      client.name.isNotEmpty ? client.name[0] : '?',
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text(client.phone, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Tabs Content
            Expanded(
              child: TabBarView(
                children: [
                  _buildBorrowingHistory(context, provider, borrowings),
                  _buildFeedbacksList(context, provider, clientId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowingHistory(BuildContext context, LibraryProvider provider, List<Borrowing> borrowings) {
    if (borrowings.isEmpty) {
      return const Center(child: Text('لا يوجد سجل إعارات لهذا العميل'));
    }

    // Sort by date descending
    borrowings.sort((a, b) => b.borrowDate.compareTo(a.borrowDate));

    return ListView.builder(
      itemCount: borrowings.length,
      itemBuilder: (context, index) {
        final borrowing = borrowings[index];
        final book = provider.books.firstWhere((b) => b.id == borrowing.bookId, orElse: () => provider.books.first);
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: const Icon(Icons.book),
            title: Text(book.title),
            subtitle: Text(
              'تاريخ الإعارة: ${DateFormat('yyyy-MM-dd').format(borrowing.borrowDate)}\n'
              'تاريخ الإرجاع: ${DateFormat('yyyy-MM-dd').format(borrowing.deadline)}',
            ),
            trailing: borrowing.isReturned
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.timelapse, color: Colors.orange),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildFeedbacksList(BuildContext context, LibraryProvider provider, int clientId) {
    return FutureBuilder<List<BookFeedback>>(
      future: provider.getClientFeedbacks(clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final feedbacks = snapshot.data ?? [];
        
        if (feedbacks.isEmpty) {
          return const Center(child: Text('لا توجد تقييمات لهذا العميل'));
        }

        return ListView.builder(
          itemCount: feedbacks.length,
          itemBuilder: (context, index) {
            final feedback = feedbacks[index];
            final book = provider.books.firstWhere((b) => b.id == feedback.bookId, orElse: () => provider.books.first);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                title: Text('كتاب: ${book.title}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RatingBarIndicator(
                      rating: feedback.rating,
                      itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 15.0,
                      direction: Axis.horizontal,
                    ),
                    if (feedback.comment != null && feedback.comment!.isNotEmpty)
                      Text(feedback.comment!),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
