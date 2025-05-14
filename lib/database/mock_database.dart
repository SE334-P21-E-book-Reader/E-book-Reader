import '../widgets/library/book_grid.dart';

final List<Book> mockBooks = [
  Book(
    id: '1',
    title: 'The Great Gatsby',
    author: 'F. Scott Fitzgerald',
    coverUrl: '',
    format: 'EPUB',
  ),
  Book(
    id: '2',
    title: '1984',
    author: 'George Orwell',
    coverUrl: '',
    format: 'PDF',
  ),
  Book(
    id: '3',
    title: 'To Kill a Mockingbird',
    author: 'Harper Lee',
    coverUrl: '',
    format: 'EPUB',
  ),
  Book(
    id: '4',
    title: 'Pride and Prejudice',
    author: 'Jane Austen',
    coverUrl: '',
    format: 'PDF',
  ),
];

class Bookmark {
  final String id;
  final String bookId;
  final String title;
  final String author;
  final String chapter;
  final String snippet;
  final int page;
  final double position;
  final String date;
  final DateTime timestamp;
  final String coverUrl;

  Bookmark({
    required this.id,
    required this.bookId,
    required this.title,
    required this.author,
    required this.chapter,
    required this.snippet,
    required this.page,
    required this.position,
    required this.date,
    required this.timestamp,
    required this.coverUrl,
  });
}

final List<Bookmark> mockBookmarks = [
  Bookmark(
    id: '1',
    bookId: '1',
    title: 'The Great Gatsby',
    author: 'F. Scott Fitzgerald',
    chapter: 'Chapter 3: The Meeting',
    snippet:
        'Santiago trải áo khoác xuống sàn và nằm xuống, dùng cuốn sách vừa đọc xong làm gối...',
    page: 42,
    position: 0.22,
    date: 'Hôm qua',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    coverUrl: '',
  ),
  Bookmark(
    id: '2',
    bookId: '2',
    title: '1984',
    author: 'George Orwell',
    chapter: 'Chapter 5: The Journey',
    snippet:
        'Anh ta đã đi qua sa mạc nhiều lần, nhưng chàng trai vẫn luôn bị mê hoặc bởi nó...',
    page: 78,
    position: 0.41,
    date: '3 ngày trước',
    timestamp: DateTime.now().subtract(const Duration(days: 3)),
    coverUrl: '',
  ),
  Bookmark(
    id: '3',
    bookId: '3',
    title: 'To Kill a Mockingbird',
    author: 'Harper Lee',
    chapter: 'Chapter 5: The Journey',
    snippet:
        'Hãy thành thật quan tâm đến người khác. Bạn có thể có được nhiều bạn bè trong hai tháng...',
    page: 78,
    position: 0.35,
    date: '3 ngày trước',
    timestamp: DateTime.now().subtract(const Duration(days: 3)),
    coverUrl: '',
  ),
  Bookmark(
    id: '4',
    bookId: '4',
    title: 'Pride and Prejudice',
    author: 'Jane Austen',
    chapter: 'Chapter 2: The Method of Thinking',
    snippet:
        'Tư duy phản biện là quá trình phân tích và đánh giá thông tin một cách khách quan...',
    page: 23,
    position: 0.12,
    date: '1 tuần trước',
    timestamp: DateTime.now().subtract(const Duration(days: 7)),
    coverUrl: '',
  ),
];
