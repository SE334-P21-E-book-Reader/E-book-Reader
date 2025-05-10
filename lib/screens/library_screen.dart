import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/book_grid.dart';
import '../widgets/book_list.dart';
import '../database/mock_database.dart';
import 'package:file_picker/file_picker.dart';
import '../screens/book_reader_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Mock book data
    final books = mockBooks;
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
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Imported!')),
                            );
                            // TODO: Handle the imported file (add to library, etc.)
                          } else {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Only PDF and EPUB files are supported.')),
                            );
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
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: l10n.searchBooks,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          filled: true,
                          fillColor: theme.inputDecorationTheme.fillColor ??
                              theme.colorScheme.surface,
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ViewModeButton(
                              icon: Icons.grid_view,
                              selected: _viewMode == 'grid',
                              onTap: () => setState(() => _viewMode = 'grid'),
                              tooltip: l10n.gridView,
                              theme: theme,
                            ),
                            _ViewModeButton(
                              icon: Icons.list,
                              selected: _viewMode == 'list',
                              onTap: () => setState(() => _viewMode = 'list'),
                              tooltip: l10n.listView,
                              theme: theme,
                            ),
                          ],
                        ),
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
              child: TabBarView(
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
                        ),
                  _viewMode == 'grid'
                      ? BookGrid(
                          books: books
                              .where((b) => b.format.toUpperCase() == 'EPUB')
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
                        )
                      : BookList(
                          books: books
                              .where((b) => b.format.toUpperCase() == 'EPUB')
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
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String tooltip;
  final ThemeData theme;

  const _ViewModeButton({
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.tooltip,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? (theme.brightness == Brightness.dark
              ? theme.colorScheme.primary.withValues(alpha: 0.25)
              : theme.colorScheme.primary.withValues(alpha: 0.12))
          : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(
            icon,
            color: selected ? theme.colorScheme.primary : theme.iconTheme.color,
            size: 20,
          ),
        ),
      ),
    );
  }
}
