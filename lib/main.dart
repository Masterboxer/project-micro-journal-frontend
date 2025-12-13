import 'package:flutter/material.dart';
import 'package:project_micro_journal/authentication/pages/signup_page.dart';
import 'package:project_micro_journal/authentication/services/authentication_token_storage_service.dart';
import 'package:project_micro_journal/home/pages/home_page.dart';

void main() {
  runApp(ProjectMicroJournalApp());
}

class ProjectMicroJournalApp extends StatelessWidget {
  ProjectMicroJournalApp({super.key});
  final authenticationTokenStorageService = AuthenticationTokenStorageService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project MicroJournal',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: FutureBuilder<String?>(
        future: authenticationTokenStorageService.getAccessToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            return const HomePage();
          } else {
            return const SignupPage();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
