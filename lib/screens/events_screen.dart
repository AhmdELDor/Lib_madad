import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../providers/library_provider.dart';
import '../widgets/app_drawer.dart';
import 'add_event_screen.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  void _confirmDelete(BuildContext context, LibraryProvider provider, Event event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الفعالية'),
        content: Text('هل أنت متأكد من حذف فعالية "${event.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await provider.deleteEvent(event.id!);
              Navigator.pop(ctx);
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
    final events = provider.events;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الفعاليات'),
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEventScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: events.isEmpty
          ? const Center(child: Text('لا توجد فعاليات قادمة'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Section (Square & Swipeable)
                          if (event.imagePaths != null && event.imagePaths!.isNotEmpty)
                            AspectRatio(
                              aspectRatio: 1.0, // Square
                              child: Stack(
                                children: [
                                  PageView.builder(
                                    itemCount: event.imagePaths!.length,
                                    itemBuilder: (context, imgIndex) {
                                      return GestureDetector(
                                        onTap: () {
                                          _showFullScreenImage(context, event.imagePaths!, imgIndex);
                                        },
                                        child: kIsWeb 
                                            ? Image.network(
                                                event.imagePaths![imgIndex],
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              )
                                            : Image.file(
                                                File(event.imagePaths![imgIndex]),
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              ),
                                      );
                                    },
                                  ),
                                  // Image Indicator (if more than 1)
                                  if (event.imagePaths!.length > 1)
                                    Positioned(
                                      bottom: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.swipe, color: Colors.white, size: 16),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          else
                            Container(
                              height: 150,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.event, size: 50, color: Colors.grey),
                              ),
                            ),
                          
                          // Details Section
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 12, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('MMM d').format(event.date),
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('hh:mm a').format(event.date),
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Text(
                                      event.description ?? '',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey[800], fontSize: 12, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Edit/Delete Menu
                      Positioned(
                        top: 5,
                        right: 5,
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 5)]),
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddEventScreen(event: event)),
                              );
                            } else if (value == 'delete') {
                              _confirmDelete(context, provider, event);
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 10), Text('تعديل')]),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 10), Text('حذف', style: TextStyle(color: Colors.red))]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showFullScreenImage(BuildContext context, List<String> imagePaths, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PageView.builder(
            itemCount: imagePaths.length,
            controller: PageController(initialPage: initialIndex),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: kIsWeb 
                      ? Image.network(
                          imagePaths[index],
                          fit: BoxFit.contain,
                        )
                      : Image.file(
                          File(imagePaths[index]),
                          fit: BoxFit.contain,
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
