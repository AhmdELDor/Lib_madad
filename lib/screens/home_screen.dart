import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/library_provider.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LibraryProvider>(context);
    final books = provider.books;
    final borrowings = provider.borrowings;
    final clients = provider.clients;
    
    final activeBorrowingsCount = borrowings.where((b) => !b.isReturned).length;
    final totalDonations = borrowings.fold(0.0, (sum, item) => sum + (item.donationAmount ?? 0));
    
    // Calculate total available and borrowed books
    final totalBooks = books.fold(0, (sum, book) => sum + book.quantity);
    final totalAvailable = books.fold(0, (sum, book) => sum + book.availableQuantity);
    final totalBorrowed = totalBooks - totalAvailable;
    
    // Filter Overdue
    final overdueBorrowings = borrowings.where((b) {
      return !b.isReturned && b.deadline.isBefore(DateTime.now());
    }).toList();

    // Filter Active (Borrowing Now) - Sort by date descending
    final activeBorrowingsList = borrowings.where((b) => !b.isReturned).toList()
      ..sort((a, b) => b.borrowDate.compareTo(a.borrowDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية والإحصائيات'),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. Split Row: Borrowing Now & Overdue (Right) & Overview (Left)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Right Side (in RTL) -> Borrowing Now & Overdue Alerts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, 'يتم استعارتها الآن'),
                      const SizedBox(height: 10),
                      if (activeBorrowingsList.isEmpty)
                        const Center(child: Text('لا توجد إعارات نشطة حالياً', style: TextStyle(color: Colors.grey)))
                      else
                        Card(
                          elevation: 4,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: SizedBox(
                            height: 300, // Fixed height for scrolling
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              // Allow scrolling inside the fixed height
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: activeBorrowingsList.length, // Show all, scrollable
                              separatorBuilder: (ctx, i) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final borrowing = activeBorrowingsList[index];
                                final book = books.firstWhere((b) => b.id == borrowing.bookId);
                                final client = clients.firstWhere((c) => c.id == borrowing.clientId);

                                return ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(FontAwesomeIcons.bookOpen, color: Colors.blue, size: 16),
                                  ),
                                  title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('العميل: ${client.name}'),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('موعد الإرجاع', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      Text(
                                        DateFormat('MM-dd').format(borrowing.deadline),
                                        style: TextStyle(
                                          color: borrowing.deadline.isBefore(DateTime.now()) ? Colors.red : Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                      // Overdue Alerts Section (Moved here)
                      if (overdueBorrowings.isNotEmpty) ...[
                        const SizedBox(height: 25),
                        _buildSectionTitle(context, 'تنبيهات التأخير', color: Colors.red),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 4,
                          color: Colors.red[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.red.withOpacity(0.5)),
                          ),
                          child: SizedBox(
                            height: 200, // Fixed height for scrolling
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: overdueBorrowings.length,
                              separatorBuilder: (ctx, i) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final borrowing = overdueBorrowings[index];
                                final book = books.firstWhere((b) => b.id == borrowing.bookId);
                                final client = clients.firstWhere((c) => c.id == borrowing.clientId);
                                final daysOverdue = DateTime.now().difference(borrowing.deadline).inDays;

                                return ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.red,
                                    child: Icon(Icons.warning_amber_rounded, color: Colors.white),
                                  ),
                                  title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('العميل: ${client.name}\nمتأخر منذ $daysOverdue يوم'),
                                  trailing: Text(
                                    DateFormat('yyyy-MM-dd').format(borrowing.deadline),
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 20),

                // Left Side (in RTL) -> Overview & Charts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, 'نظرة عامة'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildStatCard(context, 'الكتب', '${books.length}', FontAwesomeIcons.book, Colors.blue)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildStatCard(context, 'العملاء', '${clients.length}', FontAwesomeIcons.users, Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildStatCard(context, 'إعارات نشطة', '$activeBorrowingsCount', FontAwesomeIcons.handshake, Colors.orange)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildStatCard(context, 'التبرعات', '$totalDonations', FontAwesomeIcons.coins, Colors.purple, suffix: 'د.أ')),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // 3. Charts Section (Moved here)
                      _buildSectionTitle(context, 'إحصائيات المكتبة'),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 4,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Text('حالة توفر الكتب', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 200,
                                child: books.isEmpty 
                                    ? const Center(child: Text('لا توجد بيانات'))
                                    : PieChart(
                                    PieChartData(
                                      sections: [
                                        PieChartSectionData(
                                          value: totalAvailable.toDouble(),
                                          title: 'متاح',
                                          color: Colors.green,
                                          radius: 60,
                                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        PieChartSectionData(
                                          value: totalBorrowed.toDouble(),
                                          title: 'معار',
                                          color: Colors.orange,
                                          radius: 50,
                                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 30,
                                    ),
                                  ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildChartLegend(Colors.green, 'متاح ($totalAvailable)'),
                                  const SizedBox(width: 20),
                                  _buildChartLegend(Colors.orange, 'معار ($totalBorrowed)'),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, {Color? color}) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color, {String? suffix}) {
    return Card(
      elevation: 4,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    if (suffix != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        suffix,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
