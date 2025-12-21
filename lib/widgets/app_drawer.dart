import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../screens/home_screen.dart';
import '../screens/books_screen.dart';
import '../screens/clients_screen.dart';
import '../screens/borrowing_screen.dart';
import '../screens/events_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0), // Add padding to prevent cutting off
              child: Image.asset(
                'assets/logos/logo.png',
                fit: BoxFit.contain, // Ensure the full logo is visible
              ),
            ),
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.chartPie),
            title: const Text('الرئيسية والإحصائيات'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.book),
            title: const Text('الكتب'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const BooksScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.users),
            title: const Text('العملاء'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ClientsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.handshake),
            title: const Text('الإعارات'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const BorrowingScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.calendar),
            title: const Text('الفعاليات'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const EventsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
