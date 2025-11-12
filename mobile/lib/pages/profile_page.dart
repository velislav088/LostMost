import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/auth/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // get auth service
  final authService = AuthService();

  // confirm logout
  void confirmLogout() async {
    // get user choice
    final logoutDialog = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            // cancel
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            // confirm
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (logoutDialog == true) {
      logout();
    }
  }

  // logout
  void logout() async {
    await authService.signOut();
    if (!mounted) return; // guard the use with a 'mounted' check
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    // get user email
    final currentEmail = authService.getCurrentUserEmail();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          // logout button
          IconButton(onPressed: confirmLogout, icon: Icon(Icons.logout)),
        ],
      ),

      body: Center(child: Text(currentEmail.toString())),
    );
  }
}
