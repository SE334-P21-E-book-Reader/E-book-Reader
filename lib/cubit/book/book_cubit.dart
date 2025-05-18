import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/book.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
part 'book_state.dart';

class BookCubit extends Cubit<BookState> {
  static const String _booksFile = 'books.json';
  BookCubit() : super(const BookState());

  // Load books from local storage
  Future<void> loadBooks() async {
    emit(state.copyWith(isLoading: true));
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final booksFile = File('${appDir.path}/$_booksFile');
      if (await booksFile.exists()) {
        final content = await booksFile.readAsString();
        final List<dynamic> jsonList = json.decode(content);
        final books = jsonList.map((e) => Book.fromMap(e)).toList();
        emit(state.copyWith(books: books, isLoading: false));
      } else {
        emit(state.copyWith(books: [], isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // Save books to local storage
  Future<void> _saveBooks(List<Book> books) async {
    final appDir = await getApplicationDocumentsDirectory();
    final booksFile = File('${appDir.path}/$_booksFile');
    final jsonList = books.map((b) => b.toMap()).toList();
    await booksFile.writeAsString(json.encode(jsonList));
  }

  // Helper to get a unique file path in app data
  String _getUniqueFilePath(String dir, String fileName) {
    var base = fileName;
    var ext = '';
    if (fileName.contains('.')) {
      base = fileName.substring(0, fileName.lastIndexOf('.'));
      ext = fileName.substring(fileName.lastIndexOf('.'));
    }
    var count = 1;
    var uniqueName = fileName;
    while (File('$dir/$uniqueName').existsSync()) {
      uniqueName = '$base($count)$ext';
      count++;
    }
    return '$dir/$uniqueName';
  }

  // Add a book: copy to app data, add to state, upload to Firebase
  Future<void> addBook({
    required File file,
    required String title,
    required String author,
    required String format,
    required String userId,
    void Function(String message)? onDuplicate,
    String? customFileName,
  }) async {
    emit(state.copyWith(isLoading: true));
    try {
      // Check for duplicate by file name
      final fileName = customFileName ?? file.path.split('/').last;
      final isDuplicate = state.books.any((b) => b.title == fileName);
      if (isDuplicate) {
        emit(state.copyWith(isLoading: false));
        if (onDuplicate != null) {
          onDuplicate('Duplicate file: $fileName');
        }
        return;
      }
      // Copy file to app data
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = _getUniqueFilePath(appDir.path, fileName);
      final localFile = await file.copy(localPath);
      // Create Book object with local link
      final book = Book(
        id: const Uuid().v4(),
        title: fileName,
        author: author,
        coverUrl: '',
        format: format,
        link: localFile.path, // local path for reading
        userId: userId,
        numberOfPage: 0, // TODO: parse number of pages
        lastPage: 1,
      );
      final updatedBooks = List<Book>.from(state.books)..add(book);
      emit(state.copyWith(books: updatedBooks, isLoading: false));
      await _saveBooks(updatedBooks);
      // Upload to Firebase Storage in background
      _uploadToFirebase(localFile, book, updatedBooks);
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // Upload file to Firebase and update book link
  Future<void> _uploadToFirebase(
      File localFile, Book book, List<Book> books) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('books/${book.userId}/${localFile.path.split('/').last}');
      await storageRef.putFile(localFile);
      final downloadUrl = await storageRef.getDownloadURL();
      // Update book with Firebase link
      final updatedBook = Book(
        id: book.id,
        title: book.title,
        author: book.author,
        coverUrl: book.coverUrl,
        format: book.format,
        link: downloadUrl, // now remote link
        userId: book.userId,
        numberOfPage: book.numberOfPage,
        lastPage: book.lastPage,
      );
      final updatedBooks =
          books.map((b) => b.id == book.id ? updatedBook : b).toList();
      emit(state.copyWith(books: updatedBooks));
      await _saveBooks(updatedBooks);
    } catch (e) {
      // Optionally handle upload error
    }
  }

  // Delete a book by id and remove its file
  Future<void> deleteBook(String bookId) async {
    Book book;
    try {
      book = state.books.firstWhere((b) => b.id == bookId);
    } catch (_) {
      return;
    }
    try {
      // Remove file from local storage
      final file = File(book.link);
      if (await file.exists()) {
        await file.delete();
      }
      // Remove from state
      final updatedBooks = List<Book>.from(state.books)
        ..removeWhere((b) => b.id == bookId);
      emit(state.copyWith(books: updatedBooks));
      await _saveBooks(updatedBooks);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  // Update a book's title (and optionally author)
  Future<void> updateBook(
      {required String bookId,
      required String newTitle,
      String? newAuthor}) async {
    final books = state.books;
    final idx = books.indexWhere((b) => b.id == bookId);
    if (idx == -1) return;
    final oldBook = books[idx];
    final updatedBook = Book(
      id: oldBook.id,
      title: newTitle,
      author: newAuthor ?? oldBook.author,
      coverUrl: oldBook.coverUrl,
      format: oldBook.format,
      link: oldBook.link,
      userId: oldBook.userId,
      numberOfPage: oldBook.numberOfPage,
      lastPage: oldBook.lastPage,
    );
    final updatedBooks = List<Book>.from(books);
    updatedBooks[idx] = updatedBook;
    emit(state.copyWith(books: updatedBooks));
    await _saveBooks(updatedBooks);
  }
}
