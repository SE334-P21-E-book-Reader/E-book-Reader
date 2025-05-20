import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../database/mock_database.dart';
import 'pdf_reader_screen.dart';
import '../widgets/components/search_bar.dart' as components;
import '../widgets/bookmark/bookmark_card.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  String _searchQuery = '';
  final List<Bookmark> _bookmarks = List.from(mockBookmarks);

  void _deleteBookmark(Bookmark bookmark) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.bookmarksDeleteTitle),
        content: Text(l10n.bookmarksDeleteConfirm),
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
      setState(() {
        _bookmarks.removeWhere((b) => b.id == bookmark.id);
      });
    }
  }

  // void _navigateToReader(Bookmark bookmark) {
  //   try {
  //     // final book = mockBooks.firstWhere((b) => b.id == bookmark.bookId);
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => BookReaderScreen(book: book),
  //       ),
  //     );
  //   } catch (e) {
  //     // Book not found, do nothing
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Filter bookmarks based on search query
    final filteredBookmarks = _bookmarks.where((bookmark) {
      final q = _searchQuery.toLowerCase();
      return bookmark.title.toLowerCase().contains(q) ||
          bookmark.author.toLowerCase().contains(q) ||
          bookmark.chapter.toLowerCase().contains(q) ||
          bookmark.snippet.toLowerCase().contains(q);
    }).toList();

    // Group bookmarks by book for book view mode, only keep the latest bookmark per book
    final Map<String, Bookmark> latestBookmarkByBook = {};
    for (final bookmark in filteredBookmarks) {
      final existing = latestBookmarkByBook[bookmark.bookId];
      if (existing == null || bookmark.timestamp.isAfter(existing.timestamp)) {
        latestBookmarkByBook[bookmark.bookId] = bookmark;
      }
    }
    // For book view, group by bookId, but only one bookmark per book
    final bookmarksByBook = latestBookmarkByBook;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.bookmarksTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                components.SearchBar(
                  hintText: l10n.bookmarksSearchHint,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  borderColor: colorScheme.secondary,
                  fillColor: theme.inputDecorationTheme.fillColor ??
                      colorScheme.surface,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: filteredBookmarks.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? l10n.bookmarksNotFound
                            : l10n.bookmarksEmpty,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.secondary),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: bookmarksByBook.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, idx) {
                        final bookId = bookmarksByBook.keys.elementAt(idx);
                        final bookmark = bookmarksByBook[bookId]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.bookmark, size: 18),
                                const SizedBox(width: 8),
                                Text(bookmark.title,
                                    style: textTheme.titleMedium),
                              ],
                            ),
                            const SizedBox(height: 8),
                            BookmarkCard(
                              bookmark: bookmark,
                              compact: true,
                              onDelete: () => _deleteBookmark(bookmark),
                              // onTap: () => _navigateToReader(bookmark),
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
