import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/client.dart';
import '../models/borrowing.dart';
import '../models/event.dart';
import '../models/feedback.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    // Store database in application directory (not Documents)
    final executableDir = File(Platform.resolvedExecutable).parent.path;
    final dataDir = Directory(join(executableDir, 'data'));
    
    // Create data directory if it doesn't exist
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    
    final dbPath = join(dataDir.path, 'library_manager.db');
    
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        genre TEXT NOT NULL,
        imagePath TEXT,
        description TEXT,
        isAvailable INTEGER NOT NULL DEFAULT 1,
        quantity INTEGER NOT NULL DEFAULT 1,
        availableQuantity INTEGER NOT NULL DEFAULT 1,
        borrowCount INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        borrowCount INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE borrowings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId INTEGER NOT NULL,
        clientId INTEGER NOT NULL,
        borrowDate INTEGER NOT NULL,
        deadline INTEGER NOT NULL,
        donationAmount REAL,
        isReturned INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (bookId) REFERENCES books (id),
        FOREIGN KEY (clientId) REFERENCES clients (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        imagePaths TEXT,
        date INTEGER NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE feedbacks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId INTEGER NOT NULL,
        clientId INTEGER,
        comment TEXT,
        rating REAL NOT NULL DEFAULT 0.0,
        FOREIGN KEY (bookId) REFERENCES books (id),
        FOREIGN KEY (clientId) REFERENCES clients (id)
      )
    ''');
  }

  Future<void> init() async {
    await database;
  }

  // Books
  Future<void> addBook(Book book) async {
    final db = await database;
    book.id = await db.insert('books', book.toMap());
  }

  Future<List<Book>> getAllBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('books');
    return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
  }

  Future<void> updateBook(Book book) async {
    final db = await database;
    await db.update(
      'books',
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<void> deleteBook(int id) async {
    final db = await database;
    await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Clients
  Future<void> addClient(Client client) async {
    final db = await database;
    client.id = await db.insert('clients', client.toMap());
  }

  Future<List<Client>> getAllClients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('clients');
    return List.generate(maps.length, (i) => Client.fromMap(maps[i]));
  }

  Future<void> updateClient(Client client) async {
    final db = await database;
    await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<void> deleteClient(int id) async {
    final db = await database;
    await db.delete(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Borrowings
  Future<void> addBorrowing(Borrowing borrowing) async {
    final db = await database;
    borrowing.id = await db.insert('borrowings', borrowing.toMap());
  }

  Future<List<Borrowing>> getAllBorrowings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('borrowings');
    return List.generate(maps.length, (i) => Borrowing.fromMap(maps[i]));
  }

  Future<void> updateBorrowing(Borrowing borrowing) async {
    final db = await database;
    await db.update(
      'borrowings',
      borrowing.toMap(),
      where: 'id = ?',
      whereArgs: [borrowing.id],
    );
  }

  Future<void> deleteBorrowing(int id) async {
    final db = await database;
    await db.delete(
      'borrowings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Events
  Future<void> addEvent(Event event) async {
    final db = await database;
    event.id = await db.insert('events', event.toMap());
  }

  Future<List<Event>> getAllEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  Future<void> updateEvent(Event event) async {
    final db = await database;
    await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<void> deleteEvent(int id) async {
    final db = await database;
    await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Feedbacks
  Future<void> addFeedback(BookFeedback feedback) async {
    final db = await database;
    feedback.id = await db.insert('feedbacks', feedback.toMap());
  }

  Future<List<BookFeedback>> getFeedbacksForBook(int bookId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'feedbacks',
      where: 'bookId = ?',
      whereArgs: [bookId],
    );
    return List.generate(maps.length, (i) => BookFeedback.fromMap(maps[i]));
  }

  Future<List<BookFeedback>> getFeedbacksForClient(int clientId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'feedbacks',
      where: 'clientId = ?',
      whereArgs: [clientId],
    );
    return List.generate(maps.length, (i) => BookFeedback.fromMap(maps[i]));
  }
}
