import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/library_provider.dart';
import '../widgets/app_drawer.dart';
import 'add_book_screen.dart';
import 'book_details_screen.dart';
import 'add_borrowing_screen.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  String _searchQuery = '';
  String? _selectedGenre;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LibraryProvider>(context);
    final allBooks = provider.books;

    // Filter Logic
    final filteredBooks = allBooks.where((book) {
      final matchesSearch = book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesGenre = _selectedGenre == null || book.genre == _selectedGenre;
      return matchesSearch && matchesGenre;
    }).toList();

    // Get unique genres for filter
    final genres = allBooks.map((b) => b.genre).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الكتب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'تصدير إلى Excel',
            onPressed: () async {
              final error = await provider.exportBooksToExcel();
              if (context.mounted) {
                if (error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تصدير الملف بنجاح')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Simple search bar toggle could be implemented here
            },
          )
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBookScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'بحث عن كتاب...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  hint: const Text('تصنيف'),
                  value: _selectedGenre,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('الكل')),
                    ...genres.map((g) => DropdownMenuItem(value: g, child: Text(g))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGenre = value;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Book List
          Expanded(
            child: filteredBooks.isEmpty
                ? const Center(child: Text('لا توجد كتب مطابقة'))
                : GridView.builder(
                    padding: const EdgeInsets.all(15),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200, // Maximum width of a card
                      childAspectRatio: 0.65, // Height relative to width
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => BookDetailsScreen(bookId: book.id!)),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Book Cover Image
                              Expanded(
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                      child: Container(
                                        width: double.infinity,
                                        color: Colors.grey[100],
                                        child: book.imagePath != null
                                            ? Image.file(
                                                File(book.imagePath!),
                                                fit: BoxFit.cover,
                                              )
                                            : const Center(
                                                child: Icon(FontAwesomeIcons.book, size: 30, color: Colors.grey),
                                              ),
                                      ),
                                    ),
                                    if (book.isAvailable)
                                      Positioned(
                                        top: 5,
                                        left: 5,
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => AddBorrowingScreen(initialBookId: book.id),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 4,
                                                )
                                              ]
                                            ),
                                            child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Book Details
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      book.author,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: book.isAvailable ? Colors.green[50] : Colors.red[50],
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(
                                          color: book.isAvailable ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                                          width: 0.5
                                        ),
                                      ),
                                      child: Text(
                                        book.isAvailable ? 'متاح (${book.availableQuantity})' : 'نفذت الكمية',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: book.isAvailable ? Colors.green[800] : Colors.red[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
