part of 'book_cubit.dart';

class BookState extends Equatable {
  final List<Book> books;
  final bool isLoading;
  final String? error;

  const BookState({
    this.books = const [],
    this.isLoading = false,
    this.error,
  });

  BookState copyWith({
    List<Book>? books,
    bool? isLoading,
    String? error,
  }) {
    return BookState(
      books: books ?? this.books,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [books, isLoading, error];
}
