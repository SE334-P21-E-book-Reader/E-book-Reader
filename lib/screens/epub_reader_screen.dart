import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../bloc/theme/theme_cubit.dart';
import '../models/book.dart';

class EPUBReaderScreen extends StatefulWidget {
  final Book book;
  const EPUBReaderScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<EPUBReaderScreen> createState() => _EPUBReaderScreenState();
}

class _EPUBReaderScreenState extends State<EPUBReaderScreen> {
  EpubController? _epubController;
  File? _localFile;
  bool _loading = true;
  String? _error;
  bool _disposed = false;
  final EpubFlow _currentFlow = EpubFlow.paginated;
  List<EpubChapter> _chapters = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  double _progress = 0.0;
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<EpubSearchResult> _searchResults = [];
  bool _searching = false;
  String _searchError = '';
  String? _lastHighlightedCfi;
  bool _showFontSizeSlider = false;
  double _fontSize = 16.0;
  String? _selectedCfi;
  bool _menuExpanded = false;
  EpubDisplaySettings? _epubDisplaySettings;
  EpubTheme _epubTheme = EpubTheme.light();

  @override
  void initState() {
    super.initState();
    _prepareEpub();
    _searchController.addListener(() async {
      setState(() {
        _searchResults.clear();
        _searchError = '';
      });
      if (_searchController.text.isEmpty && _lastHighlightedCfi != null) {
        await _epubController?.removeHighlight(cfi: _lastHighlightedCfi!);
        _lastHighlightedCfi = null;
      }
    });
    _epubDisplaySettings = EpubDisplaySettings(
      flow: _currentFlow,
      snap: false,
      spread: EpubSpread.auto,
      allowScriptedContent: true,
      theme: _epubTheme,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _prepareEpub() async {
    if (_disposed) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      File file;
      if (widget.book.link.startsWith('http')) {
        // Download to local
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = widget.book.link.split('/').last.split('?').first;
        final localPath = '${appDir.path}/$fileName';
        file = File(localPath);
        if (!await file.exists()) {
          final response = await http.get(Uri.parse(widget.book.link));
          if (response.statusCode == 200) {
            await file.writeAsBytes(response.bodyBytes);
          } else {
            throw Exception(
                'Failed to download EPUB: \\${response.statusCode}');
          }
        }
      } else {
        file = File(widget.book.link);
        if (!await file.exists()) {
          throw Exception('EPUB file not found: \\${widget.book.link}');
        }
      }
      if (_disposed) return;
      setState(() {
        _localFile = file;
        _epubController = EpubController();
        _loading = false;
      });
    } catch (e) {
      if (_disposed) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Helper to get chapter title for a given cfi
  String? _getChapterTitleForCfi(String cfi) {
    for (final chapter in _chapters) {
      if (chapter.href != null && cfi.contains(chapter.href!)) {
        return chapter.title;
      }
    }
    return null;
  }

  // Helper to highlight search word in excerpt
  Widget _highlightedExcerpt(String excerpt, String query) {
    if (query.isEmpty) return Text(excerpt);
    final matches =
        RegExp(RegExp.escape(query), caseSensitive: false).allMatches(excerpt);
    if (matches.isEmpty) return Text(excerpt);
    List<TextSpan> spans = [];
    int last = 0;
    for (final match in matches) {
      if (match.start > last) {
        spans.add(TextSpan(text: excerpt.substring(last, match.start)));
      }
      spans.add(TextSpan(
        text: excerpt.substring(match.start, match.end),
        style: TextStyle(
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));
      last = match.end;
    }
    if (last < excerpt.length) {
      spans.add(TextSpan(text: excerpt.substring(last)));
    }
    return RichText(
        text: TextSpan(style: TextStyle(color: Colors.black), children: spans));
  }

  List<ContextMenuItem> get _menuItems {
    List<ContextMenuItem> baseItems = [
      ContextMenuItem(id: 1, title: 'Copy'),
      ContextMenuItem(id: 2, title: 'Highlight'),
      ContextMenuItem(id: 3, title: 'Underline'),
    ];
    return [
      ...baseItems,
    ];
  }

  void _onContextMenuActionItemClicked(ContextMenuItem item) async {
    switch (item.id) {
      case 1: // Copy
        if (_selectedCfi != null) {
          await Clipboard.setData(ClipboardData(text: _selectedCfi!));
        }
        break;
      case 2: // Highlight
        if (_selectedCfi != null) {
          await _epubController?.addHighlight(
            cfi: _selectedCfi!,
            color: Colors.yellow,
            opacity: 0.5,
          );
        }
        break;
      case 3: // Underline
        if (_selectedCfi != null) {
          await _epubController?.addUnderline(cfi: _selectedCfi!);
        }
        break;
    }
    // Dismiss both context menu and text selection after any action
    setState(() {
      _selectedCfi = null;
    });
    ContextMenuController.removeAny();
  }

  ContextMenu get _customContextMenu => ContextMenu(
        menuItems: _menuItems,
        onContextMenuActionItemClicked: _onContextMenuActionItemClicked,
        settings: ContextMenuSettings(
          hideDefaultSystemContextMenuItems: true,
        ),
      );

  void _toggleTheme(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();
    final isDark = themeCubit.state.themeMode == ThemeMode.dark;
    final newTheme = isDark ? ThemeMode.light : ThemeMode.dark;
    themeCubit.setThemeMode(newTheme);
    setState(() {
      _epubTheme = isDark ? EpubTheme.light() : EpubTheme.dark();
      _epubDisplaySettings = EpubDisplaySettings(
        flow: _currentFlow,
        snap: false,
        spread: EpubSpread.auto,
        allowScriptedContent: true,
        theme: _epubTheme,
      );
    });
    _epubController?.updateTheme(theme: _epubTheme);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
        actions: [
          // Theme switch button
          Builder(
            builder: (context) {
              final themeState = context.watch<ThemeCubit>().state;
              final isDark = themeState.themeMode == ThemeMode.dark;
              return IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => RotationTransition(
                    turns: animation,
                    child: child,
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    key: ValueKey<bool>(isDark),
                  ),
                ),
                tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                onPressed: () => _toggleTheme(context),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            tooltip: 'Bookmark',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => SizedBox(
                  height: 200,
                  child: Center(child: Text('Bookmark bottom sheet (empty)')),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.format_size),
            tooltip: 'Font Size',
            onPressed: () {
              setState(() {
                _showFontSizeSlider = !_showFontSizeSlider;
              });
            },
            onLongPress: () {
              setState(() {
                _fontSize = 16.0;
              });
              _epubController?.setFontSize(fontSize: 16.0);
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Table of Contents',
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Table of Contents',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: _chapters.isEmpty
                    ? const Center(child: Text('No chapters'))
                    : ListView.builder(
                        itemCount: _chapters.length,
                        itemBuilder: (context, idx) {
                          final chapter = _chapters[idx];
                          return ListTile(
                            title: Text(chapter.title ?? 'Untitled'),
                            onTap: () {
                              Navigator.of(context).maybePop();
                              _epubController?.display(cfi: chapter.href);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Search',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (query) async {
                          if (query.trim().isEmpty) return;
                          setState(() {
                            _searching = true;
                            _searchResults.clear();
                            _searchError = '';
                          });
                          try {
                            final results = await _epubController!
                                .search(query: query.trim());
                            setState(() {
                              _searchResults = results;
                              _searching = false;
                              _searchError =
                                  results.isEmpty ? 'No results found.' : '';
                            });
                          } catch (e) {
                            setState(() {
                              _searching = false;
                              _searchError = 'Search failed: $e';
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          suffixIcon: _searchController.text.isNotEmpty ||
                                  _searchResults.isNotEmpty ||
                                  _searchError.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchResults.clear();
                                      _searchError = '';
                                    });
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                    if (_searching)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
              if (_searchResults.isNotEmpty)
                Expanded(
                  child: ListView.separated(
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, idx) => Divider(),
                    itemBuilder: (context, idx) {
                      final result = _searchResults[idx];
                      final chapterTitle =
                          _getChapterTitleForCfi(result.cfi ?? '');
                      return ListTile(
                        title: _highlightedExcerpt(
                            result.excerpt ?? '', _searchController.text),
                        onTap: () async {
                          Navigator.of(context).maybePop();
                          if (_lastHighlightedCfi != null) {
                            await _epubController?.removeHighlight(
                                cfi: _lastHighlightedCfi!);
                          }
                          await _epubController?.display(cfi: result.cfi);
                          if (result.cfi != null && result.cfi!.isNotEmpty) {
                            await _epubController?.addHighlight(
                              cfi: result.cfi!,
                              color: Colors.yellow,
                              opacity: 0.5,
                            );
                            _lastHighlightedCfi = result.cfi;
                          }
                        },
                      );
                    },
                  ),
                ),
              if (_searchError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child:
                      Text(_searchError, style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          _loading
              ? const SizedBox.shrink()
              : _error != null
                  ? Center(child: Text(_error!))
                  : _localFile == null || _epubController == null
                      ? const Center(child: Text('Failed to load EPUB.'))
                      : GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            if (_showFontSizeSlider) {
                              setState(() {
                                _showFontSizeSlider = false;
                              });
                            }
                          },
                          child: Stack(
                            children: [
                              // Main content (EpubViewer with font size slider overlay)
                              Column(
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        SafeArea(
                                          child: Builder(
                                            builder: (context) {
                                              final themeState = context
                                                  .watch<ThemeCubit>()
                                                  .state;
                                              final isDark =
                                                  themeState.themeMode ==
                                                      ThemeMode.dark;
                                              return EpubViewer(
                                                key: ValueKey(_currentFlow),
                                                epubSource: EpubSource.fromFile(
                                                    _localFile!),
                                                epubController:
                                                    _epubController!,
                                                displaySettings:
                                                    _epubDisplaySettings!,
                                                selectionContextMenu:
                                                    _customContextMenu,
                                                onChaptersLoaded: (chapters) {
                                                  setState(() {
                                                    _chapters = chapters;
                                                  });
                                                },
                                                onEpubLoaded: () async {
                                                  final chapters =
                                                      await _epubController
                                                          ?.getChapters();
                                                  print(
                                                      chapters); // Inspect for cfi or other properties
                                                },
                                                onRelocated: (value) async {
                                                  // Update progress
                                                  final progress =
                                                      await _epubController
                                                          ?.getCurrentLocation();
                                                  if (progress != null &&
                                                      mounted) {
                                                    setState(() {
                                                      _progress =
                                                          progress.progress ??
                                                              0.0;
                                                    });
                                                  }
                                                },
                                                onTextSelected:
                                                    (epubTextSelection) {
                                                  setState(() {
                                                    _selectedCfi =
                                                        epubTextSelection
                                                            .selectionCfi;
                                                  });
                                                },
                                                onAnnotationClicked:
                                                    (cfi) async {
                                                  await _epubController
                                                      ?.removeHighlight(
                                                          cfi: cfi);
                                                  await _epubController
                                                      ?.removeUnderline(
                                                          cfi: cfi);
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                        if (_showFontSizeSlider)
                                          Positioned(
                                            top: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              child: Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.zoom_out),
                                                    tooltip: 'Zoom -',
                                                    onPressed: () {
                                                      setState(() {
                                                        _showFontSizeSlider =
                                                            true;
                                                        _fontSize =
                                                            (_fontSize - 1)
                                                                .clamp(10, 40);
                                                      });
                                                      _epubController
                                                          ?.setFontSize(
                                                              fontSize:
                                                                  _fontSize);
                                                    },
                                                  ),
                                                  Expanded(
                                                    child: Slider(
                                                      min: 10,
                                                      max: 40,
                                                      divisions: 30,
                                                      value: _fontSize,
                                                      label: _fontSize
                                                          .toStringAsFixed(0),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _showFontSizeSlider =
                                                              true;
                                                          _fontSize = value;
                                                        });
                                                        _epubController
                                                            ?.setFontSize(
                                                                fontSize:
                                                                    _fontSize);
                                                      },
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.zoom_in),
                                                    tooltip: 'Zoom +',
                                                    onPressed: () {
                                                      setState(() {
                                                        _showFontSizeSlider =
                                                            true;
                                                        _fontSize =
                                                            (_fontSize + 1)
                                                                .clamp(10, 40);
                                                      });
                                                      _epubController
                                                          ?.setFontSize(
                                                              fontSize:
                                                                  _fontSize);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // Bottom navigation bar (page navigator)
                              if (MediaQuery.of(context).viewInsets.bottom == 0)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Material(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 8.0,
                                        right: 8.0,
                                        top: 4.0,
                                        bottom: 12.0 +
                                            MediaQuery.of(context)
                                                .viewPadding
                                                .bottom,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.first_page),
                                            tooltip: 'First Page',
                                            onPressed: _epubController == null
                                                ? null
                                                : () {
                                                    _epubController!
                                                        .moveToFistPage();
                                                  },
                                          ),
                                          IconButton(
                                            icon:
                                                const Icon(Icons.chevron_left),
                                            tooltip: 'Previous Page',
                                            onPressed: _epubController == null
                                                ? null
                                                : () {
                                                    _epubController!.prev();
                                                  },
                                          ),
                                          Text(
                                              '${(_progress * 100).toStringAsFixed(2)}%'),
                                          IconButton(
                                            icon:
                                                const Icon(Icons.chevron_right),
                                            tooltip: 'Next Page',
                                            onPressed: _epubController == null
                                                ? null
                                                : () {
                                                    _epubController!.next();
                                                  },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.last_page),
                                            tooltip: 'Last Page',
                                            onPressed: _epubController == null
                                                ? null
                                                : () {
                                                    _epubController!
                                                        .moveToLastPage();
                                                  },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
