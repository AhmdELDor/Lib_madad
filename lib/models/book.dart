class Book {
  int? id;
  String title;
  String author;
  String genre;
  String? imagePath;
  String? description;
  bool isAvailable;
  int quantity;
  int availableQuantity;
  int borrowCount;

  Book({
    this.id,
    required this.title,
    required this.author,
    required this.genre,
    this.imagePath,
    this.description,
    this.isAvailable = true,
    this.quantity = 1,
    this.availableQuantity = 1,
    this.borrowCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'genre': genre,
      'imagePath': imagePath,
      'description': description,
      'isAvailable': isAvailable ? 1 : 0,
      'quantity': quantity,
      'availableQuantity': availableQuantity,
      'borrowCount': borrowCount,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      genre: map['genre'],
      imagePath: map['imagePath'],
      description: map['description'],
      isAvailable: map['isAvailable'] == 1,
      quantity: map['quantity'],
      availableQuantity: map['availableQuantity'],
      borrowCount: map['borrowCount'],
    );
  }
}
