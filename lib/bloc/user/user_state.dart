import 'package:equatable/equatable.dart';

class UserState extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isLoading;
  final String? error;
  final bool isLoggedOut;

  const UserState({
    this.uid = '',
    this.name = '',
    this.email = '',
    this.avatarUrl,
    this.isLoading = false,
    this.error,
    this.isLoggedOut = false,
  });

  UserState copyWith({
    String? uid,
    String? name,
    String? email,
    String? avatarUrl,
    bool? isLoading,
    String? error,
    bool? isLoggedOut,
  }) {
    return UserState(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedOut: isLoggedOut ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [uid, name, email, avatarUrl, isLoading, error, isLoggedOut];
}

class UserLoggedOut extends UserState {
  const UserLoggedOut() : super(isLoggedOut: true);
}
