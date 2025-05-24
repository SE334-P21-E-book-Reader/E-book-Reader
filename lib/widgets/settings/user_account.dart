import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../bloc/user/user_cubit.dart';
import '../../bloc/user/user_state.dart';

class UserAccount extends StatefulWidget {
  const UserAccount({super.key});

  @override
  State<UserAccount> createState() => _UserAccountState();
}

class _UserAccountState extends State<UserAccount> {
  final GlobalKey _avatarMenuKey = GlobalKey();

  void _showEditNameSheet(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Account Info',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await context.read<UserCubit>().updateName(controller.text);
                    await context.read<UserCubit>().fetchUser();
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPasswordResetInfo(BuildContext context) async {
    await context.read<UserCubit>().sendPasswordReset();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Info'),
        content: const Text(
            'A password reset link will be sent to your email. Please check your inbox.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAvatarDetail(BuildContext context, String? avatarUrl) {
    if (avatarUrl == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(avatarUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatarFromCamera(BuildContext context) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) {
      final file = File(picked.path);
      await context.read<UserCubit>().uploadAvatar(file);
      await context.read<UserCubit>().fetchUser();
    }
  }

  Future<void> _pickAvatarFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final file = File(picked.path);
      await context.read<UserCubit>().uploadAvatar(file);
      await context.read<UserCubit>().fetchUser();
    }
  }

  void _showAvatarMenu(BuildContext context) async {
    final RenderBox button =
        _avatarMenuKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset position =
        button.localToGlobal(Offset.zero, ancestor: overlay);
    final Size size = button.size;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        position.dx + size.width,
        position.dy,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'camera',
          child: ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Take a photo'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'gallery',
          child: ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Choose from gallery'),
          ),
        ),
      ],
    );
    if (result == 'camera') {
      await _pickAvatarFromCamera(context);
    } else if (result == 'gallery') {
      await _pickAvatarFromGallery(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userCubit = context.read<UserCubit>();
    String userId = userCubit.state.uid;
    if (userId.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userId = user.uid;
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: \\${snapshot.error}'));
        }
        final data = snapshot.data?.data();
        final name = data?['name'] ?? userCubit.state.name;
        final avatarUrl = data?['avatarUrl'] ?? userCubit.state.avatarUrl;
        final email = data?['email'] ?? userCubit.state.email;
        return BlocBuilder<UserCubit, UserState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(child: Text('Error: \\${state.error}'));
            }
            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          onTap: () => _showAvatarDetail(context, avatarUrl),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null
                                ? Icon(Icons.person,
                                    size: 48, color: theme.colorScheme.primary)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: theme.colorScheme.surface,
                            shape: const CircleBorder(),
                            child: InkWell(
                              key: _avatarMenuKey,
                              customBorder: const CircleBorder(),
                              onTap: () => _showAvatarMenu(context),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(Icons.camera_alt_outlined,
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.grey[800],
                                    size: 20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(name,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 70),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: theme.brightness == Brightness.dark
                          ? const BorderSide(color: Colors.white)
                          : BorderSide.none,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 4),
                      child: Row(
                        children: [
                          // Icon(Icons.email, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Center(
                              child: Text(
                                email,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: theme.brightness == Brightness.dark
                                ? const BorderSide(color: Colors.white)
                                : BorderSide.none,
                          ),
                          child: ListTile(
                            leading: Icon(Icons.edit,
                                color: theme.colorScheme.primary),
                            title: const Text("Change username"),
                            onTap: () => _showEditNameSheet(context, name),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: theme.brightness == Brightness.dark
                                ? const BorderSide(color: Colors.white)
                                : BorderSide.none,
                          ),
                          child: ListTile(
                            leading: Icon(Icons.lock_reset,
                                color: theme.colorScheme.primary),
                            title: const Text("Reset password"),
                            onTap: () => _showPasswordResetInfo(context),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: theme.brightness == Brightness.dark
                                ? const BorderSide(color: Colors.white)
                                : BorderSide.none,
                          ),
                          child: ListTile(
                            leading: Icon(Icons.logout,
                                color: theme.colorScheme.error),
                            title: const Text('Logout'),
                            onTap: () {
                              context.read<UserCubit>().logout();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
