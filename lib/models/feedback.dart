class BookFeedback {
  int? id;
  int bookId;
  int? clientId;
  String? comment;
  double rating;

  BookFeedback({
    this.id,
    required this.bookId,
    this.clientId,
    this.comment,
    this.rating = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'clientId': clientId,
      'comment': comment,
      'rating': rating,
    };
  }

  factory BookFeedback.fromMap(Map<String, dynamic> map) {
    return BookFeedback(
      id: map['id'],
      bookId: map['bookId'],
      clientId: map['clientId'],
      comment: map['comment'],
      rating: map['rating'],
    );
  }
}
