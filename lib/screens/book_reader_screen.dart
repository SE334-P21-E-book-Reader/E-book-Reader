import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/library/book_grid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/theme/theme_cubit.dart';

class BookReaderScreen extends StatefulWidget {
  final Book book;
  const BookReaderScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  double? fontSize;
  double scale = 1.0;
  bool isBookmarked = false;
  bool showSettings = false;
  bool showControls = true;
  Timer? _hideTimer;
  final bool _isMenuOpen = false;
  bool _isSliderActive = false;
  bool useZoom = true; // default to Non-OCR (zoom mode)
  bool _isDocMenuOpen = false;
  OverlayEntry? _docMenuOverlay;
  final GlobalKey _docIconKey = GlobalKey();
  int _currentPage = 1;
  final int _totalPages = 189; // Example, replace with actual book data
  Timer? _zoomTimer;
  bool _isZooming = false;

  @override
  void initState() {
    super.initState();
    // Get initial font size from ThemeCubit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeCubit = context.read<ThemeCubit>();
      setState(() {
        fontSize = 16 * themeCubit.fontSizeScale;
      });
    });
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (showControls && !_isMenuOpen && !_isSliderActive && !_isDocMenuOpen) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        setState(() {
          showControls = false;
        });
      });
    }
  }

  void _toggleBookmark() {
    setState(() {
      isBookmarked = !isBookmarked;
    });
  }

  void _handleContentTap() {
    setState(() {
      showControls = !showControls;
      if (showSettings) showSettings = false;
    });
    if (showControls) _startHideTimer();
  }

  void _handleFontSizeChange(double newSize) {
    setState(() {
      fontSize = newSize;
    });
    // Optionally update global font size scale
    // final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    // themeProvider.setFontSize((newSize - 12) / 6); // Map 12-24 to 0-2
  }

  void _onBarInteraction() {
    // Show controls and cancel hide timer, but do not start a new timer
    setState(() {
      showControls = true;
    });
    _hideTimer?.cancel();
  }

  void _navigateToLibrary() {
    Navigator.of(context).pop();
  }

  void _showDocMenu() {
    if (_docMenuOverlay != null) return;
    final RenderBox iconBox =
        _docIconKey.currentContext!.findRenderObject() as RenderBox;
    final Offset iconPosition = iconBox.localToGlobal(Offset.zero);
    final Size iconSize = iconBox.size;
    _docMenuOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss area
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() {
                  _isDocMenuOpen = false;
                  showControls = false;
                });
                _docMenuOverlay?.remove();
                _docMenuOverlay = null;
              },
            ),
          ),
          Positioned(
            left: iconPosition.dx - 120, // move menu to the left of the icon
            top: iconPosition.dy + iconSize.height,
            child: Material(
              color: Colors.transparent,
              child: Container(
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(blurRadius: 8, color: Colors.black26)
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMenuItem(context, 'Non-OCR', Icons.image, useZoom,
                        () {
                      setState(() {
                        useZoom = true;
                        _isDocMenuOpen = false;
                      });
                      _docMenuOverlay?.remove();
                      _docMenuOverlay = null;
                      _startHideTimer();
                    }),
                    _buildMenuItem(context, 'OCR', Icons.text_fields, !useZoom,
                        () {
                      setState(() {
                        useZoom = false;
                        _isDocMenuOpen = false;
                      });
                      _docMenuOverlay?.remove();
                      _docMenuOverlay = null;
                      _startHideTimer();
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_docMenuOverlay!);
    setState(() {
      _isDocMenuOpen = true;
    });
    _hideTimer?.cancel();
  }

  Widget _buildMenuItem(BuildContext context, String label, IconData icon,
      bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: selected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon,
                color: selected ? Theme.of(context).colorScheme.primary : null),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  void _goToPreviousPage() {
    setState(() {
      if (_currentPage > 1) _currentPage--;
    });
  }

  void _goToNextPage() {
    setState(() {
      if (_currentPage < _totalPages) _currentPage++;
    });
  }

  void _goToFirstPage() {
    setState(() {
      _currentPage = 1;
      showControls = true;
    });
    _hideTimer?.cancel();
  }

  void _goToLastPage() {
    setState(() {
      _currentPage = _totalPages;
      showControls = true;
    });
    _hideTimer?.cancel();
  }

  void _handleZoomChange(double newScale) {
    setState(() {
      scale = newScale.clamp(0.5, 4.0);
    });
  }

  void _startZooming(bool zoomIn) {
    _zoomTimer?.cancel();
    _isZooming = true;
    showControls = true;
    _hideTimer?.cancel();
    _zoomTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      setState(() {
        showControls = true;
        if (zoomIn) {
          scale = (scale + 0.1).clamp(0.5, 4.0);
        } else {
          scale = (scale - 0.1).clamp(0.5, 4.0);
        }
      });
    });
  }

  void _stopZooming() {
    _zoomTimer?.cancel();
    _isZooming = false;
    setState(() {
      showControls = true;
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _zoomTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final fontSz = fontSize ?? 16 * context.watch<ThemeCubit>().fontSizeScale;
    const double barHeight = 64;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Main Content Area (tappable except bars)
          Positioned.fill(
            top: showControls ? barHeight : 0,
            bottom: showControls ? barHeight : 0,
            child: GestureDetector(
              onTap: _handleContentTap,
              behavior: HitTestBehavior.opaque,
              child: useZoom
                  ? InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 2.5,
                      scaleEnabled: true,
                      panEnabled: true,
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.center,
                        child: _ReaderContent(
                            fontSize: fontSz, l10n: l10n, book: widget.book),
                      ),
                    )
                  : Align(
                      alignment: Alignment.center,
                      child: _ReaderContent(
                          fontSize: fontSz, l10n: l10n, book: widget.book),
                    ),
            ),
          ),
          // Top App Bar
          if (showControls)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onBarInteraction,
                child: AnimatedOpacity(
                  opacity: showControls ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.95),
                      border: Border(
                        bottom: BorderSide(
                            color:
                                colorScheme.secondary.withValues(alpha: 0.2)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 32),
                              color: colorScheme.primary,
                              onPressed: () {
                                _navigateToLibrary();
                              },
                              tooltip: l10n.library,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.book.title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface),
                                ),
                                Text(
                                  widget.book.author,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: colorScheme.secondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isBookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: isBookmarked
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                              onPressed: _toggleBookmark,
                              tooltip: l10n.bookmark,
                            ),
                            IconButton(
                              key: _docIconKey,
                              icon: const Icon(Icons.description),
                              color: colorScheme.onSurface,
                              onPressed: _showDocMenu,
                              tooltip: 'Document Options',
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Bottom Controls
          if (showControls)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onBarInteraction,
                child: AnimatedOpacity(
                  opacity: showControls ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.95),
                      border: Border(
                        top: BorderSide(
                            color:
                                colorScheme.secondary.withValues(alpha: 0.2)),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Page navigation row
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.first_page),
                              onPressed: _goToFirstPage,
                              tooltip: 'First Page',
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () {
                                _goToPreviousPage();
                                setState(() {
                                  showControls = true;
                                });
                                _hideTimer?.cancel();
                              },
                              tooltip: l10n.library, // or 'Previous Page'
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                    l10n.pageIndicator(
                                        _currentPage, _totalPages),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.secondary)),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                _goToNextPage();
                                setState(() {
                                  showControls = true;
                                });
                                _hideTimer?.cancel();
                              },
                              tooltip: l10n.library, // or 'Next Page'
                            ),
                            IconButton(
                              icon: const Icon(Icons.last_page),
                              onPressed: _goToLastPage,
                              tooltip: 'Last Page',
                            ),
                          ],
                        ),
                        // Zoom/font size row
                        Row(
                          children: [
                            GestureDetector(
                              onTapDown:
                                  useZoom ? (_) => _startZooming(false) : null,
                              onTapUp: useZoom ? (_) => _stopZooming() : null,
                              onTapCancel: useZoom ? _stopZooming : null,
                              child: IconButton(
                                icon: useZoom
                                    ? const Icon(Icons.zoom_out)
                                    : const Text('A',
                                        style: TextStyle(fontSize: 14)),
                                onPressed: () {
                                  if (useZoom) {
                                    setState(() {
                                      scale = (scale - 0.1).clamp(0.5, 4.0);
                                    });
                                  } else {
                                    _handleFontSizeChange(
                                        fontSz > 12 ? fontSz - 1 : 12);
                                  }
                                },
                                tooltip: useZoom ? 'Zoom out' : l10n.small,
                              ),
                            ),
                            Expanded(
                              child: Listener(
                                onPointerDown: (_) {
                                  if (_isZooming) _stopZooming();
                                },
                                child: Slider(
                                  value:
                                      useZoom ? scale.clamp(0.5, 4.0) : fontSz,
                                  min: useZoom ? 0.5 : 12,
                                  max: useZoom ? 4.0 : 24,
                                  divisions: useZoom ? 35 : 12,
                                  label: useZoom
                                      ? '${(scale * 100).toStringAsFixed(0)}%'
                                      : fontSz.toStringAsFixed(0),
                                  onChangeStart: (_) {
                                    setState(() {
                                      _isSliderActive = true;
                                    });
                                    _hideTimer?.cancel();
                                    if (_isZooming) _stopZooming();
                                  },
                                  onChanged: (value) {
                                    if (useZoom) {
                                      _handleZoomChange(value);
                                    } else {
                                      _handleFontSizeChange(value);
                                    }
                                  },
                                  onChangeEnd: (_) {
                                    setState(() {
                                      _isSliderActive = false;
                                    });
                                    if (!_isZooming) {
                                      _startHideTimer();
                                    }
                                  },
                                  activeColor: colorScheme.primary,
                                  inactiveColor: colorScheme.secondary,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTapDown:
                                  useZoom ? (_) => _startZooming(true) : null,
                              onTapUp: useZoom ? (_) => _stopZooming() : null,
                              onTapCancel: useZoom ? _stopZooming : null,
                              child: IconButton(
                                icon: useZoom
                                    ? const Icon(Icons.zoom_in)
                                    : const Text('A',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  if (useZoom) {
                                    setState(() {
                                      scale = (scale + 0.1).clamp(0.5, 4.0);
                                    });
                                  } else {
                                    _handleFontSizeChange(
                                        fontSz < 24 ? fontSz + 1 : 24);
                                  }
                                },
                                tooltip: useZoom ? 'Zoom in' : l10n.large,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                                '${((_currentPage / _totalPages) * 100).toStringAsFixed(0)}%',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: colorScheme.secondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Settings Panel
          if (showSettings)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    showSettings = false;
                  });
                },
                child: Container(
                  color: colorScheme.surface.withValues(alpha: 0.95),
                  child: Center(
                    child: _ReaderSettings(
                      fontSize: fontSz,
                      setFontSize: _handleFontSizeChange,
                      onClose: () {
                        setState(() {
                          showSettings = false;
                        });
                      },
                      l10n: l10n,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Placeholder for ReaderContent
class _ReaderContent extends StatelessWidget {
  final double fontSize;
  final AppLocalizations l10n;
  final Book book;
  const _ReaderContent(
      {required this.fontSize, required this.l10n, required this.book});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '${l10n.noBooksFound}\n${book.title}', // TODO: Replace with book content
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontSize: fontSize),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Placeholder for ReaderSettings
class _ReaderSettings extends StatelessWidget {
  final double fontSize;
  final ValueChanged<double> setFontSize;
  final VoidCallback onClose;
  final AppLocalizations l10n;
  const _ReaderSettings(
      {required this.fontSize,
      required this.setFontSize,
      required this.onClose,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.settings, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text(l10n.fontSize, style: Theme.of(context).textTheme.bodyMedium),
            Slider(
              value: fontSize,
              min: 12,
              max: 24,
              divisions: 12,
              onChanged: setFontSize,
              activeColor: colorScheme.primary,
              inactiveColor: colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onClose,
              child: Text(l10n.settingsDescription),
            ),
          ],
        ),
      ),
    );
  }
}
