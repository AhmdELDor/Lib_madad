import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as path;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../models/book.dart';
import '../models/client.dart';
import '../models/borrowing.dart';
import '../models/event.dart';
import '../models/feedback.dart';
import '../services/database_service.dart';

class LibraryProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  List<Book> _books = [];
  List<Client> _clients = [];
  List<Borrowing> _borrowings = [];
  List<Event> _events = [];

  List<Book> get books => _books;
  List<Client> get clients => _clients;
  List<Borrowing> get borrowings => _borrowings;
  List<Event> get events => _events;

  Future<void> init() async {
    await _dbService.init();
    await _initNotifications();
    await fetchAllData();
  }

  Future<void> _initNotifications() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(settings);
  }

  Future<void> fetchAllData() async {
    _books = await _dbService.getAllBooks();
    _clients = await _dbService.getAllClients();
    _borrowings = await _dbService.getAllBorrowings();
    _events = await _dbService.getAllEvents();
    notifyListeners();
  }

  // --- HELPER: Save Image Permanently ---
  Future<String> _saveImageLocally(String imagePath) async {
    if (kIsWeb) return imagePath;
    if (imagePath.isEmpty) return '';
    try {
      final File originalFile = File(imagePath);
      if (!await originalFile.exists()) return imagePath; // Return original if file not found

      // Create a 'user_data/images' folder in the app's execution directory (portable)
      // On Windows, this is usually next to the executable or in the project root when debugging.
      final String appDir = Directory.current.path;
      final String imagesDir = path.join(appDir, 'user_data', 'images');
      
      final Directory directory = Directory(imagesDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final String fileName = path.basename(imagePath);
      final String newPath = path.join(directory.path, '${DateTime.now().millisecondsSinceEpoch}_$fileName');
      
      await originalFile.copy(newPath);
      return newPath;
    } catch (e) {
      debugPrint("Error saving image: $e");
      return imagePath; // Fallback to original path
    }
  }

  // Books
  Future<void> addBook(Book book) async {
    // Save image permanently before adding to DB
    String? savedImagePath = book.imagePath;
    if (book.imagePath != null && book.imagePath!.isNotEmpty) {
      savedImagePath = await _saveImageLocally(book.imagePath!);
    }
    
    // Create a new book with saved image path
    final bookToSave = Book(
      title: book.title,
      author: book.author,
      genre: book.genre,
      imagePath: savedImagePath,
      description: book.description,
      isAvailable: book.quantity > 0,
      quantity: book.quantity,
      availableQuantity: book.quantity,
      borrowCount: 0,
    );

    await _dbService.addBook(bookToSave);
    await fetchAllData();
  }
  
  Future<void> updateBook(Book book) async {
    String? savedImagePath = book.imagePath;
    if (book.imagePath != null && book.imagePath!.isNotEmpty) {
       // Check if path is already in app docs (simple check)
       if (!kIsWeb) {
         final String appDir = Directory.current.path;
         final isAlreadySaved = book.imagePath!.startsWith(appDir);
         
         if (!isAlreadySaved) {
           savedImagePath = await _saveImageLocally(book.imagePath!);
         }
       }
    }
    
    final bookToSave = Book(
      id: book.id,
      title: book.title,
      author: book.author,
      genre: book.genre,
      imagePath: savedImagePath,
      description: book.description,
      isAvailable: book.isAvailable,
      quantity: book.quantity,
      availableQuantity: book.availableQuantity,
      borrowCount: book.borrowCount,
    );
    
    await _dbService.updateBook(bookToSave);
    await fetchAllData();
  }

  Future<void> deleteBook(int id) async {
    await _dbService.deleteBook(id);
    await fetchAllData();
  }

  // Clients
  Future<void> addClient(Client client) async {
    await _dbService.addClient(client);
    await fetchAllData();
  }
  
  Future<void> updateClient(Client client) async {
    await _dbService.updateClient(client);
    await fetchAllData();
  }

  // Borrowings
  Future<void> borrowBook(Borrowing borrowing) async {
    final book = _books.firstWhere((b) => b.id == borrowing.bookId);
    
    if (book.availableQuantity <= 0) {
      throw Exception('Book is not available');
    }

    await _dbService.addBorrowing(borrowing);
    
    // Update Book status and borrow count
    final updatedBook = Book(
      id: book.id,
      title: book.title,
      author: book.author,
      genre: book.genre,
      imagePath: book.imagePath,
      description: book.description,
      quantity: book.quantity,
      availableQuantity: book.availableQuantity - 1,
      isAvailable: book.availableQuantity - 1 > 0,
      borrowCount: book.borrowCount + 1,
    );
    await _dbService.updateBook(updatedBook);

    // Update Client borrow count
    final client = _clients.firstWhere((c) => c.id == borrowing.clientId);
    final updatedClient = Client(
      id: client.id,
      name: client.name,
      phone: client.phone,
      borrowCount: client.borrowCount + 1,
    );
    await _dbService.updateClient(updatedClient);

    // Schedule Notification
    await _scheduleDeadlineNotification(borrowing, book.title);

    await fetchAllData();
  }

  Future<void> _scheduleDeadlineNotification(Borrowing borrowing, String bookTitle) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        borrowing.id!,
        'تذكير بموعد الإرجاع',
        'حان موعد إرجاع كتاب: $bookTitle',
        tz.TZDateTime.from(borrowing.deadline, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'library_deadlines',
            'Library Deadlines',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> returnBook(Borrowing borrowing) async {
    final updatedBorrowing = Borrowing(
      id: borrowing.id,
      bookId: borrowing.bookId,
      clientId: borrowing.clientId,
      borrowDate: borrowing.borrowDate,
      deadline: borrowing.deadline,
      donationAmount: borrowing.donationAmount,
      isReturned: true,
    );
    await _dbService.updateBorrowing(updatedBorrowing);
    notifyListeners(); // Update UI immediately

    // Safely update book stock if book exists
    final bookIndex = _books.indexWhere((b) => b.id == borrowing.bookId);
    if (bookIndex != -1) {
      final book = _books[bookIndex];
      final updatedBook = Book(
        id: book.id,
        title: book.title,
        author: book.author,
        genre: book.genre,
        imagePath: book.imagePath,
        description: book.description,
        quantity: book.quantity,
        availableQuantity: book.availableQuantity + 1,
        isAvailable: true,
        borrowCount: book.borrowCount,
      );
      await _dbService.updateBook(updatedBook);
    }
    
    // Cancel notification
    await _notificationsPlugin.cancel(borrowing.id!);

    await fetchAllData();
  }

  // Events
  Future<void> addEvent(Event event) async {
    // Save all event images permanently
    List<String>? savedPaths;
    if (event.imagePaths != null) {
      savedPaths = [];
      for (String path in event.imagePaths!) {
        savedPaths.add(await _saveImageLocally(path));
      }
    }
    
    final eventToSave = Event(
      title: event.title,
      description: event.description,
      date: event.date,
      imagePaths: savedPaths,
    );
    
    await _dbService.addEvent(eventToSave);
    await fetchAllData();
  }
  
  // Feedbacks
  Future<void> addFeedback(BookFeedback feedback) async {
    await _dbService.addFeedback(feedback);
    notifyListeners();
  }
  
  Future<List<BookFeedback>> getFeedbacks(int bookId) async {
    return await _dbService.getFeedbacksForBook(bookId);
  }

  Future<List<BookFeedback>> getClientFeedbacks(int clientId) async {
    return await _dbService.getFeedbacksForClient(clientId);
  }

  List<Borrowing> getClientBorrowings(int clientId) {
    return _borrowings.where((b) => b.clientId == clientId).toList();
  }

  Future<void> deleteClient(int id) async {
    await _dbService.deleteClient(id);
    await fetchAllData();
  }

  Future<void> updateEvent(Event event) async {
    List<String>? savedPaths;
    if (event.imagePaths != null) {
      savedPaths = [];
      for (String path in event.imagePaths!) {
        if (path.contains('user_data')) {
          savedPaths.add(path);
        } else {
          savedPaths.add(await _saveImageLocally(path));
        }
      }
    }
    
    final eventToSave = Event(
      id: event.id,
      title: event.title,
      description: event.description,
      date: event.date,
      imagePaths: savedPaths,
    );
    
    await _dbService.updateEvent(eventToSave);
    await fetchAllData();
  }

  Future<void> deleteEvent(int id) async {
    await _dbService.deleteEvent(id);
    await fetchAllData();
  }

  Future<void> deleteBorrowing(int id) async {
    final borrowingIndex = _borrowings.indexWhere((b) => b.id == id);
    if (borrowingIndex == -1) return;
    
    final borrowing = _borrowings[borrowingIndex];

    if (!borrowing.isReturned) {
       final bookIndex = _books.indexWhere((b) => b.id == borrowing.bookId);
       if (bookIndex != -1) {
         final book = _books[bookIndex];
         final updatedBook = Book(
           id: book.id,
           title: book.title,
           author: book.author,
           genre: book.genre,
           imagePath: book.imagePath,
           description: book.description,
           quantity: book.quantity,
           availableQuantity: book.availableQuantity + 1,
           isAvailable: true,
           borrowCount: book.borrowCount,
         );
         await _dbService.updateBook(updatedBook);
       }
    }
    
    await _dbService.deleteBorrowing(id);
    await fetchAllData();
  }

  Future<String?> exportBooksToExcel() async {
    if (kIsWeb) return "Export not supported on Web";
    try {
      var excel = Excel.createExcel();
      // Rename default sheet
      excel.rename('Sheet1', 'Books');
      Sheet sheetObject = excel['Books'];
      
      sheetObject.appendRow([
        TextCellValue('ID'), 
        TextCellValue('Title'), 
        TextCellValue('Author'), 
        TextCellValue('Genre'), 
        TextCellValue('Total Quantity'), 
        TextCellValue('Available'), 
        TextCellValue('Status')
      ]);

      for (var book in _books) {
        sheetObject.appendRow([
          IntCellValue(book.id!),
          TextCellValue(book.title),
          TextCellValue(book.author),
          TextCellValue(book.genre),
          IntCellValue(book.quantity),
          IntCellValue(book.availableQuantity),
          TextCellValue(book.isAvailable ? 'Available' : 'Out of Stock'),
        ]);
      }

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: 'library_books.xlsx',
        allowedExtensions: ['xlsx'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        // Ensure extension
        if (!outputFile.endsWith('.xlsx')) {
          outputFile += '.xlsx';
        }
        
        var fileBytes = excel.save();
        if (fileBytes != null) {
          File(outputFile)
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);
          return null; // Success
        }
      }
      return "Export cancelled";
    } catch (e) {
      return "Error exporting: $e";
    }
  }

  Future<void> debugResetAllStocksToOne() async {
    for (var book in _books) {
      // Count active borrowings for this book
      int activeBorrowingsCount = _borrowings.where((b) => b.bookId == book.id && !b.isReturned).length;
      
      final updatedBook = Book(
        id: book.id,
        title: book.title,
        author: book.author,
        genre: book.genre,
        imagePath: book.imagePath,
        description: book.description,
        quantity: 1,
        availableQuantity: 1 - activeBorrowingsCount,
        isAvailable: 1 - activeBorrowingsCount > 0,
        borrowCount: book.borrowCount,
      );
      
      await _dbService.updateBook(updatedBook);
    }
    await fetchAllData();
  }
}
