import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/library_provider.dart';
import '../widgets/app_drawer.dart';
import 'add_client_screen.dart';
import 'client_details_screen.dart';
import 'add_borrowing_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String _searchQuery = '';
  bool _sortAscending = false; // Default to descending (most active first)

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LibraryProvider>(context);
    final allClients = provider.clients;

    // Filter Logic
    var filteredClients = allClients.where((client) {
      return client.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             client.phone.contains(_searchQuery);
    }).toList();

    // Sort Logic
    filteredClients.sort((a, b) {
      return _sortAscending 
          ? a.borrowCount.compareTo(b.borrowCount)
          : b.borrowCount.compareTo(a.borrowCount);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العملاء'),
        actions: [
          IconButton(
            icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: 'ترتيب حسب عدد الاستعارات',
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddClientScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'بحث بالاسم أو رقم الهاتف...',
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
          
          // Client List
          Expanded(
            child: filteredClients.isEmpty
                ? const Center(child: Text('لا يوجد عملاء مطابقين'))
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 0.75, // Made card taller to fix overflow
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = filteredClients[index];
                      // Check if client has active borrowings
                      final activeBorrowings = provider.borrowings.where(
                        (b) => b.clientId == client.id && !b.isReturned
                      ).toList();
                      final isBorrowingNow = activeBorrowings.isNotEmpty;

                      return Card(
                        elevation: 2,
                        color: const Color(0xFFF5F9F8), // Light greenish/grey tint
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClientDetailsScreen(clientId: client.id!),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Avatar with Badge
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: const Color(0xFF00695C), // Teal color
                                          child: Text(
                                            client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                                            style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.w300),
                                          ),
                                        ),
                                        if (isBorrowingNow)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: Colors.orange,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                              ),
                                              child: const Icon(Icons.book, size: 12, color: Colors.white),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    
                                    // Name
                                    Text(
                                      client.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 16,
                                      ),
                                    ),
                                    
                                    // Phone
                                    const SizedBox(height: 2),
                                    Text(
                                      client.phone,
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                    
                                    const Spacer(),
                                    
                                    // Borrow Count Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${client.borrowCount}',
                                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(FontAwesomeIcons.bookOpenReader, size: 12, color: Colors.blue),
                                        ],
                                      ),
                                    ),
                                    
                                    // "Borrowing Now" Text
                                    if (isBorrowingNow) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'يستعير الآن',
                                        style: TextStyle(
                                          color: Colors.orange[800], 
                                          fontSize: 11, 
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                              
                              // Top Left Add Button
                              Positioned(
                                top: 12,
                                left: 12,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddBorrowingScreen(initialClientId: client.id!),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFCC80), // Light orange
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 2,
                                        )
                                      ]
                                    ),
                                    child: const Icon(Icons.add, color: Colors.black87, size: 18),
                                  ),
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
