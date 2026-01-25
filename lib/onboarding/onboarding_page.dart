import 'package:flutter/material.dart';
import 'package:project_micro_journal/authentication/pages/signup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingScreen> _screens = [
    OnboardingScreen(
      icon: Icons.edit_note_rounded,
      iconColor: Colors.blue,
      title: "A space to reflect,\nnot perform",
      body:
          "Project Micro Journal is a place to pause and share honestly with the people who matter most.",
      caption: "Just you, your thoughts, and a few close friends",
      primaryCTA: "Continue",
    ),
    OnboardingScreen(
      icon: Icons.favorite_rounded,
      iconColor: Colors.blue,
      title: "One post,\nonce a day",
      body:
          "No pressure to post more. No scrolling endlessly. Just one small reflection when you're ready.",
      caption: "280 characters, one photo (optional)",
      primaryCTA: "Got it",
    ),
    OnboardingScreen(
      icon: Icons.local_fire_department_rounded,
      iconColor: Colors.orange,
      title: "Gentle streaks,\nnot strict rules",
      body:
          "We count the days you show up. Miss the evening? Post the next morning—your streak is safe.",
      caption: "Consistency matters, but life happens",
      primaryCTA: "That's nice",
    ),
    OnboardingScreen(
      icon: Icons.people_rounded,
      iconColor: Colors.blue,
      title: "3 friends,\nno more",
      body:
          "This isn't a place to grow an audience. You can connect with up to 3 people. That's it.",
      caption: "Quality over quantity, always",
      primaryCTA: "Makes sense",
    ),
    OnboardingScreen(
      icon: Icons.notifications_rounded,
      iconColor: Colors.blue,
      title: "Notifications that\nactually help",
      body:
          "We'll remind you when the day is ending and when your friends share. Nothing spammy, just helpful.",
      caption: "You can always adjust these later",
      primaryCTA: "Sounds good",
      secondaryCTA: "Maybe later",
    ),
    OnboardingScreen(
      icon: Icons.edit_rounded,
      iconColor: Colors.blue,
      title: "Ready to start?",
      body:
          "Your first post is waiting. No one's watching yet. Just write what's on your mind.",
      caption: null,
      primaryCTA: "Start Journaling",
    ),
  ];

  void _nextPage() {
    if (_currentPage < _screens.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
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
        MaterialPageRoute(builder: (context) => const SignupPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
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

            // Skip button
            if (_currentPage < _screens.length - 1)
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

            // Content
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
                  return _buildScreenContent(_screens[index], theme);
                },
              ),
            ),

            // Bottom buttons
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
                        _screens[_currentPage].primaryCTA,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  if (_screens[_currentPage].secondaryCTA != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _nextPage,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _screens[_currentPage].secondaryCTA!,
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
          // Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: screen.iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(screen.icon, size: 64, color: screen.iconColor),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            screen.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Body
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

  OnboardingScreen({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.caption,
    required this.primaryCTA,
    this.secondaryCTA,
  });
}
