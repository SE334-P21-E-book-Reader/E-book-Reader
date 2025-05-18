import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/library/book_grid.dart';
import '../widgets/library/book_list.dart';
// import '../database/mock_database.dart';
import 'package:file_picker/file_picker.dart';
import '../screens/book_reader_screen.dart';
import '../widgets/components/search_bar.dart' as components;
import '../widgets/components/icon_switch.dart';
// Will use BookCubit for book list
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/book/book_cubit.dart';
import 'dart:io';
import '../widgets/components/dialog_utils.dart';
import '../models/book.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        // _tabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showBookMenu(BuildContext context, Book book) async {
    final l10n = AppLocalizations.of(context)!;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
      ),
      items: [
        PopupMenuItem(value: 'read', child: Text(l10n.bookmark)),
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
    if (result == 'read') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BookReaderScreen(book: book)),
      );
    } else if (result == 'edit') {
      final books = context.read<BookCubit>().state.books;
      final existingNames =
          books.where((b) => b.id != book.id).map((b) => b.title).toList();
      final dotIdx = book.title.lastIndexOf('.');
      final originalExt = dotIdx > 0 ? book.title.substring(dotIdx) : '';
      final newName = await showRenameDialog(
        context,
        book.title,
        existingNames: existingNames,
        originalExtension: originalExt,
      );
      if (newName != null && newName != book.title) {
        await context
            .read<BookCubit>()
            .updateBook(bookId: book.id, newTitle: newName);
      }
    } else if (result == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete Book'),
          content: Text(
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
        await context.read<BookCubit>().deleteBook(book.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SafeArea(
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
                                'mockUser'; // Replace with real userId if using FirebaseAuth
                            Future<void> tryAddBook(String fileName) async {
                              await context.read<BookCubit>().addBook(
                                    file: File(file.path!),
                                    title: fileName,
                                    author: 'Unknown',
                                    format: file.extension!.toUpperCase(),
                                    userId: userId,
                                    onDuplicate: (msg) async {
                                      final books =
                                          context.read<BookCubit>().state.books;
                                      final existingNames =
                                          books.map((b) => b.title).toList();
                                      final dotIdx = file.name.lastIndexOf('.');
                                      final originalExt = dotIdx > 0
                                          ? file.name.substring(dotIdx)
                                          : '';
                                      final newName = await showRenameDialog(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              onBookClick: (book) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BookReaderScreen(book: book),
                                  ),
                                );
                              },
                              onBookLongPress: (book) =>
                                  _showBookMenu(context, book),
                            )
                          : BookList(
                              books: books,
                              searchQuery: _searchQuery,
                              onBookClick: (book) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BookReaderScreen(book: book),
                                  ),
                                );
                              },
                              onBookLongPress: (book) =>
                                  _showBookMenu(context, book),
                            ),
                      _viewMode == 'grid'
                          ? BookGrid(
                              books: books
                                  .where(
                                      (b) => b.format.toUpperCase() == 'EPUB')
                                  .toList(),
                              searchQuery: _searchQuery,
                              onBookClick: (book) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BookReaderScreen(book: book),
                                  ),
                                );
                              },
                              onBookLongPress: (book) =>
                                  _showBookMenu(context, book),
                            )
                          : BookList(
                              books: books
                                  .where(
                                      (b) => b.format.toUpperCase() == 'EPUB')
                                  .toList(),
                              searchQuery: _searchQuery,
                              onBookClick: (book) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BookReaderScreen(book: book),
                                  ),
                                );
                              },
                              onBookLongPress: (book) =>
                                  _showBookMenu(context, book),
                            ),
                      _viewMode == 'grid'
                          ? BookGrid(
                              books: books
                                  .where((b) => b.format.toUpperCase() == 'PDF')
                                  .toList(),
                              searchQuery: _searchQuery,
                              onBookClick: (book) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BookReaderScreen(book: book),
                                  ),
                                );
                              },
                              onBookLongPress: (book) =>
                                  _showBookMenu(context, book),
                            )
                          : BookList(
                              books: books
                                  .where((b) => b.format.toUpperCase() == 'PDF')
                                  .toList(),
                              searchQuery: _searchQuery,
                              onBookClick: (book) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BookReaderScreen(book: book),
                                  ),
                                );
                              },
                              onBookLongPress: (book) =>
                                  _showBookMenu(context, book),
                            ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
