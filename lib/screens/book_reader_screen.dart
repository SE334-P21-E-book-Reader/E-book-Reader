import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/theme/theme_cubit.dart';
import '../models/book.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import '../cubit/reader_cubit.dart';

class BookReaderScreen extends StatelessWidget {
  final Book book;
  const BookReaderScreen({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReaderCubit>(
      create: (_) => ReaderCubit(book.id),
      child: _BookReaderScreenBody(book: book),
    );
  }
}

class _BookReaderScreenBody extends StatefulWidget {
  final Book book;
  const _BookReaderScreenBody({Key? key, required this.book}) : super(key: key);

  @override
  State<_BookReaderScreenBody> createState() => _BookReaderScreenBodyState();
}

class _BookReaderScreenBodyState extends State<_BookReaderScreenBody> {
  final TransformationController _transformationController =
      TransformationController();
  double scale = 1.0;
  bool isBookmarked = false;
  late final EpubController _epubController = EpubController();
  final PdfViewerController _pdfController = PdfViewerController();
  PdfDocument? _pdfDocument;
  List<PdfOutline>? _pdfOutline;
  bool _isSearching = false;
  String _searchQuery = '';
  List<int> _searchResults = [];
  int _currentSearchIndex = 0;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onMatrixChanged);
  }

  void _onMatrixChanged() {
    final matrix = _transformationController.value;
    final newScale = matrix.getMaxScaleOnAxis().clamp(0.5, 4.0);
    if ((scale - newScale).abs() > 0.01) {
      setState(() {
        scale = newScale;
      });
    }
  }

  @override
  void dispose() {
    // _pdfController?.dispose(); // Not needed for pdfrx
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadPdfOutline() async {
    if (_pdfDocument == null) return;
    setState(() {
      _pdfOutline = _pdfDocument!.outline;
    });
  }

  void _showPdfTocDialog(BuildContext context) async {
    if (_pdfDocument == null) return;
    if (_pdfOutline == null) await _loadPdfOutline();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.contents),
        content: _pdfOutline == null || _pdfOutline!.isEmpty
            ? const Text('No table of contents available.')
            : SizedBox(
                width: 300,
                height: 400,
                child: ListView(
                  children: _buildOutlineList(_pdfOutline!),
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

  List<Widget> _buildOutlineList(List<PdfOutline> outlines, {int indent = 0}) {
    List<Widget> widgets = [];
    for (final item in outlines) {
      widgets.add(ListTile(
        contentPadding: EdgeInsets.only(left: 16.0 * indent),
        title: Text(item.title ?? 'Untitled'),
        onTap: () {
          Navigator.of(context).pop();
          if (item.pageNumber != null) {
            _pdfController.goToPage(item.pageNumber!);
          }
        },
      ));
      if (item.children != null && item.children!.isNotEmpty) {
        widgets.addAll(_buildOutlineList(item.children!, indent: indent + 1));
      }
    }
    return widgets;
  }

  void _showPdfSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController searchController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.search),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration:
                      const InputDecoration(hintText: 'Enter text to search'),
                  onSubmitted: (value) async {
                    setState(() => _isSearching = true);
                    final doc = _pdfDocument;
                    if (doc != null && value.isNotEmpty) {
                      List<int> results = [];
                      for (int i = 0; i < doc.pages.length; i++) {
                        final text = await doc.pages[i].text;
                        if (text != null &&
                            text.toLowerCase().contains(value.toLowerCase())) {
                          results.add(i + 1);
                        }
                      }
                      setState(() {
                        _searchQuery = value;
                        _searchResults = results;
                        _currentSearchIndex = 0;
                        _isSearching = false;
                      });
                      if (results.isNotEmpty) {
                        _pdfController.goToPage(results[0]);
                      }
                    }
                  },
                ),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  ),
                if (_searchResults.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            'Result: ${_currentSearchIndex + 1}/${_searchResults.length}'),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: _currentSearchIndex > 0
                                  ? () {
                                      setState(() {
                                        _currentSearchIndex--;
                                        _pdfController.goToPage(_searchResults[
                                            _currentSearchIndex]);
                                      });
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: _currentSearchIndex <
                                      _searchResults.length - 1
                                  ? () {
                                      setState(() {
                                        _currentSearchIndex++;
                                        _pdfController.goToPage(_searchResults[
                                            _currentSearchIndex]);
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (!_isSearching &&
                    _searchResults.isEmpty &&
                    _searchQuery.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('No results found.'),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
              ),
            ],
          ),
        );
      },
    );
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
    final readerState = context.watch<ReaderCubit>().state;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
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
            icon: const Icon(Icons.search),
            tooltip: l10n.search,
            onPressed: () {
              if (widget.book.format.toUpperCase() == 'PDF') {
                _showPdfSearchDialog(context);
              } else {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.search),
                    content: const Text('EPUB search is not yet implemented.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                            MaterialLocalizations.of(context).okButtonLabel),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: widget.book.format.toUpperCase() == 'PDF'
          ? FutureBuilder<String>(
              future: _getLocalPdfPath(widget.book.link),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Failed to load PDF: \\${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('No PDF file found.'));
                }
                final localPath = snapshot.data!;
                debugPrint('PDF localPath: $localPath');
                final file = File(localPath);
                if (!file.existsSync() && !localPath.startsWith('http')) {
                  return Center(
                      child: Text('PDF file does not exist at $localPath'));
                }
                return PdfViewer.file(
                  localPath,
                  controller: _pdfController,
                  params: PdfViewerParams(
                    enableTextSelection: true,
                    viewerOverlayBuilder: (context, size, handleLinkTap) => [
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onDoubleTap: () {
                          _pdfController.zoomUp(loop: true);
                        },
                        onTapUp: (details) {
                          handleLinkTap(details.localPosition);
                        },
                        child: IgnorePointer(
                          child:
                              SizedBox(width: size.width, height: size.height),
                        ),
                      ),
                      PdfViewerScrollThumb(
                        controller: _pdfController,
                        orientation: ScrollbarOrientation.right,
                        thumbSize: const Size(40, 25),
                        thumbBuilder:
                            (context, thumbSize, pageNumber, controller) =>
                                Container(
                          color: Colors.black.withOpacity(0.5),
                          child: Center(
                            child: Text(
                              pageNumber.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      PdfViewerScrollThumb(
                        controller: _pdfController,
                        orientation: ScrollbarOrientation.bottom,
                        thumbSize: const Size(80, 30),
                        thumbBuilder:
                            (context, thumbSize, pageNumber, controller) =>
                                Container(
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                    ],
                    onDocumentChanged: (doc) async {
                      _pdfDocument = doc;
                      await _loadPdfOutline();
                    },
                  ),
                );
              },
            )
          : EpubViewer(
              epubSource: EpubSource.fromFile(File(widget.book.link)),
              epubController: _epubController,
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
          throw Exception('Failed to download PDF: \\${response.statusCode}');
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
