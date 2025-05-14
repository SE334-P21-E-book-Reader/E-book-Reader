import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../database/mock_database.dart';

class BookmarkCard extends StatelessWidget {
  final Bookmark bookmark;
  final bool compact;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const BookmarkCard({
    Key? key,
    required this.bookmark,
    this.compact = false,
    this.onDelete,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              EdgeInsets.symmetric(vertical: compact ? 8 : 16, horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact)
                Container(
                  width: 40,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.surfaceVariant,
                  ),
                  child: const Icon(Icons.menu_book, size: 32),
                ),
              if (!compact) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!compact) ...[
                      Text(bookmark.title,
                          style: textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(bookmark.author,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.secondary)),
                    ],
                    Text(bookmark.chapter, style: textTheme.bodyMedium),
                    Text(bookmark.snippet,
                        style: textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.bookmarksPage(bookmark.page),
                            style: textTheme.bodySmall
                                ?.copyWith(color: colorScheme.secondary)),
                        Text(bookmark.date,
                            style: textTheme.bodySmall
                                ?.copyWith(color: colorScheme.secondary)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: colorScheme.error, size: 18,),
                onPressed: onDelete,
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
