import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class ReaderState extends Equatable {
  final String bookId;
  final int? currentPage; // For PDF
  final int? totalPages; // For PDF
  final String? epubCfi; // For EPUB
  final double fontSize;

  const ReaderState({
    required this.bookId,
    this.currentPage,
    this.totalPages,
    this.epubCfi,
    this.fontSize = 13,
  });

  ReaderState copyWith({
    int? currentPage,
    int? totalPages,
    String? epubCfi,
    double? fontSize,
  }) {
    return ReaderState(
      bookId: bookId,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      epubCfi: epubCfi ?? this.epubCfi,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  @override
  List<Object?> get props =>
      [bookId, currentPage, totalPages, epubCfi, fontSize];
}

class ReaderCubit extends Cubit<ReaderState> {
  ReaderCubit(String bookId) : super(ReaderState(bookId: bookId));

  void setPdfPage(int page) => emit(state.copyWith(currentPage: page));
  void setTotalPages(int pages) => emit(state.copyWith(totalPages: pages));
  void setEpubCfi(String cfi) => emit(state.copyWith(epubCfi: cfi));
  void setFontSize(double size) => emit(state.copyWith(fontSize: size));
}
