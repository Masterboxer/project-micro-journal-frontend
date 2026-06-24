import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:project_micro_journal/authentication/pages/login_page.dart';
import 'package:project_micro_journal/authentication/services/authentication_token_storage_service.dart';
import 'package:project_micro_journal/environment/development.dart';
import 'package:project_micro_journal/utils/notifications_permissions_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String? _currentUserDisplayName;
  final AuthenticationTokenStorageService _authStorage =
      AuthenticationTokenStorageService();

  final List<OnboardingScreen> _screens = [
    OnboardingScreen(
      icon: Icons.edit_note_rounded,
      iconColor: Colors.blue,
      title: "Welcome to\nReflecto",
      body:
          "A calm space to reflect with the people who matter most. One post a day, no noise, no pressure.",
      caption: "This isn't a place to perform. It's a place to show up.",
      primaryCTA: "Continue",
    ),
    OnboardingScreen(
      icon: Icons.favorite_rounded,
      iconColor: Colors.blue,
      title: "One post,\nonce a day",
      body:
          "No pressure to post more. No scrolling endlessly. Just one small reflection when you're ready.",
      caption: "500 characters",
      primaryCTA: "Got it",
    ),
    OnboardingScreen(
      icon: Icons.local_fire_department_rounded,
      iconColor: Colors.orange,
      title: "Gentle streaks,\nnot strict rules",
      body:
          "We count the days you show up. Miss the evening? Post the next morning, your streak is safe.",
      caption: "Consistency matters, but life happens",
      primaryCTA: "That's nice",
    ),
    OnboardingScreen(
      icon: Icons.people_rounded,
      iconColor: Colors.blue,
      title: "10 friends,\nand that's enough",
      body:
          "This isn't a place to grow an audience. You can connect with up to 10 people. That's it.",
      caption: "Quality over quantity, always",
      primaryCTA: "Makes sense",
    ),
    OnboardingScreen(
      icon: Icons.notifications_rounded,
      iconColor: Colors.blue,
      title: "Notifications that\nactually help",
      body:
          "We'll remind you if you didn't post for the day and when your friends share and interact. Nothing spammy, just helpful.",
      caption: "You can always adjust these later",
      primaryCTA: "Sounds good",
      secondaryCTA: "Maybe later",
      isNotificationScreen: true,
    ),
    OnboardingScreen(
      icon: Icons.person_add_alt_1_rounded,
      iconColor: Colors.blue,
      title: "Invite friends\nand family",
      body:
          "Reflecto is better with people you know. Invite friends and family so you can keep up with each other's daily moments, no matter how busy life gets.",
      caption: null,
      primaryCTA: "Invite friends",
      secondaryCTA: "Maybe later",
      isInviteScreen: true,
    ),
    OnboardingScreen(
      icon: Icons.edit_rounded,
      iconColor: Colors.blue,
      title: "Ready to start?",
      body:
          "Your first post is waiting. No one's watching yet. Just write what's on your mind.",
      caption: null,
      primaryCTA: "Start Micro Journaling",
    ),
  ];

  int get _notificationScreenIndex =>
      _screens.indexWhere((s) => s.isNotificationScreen);

  int get _inviteScreenIndex => _screens.indexWhere((s) => s.isInviteScreen);

  @override
  void initState() {
    super.initState();
    _loadCurrentUserDisplayName();
  }

  Future<void> _loadCurrentUserDisplayName() async {
    try {
      final String? userId = await _authStorage.getUserId();
      if (userId == null) return;
      final String? token = await _authStorage.getAccessToken();
      final response = await http.get(
        Uri.parse('${Environment.baseUrl}users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() {
          _currentUserDisplayName =
              data['display_name'] as String? ??
              data['username'] as String? ??
              null;
        });
      }
    } catch (_) {
      // Non-critical; invite copy falls back to generic phrasing.
    }
  }

  String get _inviteMessage {
    final name = _currentUserDisplayName ?? 'A friend';

    return '$name wants you on Reflecto\n\n'
        'We don\'t always get the chance to talk to friends and family every day, '
        'but Reflecto makes it easy to keep up with the little moments in each other\'s lives through one daily update.\n\n'
        'Join $name and connect with them on Reflecto.\n\n'
        '🌐 Website:\n'
        'https://reflecto.co.in/\n\n'
        '📱 Android App:\n'
        'https://play.google.com/store/apps/details?id=com.masterboxer.reflecto';
  }

  Future<void> _shareInvite() async {
    await Share.share(
      _inviteMessage,
      subject: '${_currentUserDisplayName ?? 'A friend'} wants you on Reflecto',
    );
  }

  void _nextPage() async {
    if (_currentPage == _notificationScreenIndex) {
      await _handleNotificationPermission();
      return;
    }

    if (_currentPage == _inviteScreenIndex) {
      await _shareInvite();
      _advancePage();
      return;
    }

    if (_currentPage < _screens.length - 1) {
      _advancePage();
    } else {
      _completeOnboarding();
    }
  }

  void _advancePage() {
    if (_currentPage < _screens.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _handleNotificationPermission() async {
    if (!mounted) return;
    await showNotificationPermissionPage(context, onPermissionGranted: () {});
    if (mounted && _currentPage < _screens.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _screens.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screen = _screens[_currentPage];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(
                  _screens.length,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(
                        right: index < _screens.length - 1 ? 4 : 0,
                      ),
                      decoration: BoxDecoration(
                        color:
                            index <= _currentPage
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (_currentPage < _screens.length - 1 && !screen.isInviteScreen)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 8),
                  child: TextButton(
                    onPressed: _skipToEnd,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 48),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _screens.length,
                itemBuilder: (context, index) {
                  final s = _screens[index];
                  if (s.isInviteScreen) {
                    return _buildInviteScreenContent(theme);
                  }
                  return _buildScreenContent(s, theme);
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _nextPage,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        screen.primaryCTA,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  if (screen.secondaryCTA != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          if (screen.isInviteScreen) {
                            _advancePage();
                          } else if (_currentPage < _screens.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          screen.secondaryCTA!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenContent(OnboardingScreen screen, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: screen.iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(screen.icon, size: 64, color: screen.iconColor),
          ),

          const SizedBox(height: 48),

          Text(
            screen.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          Text(
            screen.body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          if (screen.caption != null) ...[
            const SizedBox(height: 16),
            Text(
              screen.caption!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildInviteScreenContent(ThemeData theme) {
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_rounded,
                size: 64,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 48),

            Text(
              'Invite friends\nand family',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            Text(
              'Reflecto is better with people you know. Invite friends and family so you can keep up with each other\'s daily moments no matter how busy life gets.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              'Grow your Reflecto circle',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingScreen {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String? caption;
  final String primaryCTA;
  final String? secondaryCTA;
  final bool isNotificationScreen;
  final bool isInviteScreen;

  OnboardingScreen({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.caption,
    required this.primaryCTA,
    this.secondaryCTA,
    this.isNotificationScreen = false,
    this.isInviteScreen = false,
  });
}
