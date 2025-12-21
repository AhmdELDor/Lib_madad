class Borrowing {
  int? id;
  int bookId;
  int clientId;
  DateTime borrowDate;
  DateTime deadline;
  double? donationAmount;
  bool isReturned;

  Borrowing({
    this.id,
    required this.bookId,
    required this.clientId,
    required this.borrowDate,
    required this.deadline,
    this.donationAmount,
    this.isReturned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'clientId': clientId,
      'borrowDate': borrowDate.millisecondsSinceEpoch,
      'deadline': deadline.millisecondsSinceEpoch,
      'donationAmount': donationAmount,
      'isReturned': isReturned ? 1 : 0,
    };
  }

  factory Borrowing.fromMap(Map<String, dynamic> map) {
    return Borrowing(
      id: map['id'],
      bookId: map['bookId'],
      clientId: map['clientId'],
      borrowDate: DateTime.fromMillisecondsSinceEpoch(map['borrowDate']),
      deadline: DateTime.fromMillisecondsSinceEpoch(map['deadline']),
      donationAmount: map['donationAmount'],
      isReturned: map['isReturned'] == 1,
    );
  }
}
