import 'package:flutter/material.dart';
import '../../../core/network/dio_client.dart';
import 'phone_page.dart';
import '../../shell/app_shell.dart';


class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<bool> _hasToken() async {
    final token = await DioClient.tokenStorage.readToken();
    return token != null && token.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasToken(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final loggedIn = snap.data == true;
return loggedIn ? const AppShell() : const PhonePage();
      },

    );
  }
}





















