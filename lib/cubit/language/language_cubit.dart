import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'language_state.dart';

class LanguageCubit extends Cubit<LanguageState> {
  static const String _languageKey = 'language_code';
  SharedPreferences? _prefs;

  LanguageCubit() : super(const LanguageState()) {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    if (_prefs == null) return;
    final languageCode = _prefs!.getString(_languageKey) ?? 'en';
    emit(state.copyWith(locale: Locale(languageCode)));
  }

  Future<void> setLanguage(String languageCode) async {
    if (_prefs == null) return;
    await _prefs!.setString(_languageKey, languageCode);
    emit(state.copyWith(locale: Locale(languageCode)));
  }
}
