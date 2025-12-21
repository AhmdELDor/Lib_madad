class Client {
  int? id;
  String name;
  String phone;
  int borrowCount;

  Client({
    this.id,
    required this.name,
    required this.phone,
    this.borrowCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'borrowCount': borrowCount,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      borrowCount: map['borrowCount'],
    );
  }
}
