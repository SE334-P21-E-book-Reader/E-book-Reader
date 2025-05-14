import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'book_grid.dart';

const String kPlaceholderImage = 'https://placehold.jp/80x120.png';

class BookList extends StatelessWidget {
  final List<Book> books;
  final String searchQuery;
  final void Function(Book) onBookClick;

  const BookList({
    super.key,
    required this.books,
    required this.searchQuery,
    required this.onBookClick,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final filteredBooks = books.where((book) {
      final query = searchQuery.toLowerCase();
      return book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query);
    }).toList();

    if (filteredBooks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
          child: Text(
            l10n.noBooksFound,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.secondary,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: filteredBooks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final book = filteredBooks[index];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onBookClick(book),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.secondary),
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surface,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    (book.coverUrl != null && book.coverUrl!.isNotEmpty)
                        ? book.coverUrl!
                        : kPlaceholderImage,
                    width: 40,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: colorScheme.surface,
                      width: 40,
                      height: 56,
                      child: const Icon(Icons.broken_image,
                          color: Colors.grey, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        book.author,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colorScheme.secondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.description,
                              size: 14, color: colorScheme.secondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${book.format} • 1MB', // TODO: Replace 1MB with real size if available
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colorScheme.secondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
