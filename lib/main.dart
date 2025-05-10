import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'screens/settings_screen.dart';
import 'widgets/navigation/bottom_nav.dart';
import 'cubit/theme/theme_cubit.dart';
import 'cubit/language/language_cubit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/library_screen.dart';

void main() async {
  // Đảm bảo Flutter được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => LanguageCubit()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<LanguageCubit, LanguageState>(
          builder: (context, languageState) {
            return MaterialApp(
              title: 'E-book Reader',
              theme: ThemeData(
                colorScheme: const ColorScheme(
                  brightness: Brightness.light,
                  primary: Colors.black,
                  onPrimary: Colors.white,
                  secondary: Colors.black87,
                  onSecondary: Colors.white,
                  error: Colors.red,
                  onError: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
                useMaterial3: true,
                textTheme: GoogleFonts.croissantOneTextTheme(
                  Typography.englishLike2021.apply(
                    fontSizeFactor: context.read<ThemeCubit>().fontSizeScale,
                    bodyColor: Colors.black,
                    displayColor: Colors.black,
                  ),
                ),
              ),
              darkTheme: ThemeData(
                colorScheme: const ColorScheme(
                  brightness: Brightness.dark,
                  primary: Colors.white,
                  onPrimary: Colors.black,
                  secondary: Colors.white70,
                  onSecondary: Colors.black,
                  error: Colors.red,
                  onError: Colors.black,
                  surface: Colors.black,
                  onSurface: Colors.white,
                ),
                useMaterial3: true,
                textTheme: GoogleFonts.croissantOneTextTheme(
                  Typography.englishLike2021.apply(
                    fontSizeFactor: context.read<ThemeCubit>().fontSizeScale,
                    bodyColor: Colors.white,
                    displayColor: Colors.white,
                  ),
                ),
              ),
              themeMode: themeState.themeMode,
              locale: languageState.locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'), // English
                Locale('vi'), // Vietnamese
              ],
              home: const MainScreen(),
            );
          },
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const LibraryScreen(),
    const LibraryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNav(
        activeItem: _getActiveItem(_selectedIndex),
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  String _getActiveItem(int index) {
    switch (index) {
      case 0:
        return 'home';
      case 1:
        return 'library';
      case 2:
        return 'settings';
      default:
        return 'home';
    }
  }
}
