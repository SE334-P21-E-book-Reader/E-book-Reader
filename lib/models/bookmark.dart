import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class Bookmark {
  final String bookmarkId;
  final String bookId;
  final String bookTitle;
  final String location; // page number for PDF or CFI for EPUB

  Bookmark({
    String? bookmarkId,
    required this.bookId,
    required this.bookTitle,
    required this.location,
  }) : bookmarkId = bookmarkId ?? const Uuid().v4();

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      bookmarkId: map['bookmarkId'] as String?,
      bookId: map['bookId'] as String,
      bookTitle: map['bookTitle'] as String,
      location: map['location'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookmarkId': bookmarkId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'location': location,
    };
  }

  factory Bookmark.fromFirestore(Map<String, dynamic> map, String docId) {
    return Bookmark(
      bookmarkId: docId,
      bookId: map['bookId'] as String,
      bookTitle: map['bookTitle'] as String,
      location: map['location'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookId': bookId,
      'bookTitle': bookTitle,
      'location': location,
    };
  }

  static const String _prefsKey = 'bookmarks';

  static Future<List<Bookmark>> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => Bookmark.fromMap(e)).toList();
  }

  static Future<void> saveBookmarks(List<Bookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(bookmarks.map((b) => b.toMap()).toList());
    await prefs.setString(_prefsKey, jsonString);
  }

  static Future<List<Bookmark>> loadBookmarksFromFirestore(
      String bookId, String userId) async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('books')
        .doc(bookId)
        .collection('bookmarks')
        .where('bookId', isEqualTo: bookId)
        .get();
    return snapshot.docs
        .map((doc) => Bookmark.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  static Future<void> saveBookmarkToFirestore(
      Bookmark bookmark, String userId) async {
    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection('books')
        .doc(bookmark.bookId)
        .collection('bookmarks')
        .doc(bookmark.bookmarkId)
        .set(bookmark.toFirestore());
  }

  static Future<void> deleteBookmarkFromFirestore(
      Bookmark bookmark, String userId) async {
    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection('books')
        .doc(bookmark.bookId)
        .collection('bookmarks')
        .doc(bookmark.bookmarkId)
        .delete();
  }

  static Future<List<Bookmark>> syncBookmarks(
      String bookId, String userId) async {
    // Try cache first
    final local = await loadBookmarks();
    final filtered = local.where((b) => b.bookId == bookId).toList();
    if (filtered.isNotEmpty) return filtered;
    // Fallback to Firestore
    final remote = await loadBookmarksFromFirestore(bookId, userId);
    if (remote.isNotEmpty) {
      final all = [...local, ...remote];
      await saveBookmarks(all);
    }
    return remote;
  }
}
