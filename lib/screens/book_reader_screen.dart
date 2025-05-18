import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/theme/theme_cubit.dart';
import '../models/book.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import '../cubit/reader_cubit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../cubit/language/language_cubit.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookReaderScreen extends StatelessWidget {
  final Book book;
  const BookReaderScreen({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReaderCubit>(
      create: (_) => ReaderCubit(book.id),
      child: _BookReaderScreenBody(key: ValueKey(book.id), book: book),
    );
  }
}

class _BookReaderScreenBody extends StatefulWidget {
  final Book book;
  const _BookReaderScreenBody({Key? key, required this.book}) : super(key: key);

  @override
  State<_BookReaderScreenBody> createState() => _BookReaderScreenBodyState();
}

class _BookReaderScreenBodyState extends State<_BookReaderScreenBody> with AutomaticKeepAliveClientMixin {
  static final Map<String, PdfViewerController> _controllerCache = {};
  static final Map<String, Future<String>> _futureCache = {};

  PdfViewerController get _pdfController =>
      _controllerCache.putIfAbsent(widget.book.id, () => PdfViewerController());
  Future<String> get _pdfPathFuture =>
      _futureCache.putIfAbsent(widget.book.id, () => _getLocalPdfPath(widget.book.link));

  bool isBookmarked = false;
  late final EpubController _epubController = EpubController();
  PdfBookmarkBase? _pdfBookmarks;
  bool _isSearching = false;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;
  OverlayEntry? _overlayEntry;
  PdfScrollDirection _scrollDirection = PdfScrollDirection.vertical;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadScrollDirection();
    _searchResult.addListener(_onSearchResultChanged);
  }

  Future<void> _loadScrollDirection() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('reader_scroll_direction');
    setState(() {
      if (saved == 'horizontal') {
        _scrollDirection = PdfScrollDirection.horizontal;
      } else {
        _scrollDirection = PdfScrollDirection.vertical;
      }
    });
  }

  Future<void> _saveScrollDirection(PdfScrollDirection direction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reader_scroll_direction', direction == PdfScrollDirection.horizontal ? 'horizontal' : 'vertical');
  }

  void _onSearchResultChanged() {
    if (mounted) setState(() {
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _searchResult.removeListener(_onSearchResultChanged);
    _searchResult.dispose();
    super.dispose();
  }

  void _startSearch(String value) {
    final searchValue = value.toLowerCase();
    if (searchValue.isEmpty) {
      setState(() {
        _searchText = '';
        _searchResult.removeListener(_onSearchResultChanged);
        _searchResult.clear();
        _searchResult.addListener(_onSearchResultChanged);
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
    });

    _searchResult.removeListener(_onSearchResultChanged);
    _searchResult = _pdfController.searchText(
      searchValue,
    );
    _searchResult.addListener(_onSearchResultChanged);

    setState(() {
      _searchText = searchValue;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchText = '';
      _searchController.clear();
      _searchResult.removeListener(_onSearchResultChanged);
      _searchResult.clear();
      _searchResult.addListener(_onSearchResultChanged);
      _showSearchBar = false;
    });
  }

  void _showPdfTocDialog(BuildContext context) {
    if (_pdfBookmarks == null || _pdfBookmarks!.count == 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.contents),
          content: const Text('No table of contents available.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.contents),
        content: SizedBox(
          width: 300,
          height: 400,
          child: ListView(
            children: _buildBookmarkList(_pdfBookmarks!),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBookmarkList(PdfBookmarkBase bookmarks, {int indent = 0}) {
    List<Widget> widgets = [];
    for (int i = 0; i < bookmarks.count; i++) {
      final bookmark = bookmarks[i];
      widgets.add(ListTile(
        contentPadding: EdgeInsets.only(left: 16.0 * indent),
        title: Text(bookmark.title),
        onTap: () {
          Navigator.of(context).pop();
          if (bookmark is PdfBookmark) {
            _pdfController.jumpToBookmark(bookmark);
          }
        },
      ));
      if (bookmark.count > 0) {
        widgets.addAll(_buildBookmarkList(bookmark, indent: indent + 1));
      }
    }
    return widgets;
  }

  void _showEpubTocDialog(BuildContext context) {
    // flutter_epub_viewer does not expose TOC, so show a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.contents),
        content:
            const Text('Table of contents is not available for this EPUB.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        // No title to hide the PDF/book name
        actions: [
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            tooltip: l10n.search,
            onPressed: () {
              setState(() {
                if (_showSearchBar) {
                  _clearSearch();
                } else {
                  _showSearchBar = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            tooltip: 'Reset Zoom',
            onPressed: () {
              setState(() {
                _pdfController.zoomLevel = 1.0;
              });
            },
          ),
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? colorScheme.primary : colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() {
                isBookmarked = !isBookmarked;
              });
            },
            tooltip: l10n.bookmark,
          ),
          IconButton(
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              final themeCubit = context.read<ThemeCubit>();
              themeCubit.setThemeMode(
                theme.brightness == Brightness.dark
                    ? ThemeMode.light
                    : ThemeMode.dark,
              );
            },
            tooltip: theme.brightness == Brightness.dark
                ? l10n.theme
                : l10n.darkMode,
          ),
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: l10n.contents,
            onPressed: () {
              if (widget.book.format.toUpperCase() == 'PDF') {
                _showPdfTocDialog(context);
              } else {
                _showEpubTocDialog(context);
              }
            },
          ),
          IconButton(
            icon: Icon(_scrollDirection == PdfScrollDirection.vertical ? Icons.swap_horiz : Icons.swap_vert),
            tooltip: _scrollDirection == PdfScrollDirection.vertical
                ? 'Switch to Horizontal Scroll'
                : 'Switch to Vertical Scroll',
            onPressed: () {
              setState(() {
                _scrollDirection = _scrollDirection == PdfScrollDirection.vertical
                    ? PdfScrollDirection.horizontal
                    : PdfScrollDirection.vertical;
              });
              _saveScrollDirection(_scrollDirection);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.book.format.toUpperCase() == 'PDF' && _showSearchBar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Flexible(
                    flex: 6,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.search,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: _searchText.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearSearch,
                              )
                            : null,
                      ),
                      autofocus: false,
                      onSubmitted: _startSearch,
                    ),
                  ),
                  SizedBox(width: 8),
                  if (_searchText.isNotEmpty)
                    Flexible(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            tooltip: 'Previous',
                            onPressed: (_searchResult.totalInstanceCount > 0)
                                ? () {
                                    setState(() {
                                      _searchResult.previousInstance();
                                    });
                                  }
                                : null,
                          ),
                          Text(
                            _searchResult.totalInstanceCount > 0
                                ? '${_searchResult.currentInstanceIndex} / ${_searchResult.totalInstanceCount}'
                                : '0 / 0',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            tooltip: 'Next',
                            onPressed: (_searchResult.totalInstanceCount > 0)
                                ? () {
                                    setState(() {
                                      _searchResult.nextInstance();
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: widget.book.format.toUpperCase() == 'PDF'
                ? FutureBuilder<String>(
                    future: _pdfPathFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                            child: Text('Failed to load PDF: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: Text('No PDF file found.'));
                      }
                      final localPath = snapshot.data!;
                      final file = File(localPath);
                      if (!file.existsSync() && !localPath.startsWith('http')) {
                        return Center(
                            child: Text('PDF file does not exist at $localPath'));
                      }
                      final pdfViewer = localPath.startsWith('http')
                          ? SfPdfViewer.network(
                              localPath,
                              key: _pdfViewerKey,
                              controller: _pdfController,
                              enableTextSelection: true,
                              canShowTextSelectionMenu: true,
                              canShowScrollHead: true,
                              canShowScrollStatus: true,
                              scrollDirection: _scrollDirection,
                              pageLayoutMode: _scrollDirection == PdfScrollDirection.horizontal
                                  ? PdfPageLayoutMode.single
                                  : PdfPageLayoutMode.continuous,
                              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                                setState(() {
                                  _pdfBookmarks = details.document.bookmarks;
                                  _totalPages = details.document.pages.count;
                                });
                                context.read<ReaderCubit>().setTotalPages(details.document.pages.count);
                              },
                              onPageChanged: (PdfPageChangedDetails details) {
                                setState(() {
                                  _currentPage = details.newPageNumber;
                                });
                                context.read<ReaderCubit>().setPdfPage(details.newPageNumber);
                              },
                              onAnnotationAdded: (annotation) async {
                                // Only allow one annotation of the same type on the same text selection
                                final annotations = _pdfController.getAnnotations();
                                // Find duplicates of the same type on the same text
                                for (final existing in annotations) {
                                  if (existing == annotation) continue;
                                  if (existing.runtimeType == annotation.runtimeType) {
                                    // Compare the selected text or bounds if possible
                                    if (existing.toString() == annotation.toString()) {
                                      // Remove the previous annotation of the same type on the same text
                                      _pdfController.removeAnnotation(existing);
                                    }
                                  }
                                }
                              },
                              enableHyperlinkNavigation: true,
                              enableDocumentLinkAnnotation: true,
                              enableDoubleTapZooming: true,
                              maxZoomLevel: 5.0,
                              onZoomLevelChanged: (details) {
                                // Optionally handle zoom level changes (e.g., analytics, logging)
                              },
                            )
                          : SfPdfViewer.file(
                              file,
                              key: _pdfViewerKey,
                              controller: _pdfController,
                              enableTextSelection: true,
                              canShowTextSelectionMenu: true,
                              canShowScrollHead: true,
                              canShowScrollStatus: true,
                              scrollDirection: _scrollDirection,
                              pageLayoutMode: _scrollDirection == PdfScrollDirection.horizontal
                                  ? PdfPageLayoutMode.single
                                  : PdfPageLayoutMode.continuous,
                              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                                setState(() {
                                  _pdfBookmarks = details.document.bookmarks;
                                  _totalPages = details.document.pages.count;
                                });
                                context.read<ReaderCubit>().setTotalPages(details.document.pages.count);
                              },
                              onPageChanged: (PdfPageChangedDetails details) {
                                setState(() {
                                  _currentPage = details.newPageNumber;
                                });
                                context.read<ReaderCubit>().setPdfPage(details.newPageNumber);
                              },
                              onAnnotationAdded: (annotation) async {
                                // Only allow one annotation of the same type on the same text selection
                                final annotations = _pdfController.getAnnotations();
                                // Find duplicates of the same type on the same text
                                for (final existing in annotations) {
                                  if (existing == annotation) continue;
                                  if (existing.runtimeType == annotation.runtimeType) {
                                    // Compare the selected text or bounds if possible
                                    if (existing.toString() == annotation.toString()) {
                                      // Remove the previous annotation of the same type on the same text
                                      _pdfController.removeAnnotation(existing);
                                      _pdfController.removeAnnotation(annotation);
                                    }
                                  }
                                }
                              },
                              enableHyperlinkNavigation: true,
                              enableDocumentLinkAnnotation: true,
                              enableDoubleTapZooming: true,
                              maxZoomLevel: 5.0,
                              onZoomLevelChanged: (details) {
                                // Optionally handle zoom level changes (e.g., analytics, logging)
                              },
                            );
                      return Stack(
                        children: [
                          pdfViewer,
                          if (_scrollDirection == PdfScrollDirection.horizontal)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                color: Theme.of(context).colorScheme.surface,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.first_page),
                                      tooltip: 'First Page',
                                      onPressed: _currentPage > 1
                                          ? () {
                                              _pdfController.jumpToPage(1);
                                            }
                                          : null,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left),
                                      tooltip: 'Previous Page',
                                      onPressed: _currentPage > 1
                                          ? () {
                                              _pdfController.previousPage();
                                            }
                                          : null,
                                    ),
                                    Text(
                                      'Page $_currentPage/$_totalPages',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right),
                                      tooltip: 'Next Page',
                                      onPressed: _currentPage < _totalPages
                                          ? () {
                                              _pdfController.nextPage();
                                            }
                                          : null,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.last_page),
                                      tooltip: 'Last Page',
                                      onPressed: _currentPage < _totalPages
                                          ? () {
                                              _pdfController.jumpToPage(_totalPages);
                                            }
                                          : null,
                                    ),
                                    const Spacer(),
                                    if (_totalPages > 0)
                                      Container(
                                        margin: const EdgeInsets.only(right: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${((_currentPage / _totalPages) * 100).toStringAsFixed(0)}%',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  )
                : EpubViewer(
                    epubSource: EpubSource.fromFile(File(widget.book.link)),
                    epubController: _epubController,
                  ),
          ),
        ],
      ),
    );
  }

  Future<String> _getLocalPdfPath(String link) async {
    if (link.startsWith('http')) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = link.split('/').last.split('?').first;
      final localPath = '${appDir.path}/$fileName';
      final localFile = File(localPath);
      if (!await localFile.exists()) {
        final response = await http.get(Uri.parse(link));
        if (response.statusCode == 200) {
          await localFile.writeAsBytes(response.bodyBytes);
        } else {
          throw Exception('Failed to download PDF: ${response.statusCode}');
        }
      }
      return localPath;
    } else {
      return link;
    }
  }
}

bool isInAppData(String path) {
  if (!Platform.isAndroid) return true; // Always allow on non-Android
  return path.contains('/app_flutter/') ||
      path.contains('/data/user/0/') ||
      path.contains('/data/data/');
}
