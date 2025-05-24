// Book model for the app, including Firebase Storage link and user data
class Book {
  final String id;
  final String title;
  final String format; // 'PDF' or 'EPUB'
  final String link; // Firebase Storage link
  final String userId;
  final String
      lastReadPage; // Changed to String for EPUB CFI or PDF page number

  Book({
    required this.id,
    required this.title,
    required this.format,
    required this.link,
    required this.userId,
    required this.lastReadPage,
  });

  // Add fromMap/toMap for Firebase/Local storage
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as String,
      title: map['title'] as String,
      format: map['format'] as String,
      link: map['link'] as String,
      userId: map['userId'] as String,
      lastReadPage: map['lastReadPage'] as String? ?? '1',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'format': format,
      'link': link,
      'userId': userId,
      'lastReadPage': lastReadPage,
    };
  }

  // Firestore helpers
  factory Book.fromFirestore(Map<String, dynamic> map, String docId) {
    return Book(
      id: docId,
      title: map['title'] as String,
      format: map['format'] as String,
      link: map['link'] as String,
      userId: map['userId'] as String,
      lastReadPage: map['lastReadPage'] as String? ?? '1',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'format': format,
      'link': link,
      'userId': userId,
      'lastReadPage': lastReadPage,
    };
  }
}
