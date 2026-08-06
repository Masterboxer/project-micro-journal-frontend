import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:project_micro_journal/authentication/services/authentication_token_storage_service.dart';
import 'package:project_micro_journal/environment/development.dart';
import 'package:project_micro_journal/home/models/reflecto_progress.dart';
import 'package:project_micro_journal/posts/pages/create_post_page.dart';
import 'package:project_micro_journal/posts/pages/first_post_invite_popup.dart';
import 'package:project_micro_journal/profile/pages/profile_page.dart';
import 'package:project_micro_journal/templates/template_model.dart';
import 'package:project_micro_journal/templates/template_service.dart';
import 'package:project_micro_journal/utils/app_navigator.dart';
import 'package:project_micro_journal/utils/micro_journaling_habit_page.dart';
import 'package:project_micro_journal/utils/notifications_permissions_page.dart';
import 'package:project_micro_journal/utils/rate_app_popup.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../comments/comments_bottom_sheet.dart';
import '../dialogs/edit_post_dialog.dart';
import '../widgets/collapsible_user_posts.dart';
import '../widgets/post_card.dart';
import '../widgets/reaction_picker.dart';
import '../widgets/reflecto_score_section.dart';
import '../widgets/verification_banner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final TemplateService _templateService = TemplateService.instance;
  final AuthenticationTokenStorageService _authStorage =
      AuthenticationTokenStorageService();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final environmentVariable = Environment.baseUrl;

  List<Map<String, dynamic>> _userPosts = [];
  List<Map<String, dynamic>> _friendsPosts = [];
  ReflectoProgress? _reflectionProgress;
  bool _isLoading = true;
  String? _error;
  int? _currentUserId;
  bool _showVerificationBanner = false;
  bool _isOffline = false;

  bool _isResendingEmail = false;
  Duration? _resendCooldown;
  Timer? _resendTimer;

  static const _kResendUntilKey = 'resend_verification_until';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
    _initializeLocalNotifications();
    _checkAndRequestNotifications();
    _restoreCooldownFromStorage();
  }

  Future<void> _restoreCooldownFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMillis = prefs.getInt(_kResendUntilKey);
    if (storedMillis == null) return;

    final retryAfter = DateTime.fromMillisecondsSinceEpoch(storedMillis);
    final remaining = retryAfter.difference(DateTime.now());

    if (remaining.isNegative || remaining == Duration.zero) {
      await prefs.remove(_kResendUntilKey);
      return;
    }

    _startCountdown(remaining);
  }

  bool _looksLikeNetworkError(dynamic error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('clientexception') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection refused') ||
        msg.contains('failed host lookup') ||
        msg.contains('handshakeexception') ||
        msg.contains('os error');
  }

  void _navigateToUserProfile(int userId, String displayName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ProfilePage(viewUserId: userId, viewDisplayName: displayName),
      ),
    );
  }

  void _startCountdown(Duration remaining) {
    if (!mounted) return;
    setState(() => _resendCooldown = remaining);

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final next = _resendCooldown! - const Duration(seconds: 1);

      if (next <= Duration.zero) {
        timer.cancel();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_kResendUntilKey);
        if (mounted) setState(() => _resendCooldown = null);
      } else {
        if (next.inSeconds % 10 == 0) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(
            _kResendUntilKey,
            DateTime.now().add(next).millisecondsSinceEpoch,
          );
        }
        if (mounted) setState(() => _resendCooldown = next);
      }
    });
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    _error = null;
    _isOffline = false;

    try {
      final String? userIdStr = await _authStorage.getUserId();
      if (userIdStr != null) {
        _currentUserId = int.parse(userIdStr);
      }

      await _templateService.fetchTemplatesFromBackend();
      await Future.wait([
        _loadFeed(),
        _loadReflectionProgress(),
        _loadUserVerificationStatus(),
      ]);
      if (_showVerificationBanner) {
        _startVerificationPolling();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isOffline = _looksLikeNetworkError(e);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Timer? _verificationPollTimer;

  void _startVerificationPolling() {
    _verificationPollTimer?.cancel();
    _verificationPollTimer = Timer.periodic(const Duration(seconds: 5), (
      _,
    ) async {
      if (!_showVerificationBanner) {
        _verificationPollTimer?.cancel();
        return;
      }
      await _loadUserVerificationStatus();
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (_isResendingEmail || _resendCooldown != null) return;

    final String? email = await _authStorage.getEmail();

    if (!mounted) return;
    setState(() => _isResendingEmail = true);

    try {
      final url = Uri.parse('${environmentVariable}resend-verification-mail');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        const cooldown = Duration(minutes: 3);
        final retryAfter = DateTime.now().add(cooldown);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_kResendUntilKey, retryAfter.millisecondsSinceEpoch);
        _startCountdown(cooldown);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to resend. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isResendingEmail = false);
    }
  }

  Future<void> microJournalHabitNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          channelDescription: 'Daily reminder to post',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      9999,
      'Time to Reflecto 🧪',
      'Tap to open Micro Journaling Habit page',
      notificationDetails,
      payload: 'daily_reminder',
    );
  }

  Future<void> _loadUserVerificationStatus() async {
    if (_currentUserId == null) return;
    final response = await http.get(
      Uri.parse('${environmentVariable}users/$_currentUserId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final verified = data['email_verified'] as bool? ?? false;
      if (mounted) {
        setState(() => _showVerificationBanner = !verified);
        if (verified) {
          _verificationPollTimer?.cancel();
        }
      }
    }
  }

  String _getPostedLabel(DateTime journalDate) {
    final local = journalDate.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final postDate = DateTime(local.year, local.month, local.day);
    final diff = today.difference(postDate).inDays;
    final timeStr = _formatTime(local);
    if (diff == 0) return 'Today at $timeStr';
    if (diff == 1) return 'Yesterday at $timeStr';
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year} at $timeStr';
  }

  String _formatExpirationTime(DateTime journalDate) {
    final local = journalDate.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final postDate = DateTime(local.year, local.month, local.day);
    final diff = today.difference(postDate).inDays;
    final timeStr = _formatTime(local);
    if (diff == 0) return 'Today at $timeStr';
    if (diff == 1) return 'Yesterday at $timeStr';
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year} at $timeStr';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:$minute $period';
  }

  Future<bool> _hasPostedToday() async {
    try {
      final String? userIdStr = await _authStorage.getUserId();
      if (userIdStr == null) return false;

      final response = await http.get(
        Uri.parse('${Environment.baseUrl}posts/$userIdStr/feed'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) return false;

      final dynamic responseBody = json.decode(response.body);
      final List<dynamic> feedData = responseBody is List ? responseBody : [];

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final int userId = int.parse(userIdStr);

      for (final post in feedData) {
        if ((post['user_id'] as int) == userId) {
          final postDate = DateTime.parse(post['created_at']);
          final postDay = DateTime(postDate.year, postDate.month, postDate.day);
          if (postDay == today) return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _editPost(Map<String, dynamic> post) async {
    final newText = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogContext) =>
              EditPostDialog(initialText: post['text'] as String),
    );

    if (!mounted) return;
    if (newText == null || newText == post['text']) return;

    try {
      final response = await http.put(
        Uri.parse('${Environment.baseUrl}posts/${post['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': _currentUserId, 'text': newText}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        await _loadFeed();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update post'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload == 'daily_reminder_check') {
          final hasPosted = await _hasPostedToday();
          if (!hasPosted) {
            appNavigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => const MicroJournalingHabitPage(),
                fullscreenDialog: true,
              ),
            );
          }
        } else if (response.payload == 'daily_reminder') {
          appNavigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => const MicroJournalingHabitPage(),
              fullscreenDialog: true,
            ),
          );
        }
      },
    );

    const AndroidNotificationChannel defaultChannel =
        AndroidNotificationChannel(
          'default_notification_channel',
          'Default Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.high,
        );
    const AndroidNotificationChannel reminderChannel =
        AndroidNotificationChannel(
          'daily_reminder_channel',
          'Daily Reminders',
          description: 'Daily reminder to post',
          importance: Importance.high,
        );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(defaultChannel);
      await androidPlugin.createNotificationChannel(reminderChannel);
    }
  }

  Future<void> _checkAndRequestNotifications() async {
    if (await shouldShowNotificationPermission()) {
      if (mounted) {
        final granted = await showNotificationPermissionPage(
          context,
          onPermissionGranted: () {},
        );
        if (granted == true) {
          await setupPushNotifications();
        }
      }
    } else {
      await setupPushNotifications();
    }
  }

  Future<void> setupPushNotifications() async {
    final fcmToken = await _firebaseMessaging.getToken();
    await sendTokenToBackend(fcmToken);

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      sendTokenToBackend(newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
      if (message.data['type'] == 'post_like' ||
          message.data['type'] == 'post_comment' ||
          message.data['type'] == 'new_post') {
        _loadFeed();
      }
    });
  }

  Future<void> sendTokenToBackend(String? token) async {
    if (token == null) return;

    final String? userId = await _authStorage.getUserId();
    if (userId == null) return;

    final requestBody = {'token': token, 'user_id': int.parse(userId)};

    await http.post(
      Uri.parse('${environmentVariable}fcm/register-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );
  }

  Future<void> _loadFeed() async {
    try {
      final String? userIdStr = await _authStorage.getUserId();
      if (userIdStr == null) throw Exception('User ID not found');

      final int userId = int.parse(userIdStr);

      final response = await http.get(
        Uri.parse('${Environment.baseUrl}posts/$userIdStr/feed'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic responseBody = json.decode(response.body);
        final List<dynamic> feedData = responseBody is List ? responseBody : [];

        final userPosts = <Map<String, dynamic>>[];
        final buddyPosts = <Map<String, dynamic>>[];

        for (final post in feedData) {
          final postMap = {
            'id': post['id'],
            'user_id': post['user_id'],
            'templateId': post['template_id'],
            'text': post['text'],
            'timestamp': DateTime.parse(post['created_at']),
            'userName': post['display_name'] ?? post['username'] ?? 'User',
            'comment_count': post['comment_count'] ?? 0,
            'reactions': post['reactions'] ?? {},
            'user_reaction': post['user_reaction'],
            'total_reactions': post['total_reactions'] ?? 0,
          };

          if ((post['user_id'] as int) == userId) {
            userPosts.add(postMap);
          } else {
            buddyPosts.add(postMap);
          }
        }

        if (mounted) {
          setState(() {
            _userPosts = userPosts;
            _friendsPosts = buddyPosts;
            _error = null;
          });
        }
      } else {
        throw Exception('Failed to load feed: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading feed: $e';
        });
      }
    }
  }

  Future<void> _loadReflectionProgress() async {
    if (_currentUserId == null) return;

    final String? token = await _authStorage.getAccessToken();
    final response = await http.get(
      Uri.parse(
        '${environmentVariable}users/$_currentUserId/reflecto-progress',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() => _reflectionProgress = ReflectoProgress.fromJson(data));
    }
  }

  Future<void> _showCommentsSheet(Map<String, dynamic> post) async {
    if (_currentUserId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetContext) => CommentsBottomSheet(
            postId: post['id'],
            currentUserId: _currentUserId!,
            onCommentAdded: () => _loadFeed(),
            onCommentPosted: (tapPosition) {},
          ),
    );
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_notification_channel',
          'Default Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? '',
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  Future<void> createNewPost() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );

    if (result == null) return;
    if (!mounted) return;

    final createdPostId = result['id'];
    final shouldReloadStreak = result['should_reload_streak'] ?? false;
    final newPostText = result['text'] as String? ?? '';

    setState(() => _isLoading = true);

    try {
      if (shouldReloadStreak) {
        await Future.wait([_loadFeed(), _loadReflectionProgress()]);
      } else {
        await _loadFeed();
      }

      if (mounted) {
        setState(() => _isLoading = false);

        final newPostExists = _userPosts.any(
          (post) => post['id'] == createdPostId,
        );

        if (newPostExists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Post created successfully! 🔥'),
                ],
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          final prefs = await SharedPreferences.getInstance();
          final hasSeenInvitePopup =
              prefs.getBool('has_seen_invite_popup') ?? false;

          if (!hasSeenInvitePopup && mounted) {
            await prefs.setBool('has_seen_invite_popup', true);
            await Future.delayed(const Duration(milliseconds: 600));

            if (mounted) {
              final displayName =
                  await _authStorage.getDisplayName() ?? 'Someone';
              await FirstPostInvitePopup.show(
                context,
                postText: newPostText,
                userName: displayName,
              );
            }
          }
          await RateAppPopup.onPostCreated(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Post created but not visible yet. Pull to refresh.',
              ),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Refresh',
                textColor: Colors.white,
                onPressed: () async {
                  await Future.wait([_loadFeed(), _loadReflectionProgress()]);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh feed: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () async {
                await Future.wait([_loadFeed(), _loadReflectionProgress()]);
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _refreshPosts() async {
    _error = null;
    try {
      await Future.wait([_loadFeed(), _loadReflectionProgress()]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isOffline ? Icons.wifi_off_rounded : Icons.error_outline,
                size: 64,
                color:
                    _isOffline
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _isOffline ? 'No internet connection' : 'Something went wrong',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isOffline
                    ? 'Check your Wi-Fi or mobile data and try again.'
                    : 'We couldn\'t load your feed. Please try again.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _initializeData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_userPosts.isEmpty && _friendsPosts.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReflectionJourneySection(
            daysPosted: _reflectionProgress?.daysPosted ?? 0,
            stage: _reflectionProgress?.stage ?? GrowthStage.seed,
            daysToNext: _reflectionProgress?.daysToNext ?? 3,
            progressInStage: _reflectionProgress?.progressInStage ?? 0.0,
            hasPostedToday: _userPosts.isNotEmpty,
          ),
          const SizedBox(height: 16),
          VerificationBanner(
            show: _showVerificationBanner,
            isResending: _isResendingEmail,
            resendCooldown: _resendCooldown,
            onResend: _resendVerificationEmail,
            onDismiss: () => setState(() => _showVerificationBanner = false),
          ),

          if (_userPosts.isNotEmpty) ...[
            const SizedBox(height: 8),
            CollapsibleUserPosts(
              posts: _userPosts,
              buildCard: (post) => _buildUserPostCard(post),
              theme: theme,
            ),
            const SizedBox(height: 24),
          ],

          if (_friendsPosts.isNotEmpty) ...[
            Text(
              'Friends Activity (${_friendsPosts.length})',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._friendsPosts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildFriendPostCard(post),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserPostCard(Map<String, dynamic> post) {
    final templateId = post['templateId'] as int?;
    final PostTemplate? template =
        templateId != null
            ? _templateService.getTemplateById(templateId)
            : null;
    final journalDate =
        post['journal_date'] != null
            ? DateTime.parse(post['journal_date'])
            : post['timestamp'] as DateTime;

    return UserPostCard(
      post: post,
      template: template,
      postedLabel: _getPostedLabel(journalDate),
      reactionEmojis: kReactionEmojis,
      onEdit: () => _editPost(post),
      onDelete: () => _deletePost(post['id']),
      onReact: () => _showReactionPicker(post['id'], post),
      onComment: () => _showCommentsSheet(post),
      onViewReactions: () => _showReactionsList(post['id']),
    );
  }

  Widget _buildFriendPostCard(Map<String, dynamic> post) {
    final templateId = post['templateId'] as int?;
    final PostTemplate? template =
        templateId != null
            ? _templateService.getTemplateById(templateId)
            : null;
    final journalDate =
        post['journal_date'] != null
            ? DateTime.parse(post['journal_date'])
            : post['timestamp'] as DateTime;

    return FriendPostCard(
      post: post,
      template: template,
      expirationLabel: _formatExpirationTime(journalDate),
      reactionEmojis: kReactionEmojis,
      onTapAvatar:
          () => _navigateToUserProfile(
            post['user_id'] as int,
            post['userName'] as String,
          ),
      onReact: () => _showReactionPicker(post['id'], post),
      onComment: () => _showCommentsSheet(post),
      onViewReactions: () => _showReactionsList(post['id']),
    );
  }

  Future<void> _showReactionsList(int postId) async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.baseUrl}posts/$postId/reacts'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> reactions = json.decode(response.body);
        if (!mounted) return;
        ReactionPicker.showReactionsList(context, reactions);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading reactions: $e')));
      }
    }
  }

  Future<void> _showReactionPicker(
    int postId,
    Map<String, dynamic> post,
  ) async {
    final currentReaction = post['user_reaction'] as String?;
    await ReactionPicker.show(
      context,
      currentReaction: currentReaction,
      onSelect:
          (reactionType, tapPosition, isUnselecting) =>
              _addReaction(postId, reactionType, tapPosition, isUnselecting),
    );
  }

  Future<void> _addReaction(
    int postId,
    String reactionType,
    Offset tapPosition,
    bool isUnselecting,
  ) async {
    if (_currentUserId == null) return;

    try {
      final response = await http.post(
        Uri.parse('${Environment.baseUrl}posts/$postId/react'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _currentUserId,
          'reaction_type': reactionType,
        }),
      );

      if (response.statusCode == 200) {
        await _loadFeed();
      }
    } catch (e) {
      // handle error
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _refreshPosts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReflectionJourneySection(
            daysPosted: _reflectionProgress?.daysPosted ?? 0,
            stage: _reflectionProgress?.stage ?? GrowthStage.seed,
            daysToNext: _reflectionProgress?.daysToNext ?? 3,
            progressInStage: _reflectionProgress?.progressInStage ?? 0.0,
            hasPostedToday: _userPosts.isNotEmpty,
          ),
          const SizedBox(height: 16),
          VerificationBanner(
            show: _showVerificationBanner,
            isResending: _isResendingEmail,
            resendCooldown: _resendCooldown,
            onResend: _resendVerificationEmail,
            onDismiss: () => setState(() => _showVerificationBanner = false),
          ),
          const SizedBox(height: 48),
          Column(
            children: [
              Icon(
                Icons.edit_note_outlined,
                size: 80,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'No post yet today',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Share your thoughts and reflections for today',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: createNewPost,
                icon: const Icon(Icons.add),
                label: const Text('Create Your First Post'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(int postId) async {
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Post'),
            content: const Text(
              'Are you sure you want to delete this post? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      try {
        final response = await http.delete(
          Uri.parse('${Environment.baseUrl}posts/$postId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          await _initializeData();
          if (mounted) {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(content: Text('Post deleted successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(
                content: Text('Failed to delete post'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _verificationPollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  AppLifecycleState? _lastLifecycleState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (_lastLifecycleState == AppLifecycleState.paused) {
        _initializeData();
      }
    }

    _lastLifecycleState = state;
  }
}
