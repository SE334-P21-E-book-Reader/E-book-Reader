// Book model for the app, including Firebase Storage link and user data
class Book {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String format; // 'PDF' or 'EPUB'
  final String link; // Firebase Storage link
  final String userId;
  final int numberOfPage;
  final int lastPage;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.format,
    required this.link,
    required this.userId,
    required this.numberOfPage,
    required this.lastPage,
  });

  // Add fromMap/toMap for Firebase/Local storage
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String,
      coverUrl: map['coverUrl'] as String?,
      format: map['format'] as String,
      link: map['link'] as String,
      userId: map['userId'] as String,
      numberOfPage: map['numberOfPage'] as int? ?? 0,
      lastPage: map['lastPage'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'format': format,
      'link': link,
      'userId': userId,
      'numberOfPage': numberOfPage,
      'lastPage': lastPage,
    };
  }
}
