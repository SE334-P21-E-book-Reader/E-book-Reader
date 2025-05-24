import 'dart:async';
import 'dart:io';

// import '../database/mock_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Will use BookCubit for book list
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../bloc/book/book_cubit.dart';
import '../models/book.dart';
import '../widgets/components/dialog_utils.dart';
import '../widgets/components/icon_switch.dart';
import '../widgets/components/search_bar.dart' as components;
import '../widgets/library/book_grid.dart';
import '../widgets/library/book_list.dart';
import 'epub_reader_screen.dart';
import 'pdf_reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _viewMode = 'grid';
  late TabController _tabController;
  StreamSubscription? _booksSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    // Listen to books
    final cubit = context.read<BookCubit>();
    _booksSubscription = cubit.listenToBooks().listen((_) {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _booksSubscription?.cancel();
    super.dispose();
  }

  void _showBookMenu(BuildContext context, Book book, [String? action]) async {
    final result = action;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (book.userId != userId) return; // Only allow CRUD for own books
    if (result == 'edit') {
      final books = context.read<BookCubit>().state.books;
      final existingNames =
          books.where((b) => b.id != book.id).map((b) => b.title).toList();
      final newName = await showEditBookDialog(
        context,
        book.title,
        existingNames: existingNames,
      );
      if (newName != null && newName != book.title) {
        await context
            .read<BookCubit>()
            .updateBook(book: book, newTitle: newName);
      }
    } else if (result == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Book'),
          content: const Text(
              'Are you sure you want to delete this book? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await context.read<BookCubit>().deleteBook(book);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    void _handleBookMenu(Book book, [String? action]) =>
        _showBookMenu(context, book, action);
    void _handleBookTap(Book book) async {
      final cubit = context.read<BookCubit>();
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          cubit.getOrDownloadBookFile(book, onProgress: (p) {
            if (mounted) setState(() {});
          }).then((file) {
            Navigator.of(context).pop();
            if (book.format.toUpperCase() == 'PDF') {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      PDFReaderScreen(
                    book: book,
                    onSaveLastPage: (bookId, lastReadPage) async {
                      await cubit.updateLastReadPage(
                        bookId: bookId,
                        lastReadPage: lastReadPage,
                      );
                    },
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return child;
                  },
                ),
              );
            } else if (book.format.toUpperCase() == 'EPUB') {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      EPUBReaderScreen(book: book),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return child;
                  },
                ),
              );
            }
          });
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Downloading book...'),
                // ValueListenableBuilder<double>(
                //   valueListenable: ValueNotifier(progress),
                //   builder: (context, value, child) =>
                //       Text('${(progress * 100).toStringAsFixed(0)}%'),
                // ),
              ],
            ),
          );
        },
      );
    }

    return BlocListener<BookCubit, BookState>(
      listenWhen: (previous, current) =>
          previous.isLoading != current.isLoading,
      listener: (context, state) async {
        if (state.isLoading) {
          showLoadingDialog(context);
        } else {
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.library,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: l10n.addBook,
                          onPressed: () async {
                            FilePickerResult? result =
                                await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'epub'],
                            );
                            if (result != null && result.files.isNotEmpty) {
                              final file = result.files.first;
                              if (file.extension == 'pdf' ||
                                  file.extension == 'epub') {
                                if (!mounted) return;
                                final userId =
                                    FirebaseAuth.instance.currentUser?.uid;
                                if (userId == null) {
                                  showCustomDialog(
                                      context, 'You must be signed in.');
                                  return;
                                }
                                Future<void> tryAddBook(String fileName) async {
                                  await context.read<BookCubit>().addBook(
                                        file: File(file.path!),
                                        format: file.extension!.toUpperCase(),
                                        userId: userId,
                                        onDuplicate: (msg) async {
                                          final books = context
                                              .read<BookCubit>()
                                              .state
                                              .books;
                                          final existingNames = books
                                              .map((b) => b.title)
                                              .toList();
                                          final dotIdx =
                                              file.name.lastIndexOf('.');
                                          final originalExt = dotIdx > 0
                                              ? file.name.substring(dotIdx)
                                              : '';
                                          final newName =
                                              await showRenameDialog(
                                            context,
                                            fileName,
                                            existingNames: existingNames,
                                            originalExtension: originalExt,
                                          );
                                          if (newName != null &&
                                              newName != fileName) {
                                            await tryAddBook(newName);
                                          }
                                        },
                                        customFileName: fileName,
                                      );
                                }

                                await tryAddBook(file.name);
                              } else {
                                if (!mounted) return;
                                showCustomDialog(context,
                                    'Only PDF and EPUB files are supported.');
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: components.SearchBar(
                            hintText: l10n.searchBooks,
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                            borderColor: theme.dividerColor,
                            fillColor: theme.inputDecorationTheme.fillColor ??
                                theme.colorScheme.surface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 40,
                          child: IconSwitch(
                            items: [
                              IconSwitchItem(
                                icon: Icons.grid_view,
                                tooltip: l10n.gridView,
                                selected: _viewMode == 'grid',
                                onTap: () => setState(() => _viewMode = 'grid'),
                                theme: theme,
                              ),
                              IconSwitchItem(
                                icon: Icons.list,
                                tooltip: l10n.listView,
                                selected: _viewMode == 'list',
                                onTap: () => setState(() => _viewMode = 'list'),
                                theme: theme,
                              ),
                            ],
                            borderColor: theme.dividerColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(text: l10n.all),
                        Tab(text: l10n.epub),
                        Tab(text: l10n.pdf),
                      ],
                    ),
                  ],
                ),
              ),
              // Book Content
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: BlocBuilder<BookCubit, BookState>(
                    builder: (context, state) {
                      final books = state.books;
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _viewMode == 'grid'
                              ? BookGrid(
                                  books: books,
                                  searchQuery: _searchQuery,
                                  onBookClick: _handleBookTap,
                                  onBookLongPress: _handleBookMenu,
                                )
                              : BookList(
                                  books: books,
                                  searchQuery: _searchQuery,
                                  onBookClick: _handleBookTap,
                                  onBookLongPress: _handleBookMenu,
                                ),
                          _viewMode == 'grid'
                              ? BookGrid(
                                  books: books
                                      .where((b) =>
                                          b.format.toUpperCase() == 'EPUB')
                                      .toList(),
                                  searchQuery: _searchQuery,
                                  onBookClick: _handleBookTap,
                                  onBookLongPress: _handleBookMenu,
                                )
                              : BookList(
                                  books: books
                                      .where((b) =>
                                          b.format.toUpperCase() == 'EPUB')
                                      .toList(),
                                  searchQuery: _searchQuery,
                                  onBookClick: _handleBookTap,
                                  onBookLongPress: _handleBookMenu,
                                ),
                          _viewMode == 'grid'
                              ? BookGrid(
                                  books: books
                                      .where((b) =>
                                          b.format.toUpperCase() == 'PDF')
                                      .toList(),
                                  searchQuery: _searchQuery,
                                  onBookClick: _handleBookTap,
                                  onBookLongPress: _handleBookMenu,
                                )
                              : BookList(
                                  books: books
                                      .where((b) =>
                                          b.format.toUpperCase() == 'PDF')
                                      .toList(),
                                  searchQuery: _searchQuery,
                                  onBookClick: _handleBookTap,
                                  onBookLongPress: _handleBookMenu,
                                ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
