import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:project_micro_journal/authentication/pages/signup_page.dart';
import 'package:project_micro_journal/authentication/services/authentication_token_storage_service.dart';
import 'package:project_micro_journal/firebase_options.dart';
import 'package:project_micro_journal/followers/page/followers_page.dart';
import 'package:project_micro_journal/home/pages/home_page.dart';
import 'package:project_micro_journal/profile/pages/profile_page.dart';
import 'package:project_micro_journal/utils/app_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProjectMicroJournalApp());
}

class ProjectMicroJournalApp extends StatelessWidget {
  ProjectMicroJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Project Micro Journal',
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
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthenticationTokenStorageService().getAccessToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          return const MainAppTabs();
        } else {
          return const SignupPage();
        }
      },
    );
  }
}

class MainAppTabs extends StatefulWidget {
  const MainAppTabs({super.key});

  @override
  State<MainAppTabs> createState() => _MainAppTabsState();
}

class _MainAppTabsState extends State<MainAppTabs> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      HomePage(key: _homePageKey),
      const FollowersPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.of(context).viewPadding;

    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _tabs),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: viewPadding.bottom),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outlined),
              selectedIcon: Icon(Icons.people),
              label: 'Followers',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outlined),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton:
          _currentIndex == 0
              ? GestureDetector(
                onLongPress: () {
                  _homePageKey.currentState?.microJournalHabitNotification();
                },
                child: FloatingActionButton.extended(
                  onPressed: () {
                    _homePageKey.currentState?.createNewPost();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Post'),
                ),
              )
              : null,
    );
  }
}
