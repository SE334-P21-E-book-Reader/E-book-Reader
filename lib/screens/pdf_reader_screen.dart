import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/theme/theme_cubit.dart';
import '../models/book.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../bloc/reader/pdf/pdf_reader_cubit.dart';
import '../bloc/reader/pdf/pdf_reader_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../bloc/language/language_cubit.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PDFReaderScreen extends StatelessWidget {
  final Book book;
  const PDFReaderScreen({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PdfReaderCubit>(
      create: (_) => PdfReaderCubit(),
      child: _PDFReaderScreenBody(key: ValueKey(book.id), book: book),
    );
  }
}

class _PDFReaderScreenBody extends StatefulWidget {
  final Book book;
  const _PDFReaderScreenBody({Key? key, required this.book}) : super(key: key);

  @override
  State<_PDFReaderScreenBody> createState() => _PDFReaderScreenBodyState();
}

class _PDFReaderScreenBodyState extends State<_PDFReaderScreenBody>
    with AutomaticKeepAliveClientMixin {
  static final Map<String, PdfViewerController> _controllerCache = {};
  static final Map<String, Future<String>> _futureCache = {};

  PdfViewerController get _pdfController =>
      _controllerCache.putIfAbsent(widget.book.id, () => PdfViewerController());
  Future<String> get _pdfPathFuture => _futureCache.putIfAbsent(
      widget.book.id, () => _getLocalPdfPath(widget.book.link));

  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  PdfBookmarkBase? _rootBookmark;
  PdfTextSearchResult? _searchResult;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchResult?.removeListener(_onSearchResultChanged);
    super.dispose();
  }

  void _onSearchResultChanged() {
    if (mounted) setState(() {});
  }

  void _startSearch(String value) {
    final searchValue = value.trim();
    if (searchValue.isEmpty) {
      _clearSearch();
      return;
    }
    _searchResult?.removeListener(_onSearchResultChanged);
    _searchResult = _pdfController.searchText(searchValue);
    _searchResult?.addListener(_onSearchResultChanged);
    context.read<PdfReaderCubit>().setSearchText(searchValue);
    context.read<PdfReaderCubit>().setSearching(true);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchResult?.removeListener(_onSearchResultChanged);
    _searchResult?.clear();
    _searchResult = null;
    context.read<PdfReaderCubit>().setSearchText('');
    context.read<PdfReaderCubit>().setSearching(false);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadScrollDirection();
  }

  Future<void> _loadScrollDirection() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('reader_scroll_direction');
    final cubit = context.read<PdfReaderCubit>();
    if (saved == 'horizontal') {
      cubit.setScrollDirection(PdfScrollDirection.horizontal);
    } else {
      cubit.setScrollDirection(PdfScrollDirection.vertical);
    }
  }

  Future<void> _saveScrollDirection(PdfScrollDirection direction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reader_scroll_direction',
        direction == PdfScrollDirection.horizontal ? 'horizontal' : 'vertical');
  }

  List<Widget> _buildBookmarkList(PdfBookmarkBase bookmark) {
    List<Widget> children = [];
    for (var i = 0; i < bookmark.count; i++) {
      final child = bookmark[i];
      if (child.count > 0) {
        children.add(
          ExpansionTile(
            title: Text(child.title ?? 'Untitled'),
            children: _buildBookmarkList(child),
            onExpansionChanged: (_) {},
          ),
        );
      } else {
        children.add(
          ListTile(
            title: Text(child.title ?? 'Untitled'),
            onTap: () {
              if (child is PdfBookmark) {
                _pdfController.jumpToBookmark(child);
                Navigator.of(context).maybePop();
              }
            },
          ),
        );
      }
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPdf = widget.book.format.toUpperCase() == 'PDF';
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        actions: [
          BlocBuilder<PdfReaderCubit, PdfReaderState>(
            builder: (context, state) => IconButton(
              icon: Icon(state.isSearching ? Icons.close : Icons.search),
              tooltip: l10n.search,
              onPressed: () {
                if (state.isSearching) {
                  _clearSearch();
                } else {
                  context.read<PdfReaderCubit>().setSearching(true);
                }
              },
            ),
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
          BlocBuilder<PdfReaderCubit, PdfReaderState>(
            builder: (context, state) => IconButton(
              icon: Icon(
                state.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: state.isBookmarked
                    ? colorScheme.primary
                    : colorScheme.onSurface,
              ),
              onPressed: () {
                context
                    .read<PdfReaderCubit>()
                    .setBookmarked(!state.isBookmarked);
              },
              tooltip: l10n.bookmark,
            ),
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
          BlocBuilder<PdfReaderCubit, PdfReaderState>(
            builder: (context, state) => IconButton(
              icon: const Icon(Icons.menu_book),
              tooltip: l10n.contents,
              onPressed: () {
                if (isPdf) {
                  _scaffoldKey.currentState?.openEndDrawer();
                }
              },
            ),
          ),
          BlocBuilder<PdfReaderCubit, PdfReaderState>(
            builder: (context, state) => IconButton(
              icon: Icon(state.scrollDirection == PdfScrollDirection.vertical
                  ? Icons.swap_horiz
                  : Icons.swap_vert),
              tooltip: state.scrollDirection == PdfScrollDirection.vertical
                  ? 'Switch to Horizontal Scroll'
                  : 'Switch to Vertical Scroll',
              onPressed: () {
                final cubit = context.read<PdfReaderCubit>();
                final newDirection =
                    state.scrollDirection == PdfScrollDirection.vertical
                        ? PdfScrollDirection.horizontal
                        : PdfScrollDirection.vertical;
                cubit.setScrollDirection(newDirection);
                _saveScrollDirection(newDirection);
              },
            ),
          ),
        ],
      ),
      body: BlocBuilder<PdfReaderCubit, PdfReaderState>(
        builder: (context, state) => Column(
          children: [
            if (isPdf && state.isSearching)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          suffixIcon: state.searchText.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearSearch,
                                )
                              : null,
                        ),
                        autofocus: true,
                        onSubmitted: _startSearch,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_searchResult != null &&
                        _searchResult!.totalInstanceCount > 0)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            tooltip: 'Previous',
                            onPressed: () {
                              _searchResult!.previousInstance();
                              setState(() {});
                            },
                          ),
                          Text(
                            '${_searchResult!.currentInstanceIndex} / ${_searchResult!.totalInstanceCount}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            tooltip: 'Next',
                            onPressed: () {
                              _searchResult!.nextInstance();
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            Expanded(
              child: isPdf
                  ? FutureBuilder<String>(
                      future: _pdfPathFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text(
                                  'Failed to load PDF: \\${snapshot.error}'));
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                              child: Text('No PDF file found.'));
                        }
                        final localPath = snapshot.data!;
                        final file = File(localPath);
                        if (!file.existsSync() &&
                            !localPath.startsWith('http')) {
                          return Center(
                              child: Text(
                                  'PDF file does not exist at \\${localPath}'));
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
                                scrollDirection: state.scrollDirection,
                                pageLayoutMode: state.scrollDirection ==
                                        PdfScrollDirection.horizontal
                                    ? PdfPageLayoutMode.single
                                    : PdfPageLayoutMode.continuous,
                                onDocumentLoaded:
                                    (PdfDocumentLoadedDetails details) {
                                  context.read<PdfReaderCubit>().setTotalPages(
                                      details.document.pages.count);
                                  setState(() {
                                    _rootBookmark = details.document.bookmarks;
                                  });
                                },
                                onPageChanged: (PdfPageChangedDetails details) {
                                  context
                                      .read<PdfReaderCubit>()
                                      .setCurrentPage(details.newPageNumber);
                                },
                                enableHyperlinkNavigation: true,
                                enableDocumentLinkAnnotation: true,
                                enableDoubleTapZooming: true,
                                maxZoomLevel: 5.0,
                              )
                            : SfPdfViewer.file(
                                file,
                                key: _pdfViewerKey,
                                controller: _pdfController,
                                enableTextSelection: true,
                                canShowTextSelectionMenu: true,
                                canShowScrollHead: true,
                                canShowScrollStatus: true,
                                scrollDirection: state.scrollDirection,
                                pageLayoutMode: state.scrollDirection ==
                                        PdfScrollDirection.horizontal
                                    ? PdfPageLayoutMode.single
                                    : PdfPageLayoutMode.continuous,
                                onDocumentLoaded:
                                    (PdfDocumentLoadedDetails details) {
                                  context.read<PdfReaderCubit>().setTotalPages(
                                      details.document.pages.count);
                                  setState(() {
                                    _rootBookmark = details.document.bookmarks;
                                  });
                                },
                                onPageChanged: (PdfPageChangedDetails details) {
                                  context
                                      .read<PdfReaderCubit>()
                                      .setCurrentPage(details.newPageNumber);
                                },
                                enableHyperlinkNavigation: true,
                                enableDocumentLinkAnnotation: true,
                                enableDoubleTapZooming: true,
                                maxZoomLevel: 5.0,
                              );
                        return Stack(
                          children: [
                            pdfViewer,
                            if (state.scrollDirection ==
                                PdfScrollDirection.horizontal)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  color: Theme.of(context).colorScheme.surface,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.first_page),
                                        tooltip: 'First Page',
                                        onPressed: state.currentPage > 1
                                            ? () {
                                                _pdfController.jumpToPage(1);
                                              }
                                            : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left),
                                        tooltip: 'Previous Page',
                                        onPressed: state.currentPage > 1
                                            ? () {
                                                _pdfController.previousPage();
                                              }
                                            : null,
                                      ),
                                      Text(
                                        'Page ${state.currentPage}/${state.totalPages}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right),
                                        tooltip: 'Next Page',
                                        onPressed:
                                            state.currentPage < state.totalPages
                                                ? () {
                                                    _pdfController.nextPage();
                                                  }
                                                : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.last_page),
                                        tooltip: 'Last Page',
                                        onPressed:
                                            state.currentPage < state.totalPages
                                                ? () {
                                                    _pdfController.jumpToPage(
                                                        state.totalPages);
                                                  }
                                                : null,
                                      ),
                                      const Spacer(),
                                      if (state.totalPages > 0)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(right: 4),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${((state.currentPage / state.totalPages) * 100).toStringAsFixed(0)}%',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
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
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                child: Text(
                  'Table of Contents',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: _rootBookmark == null
                    ? Center(child: Text('No bookmarks'))
                    : ListView(
                        children: _buildBookmarkList(_rootBookmark!),
                      ),
              ),
            ],
          ),
        ),
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
