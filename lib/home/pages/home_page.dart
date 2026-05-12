import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:project_micro_journal/authentication/services/authentication_token_storage_service.dart';
import 'package:project_micro_journal/environment/development.dart';
import 'package:project_micro_journal/home/models/streak.dart';
import 'package:project_micro_journal/posts/pages/create_post_page.dart';
import 'package:project_micro_journal/templates/template_model.dart';
import 'package:project_micro_journal/templates/template_service.dart';
import 'package:project_micro_journal/utils/app_navigator.dart';
import 'package:project_micro_journal/utils/micro_journaling_habit_page.dart';
import 'package:project_micro_journal/utils/notifications_permissions_page.dart';

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
  PersonalStreak? _streak;
  bool _isLoading = true;
  String? _error;
  int? _currentUserId;
  bool _showVerificationBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
    _initializeLocalNotifications();
    _checkAndRequestNotifications();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    _error = null;

    try {
      final String? userIdStr = await _authStorage.getUserId();
      if (userIdStr != null) {
        _currentUserId = int.parse(userIdStr);
      }

      await _templateService.fetchTemplatesFromBackend();
      await Future.wait([
        _loadFeed(),
        _loadStreak(),
        _loadUserVerificationStatus(),
      ]);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildVerificationBanner() {
    if (!_showVerificationBanner) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDark ? const Color(0xFF2D1A00) : const Color(0xFFFFF3E0);
    final borderColor =
        isDark ? const Color(0xFFBF6000) : const Color(0xFFFFB74D);
    final titleColor =
        isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
    final bodyColor =
        isDark ? const Color(0xFFCC8800) : const Color(0xFFF57C00);
    final iconColor =
        isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mark_email_unread_outlined, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify your email',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Please check your inbox and verify your email address to secure your account.',
                  style: TextStyle(fontSize: 13, color: bodyColor, height: 1.4),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _isResendingEmail ? null : _resendVerificationEmail,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _isResendingEmail ? 'Sending...' : 'Resend email',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isResendingEmail ? bodyColor : titleColor,
                        decoration: TextDecoration.underline,
                        decorationColor:
                            _isResendingEmail ? bodyColor : titleColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showVerificationBanner = false),
            child: Icon(Icons.close, size: 18, color: iconColor),
          ),
        ],
      ),
    );
  }

  bool _isResendingEmail = false;

  Future<void> _resendVerificationEmail() async {
    if (_isResendingEmail) return;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.statusCode == 200
                  ? 'Verification email sent! Check your inbox.'
                  : 'Failed to resend. Please try again.',
            ),
            backgroundColor:
                response.statusCode == 200 ? Colors.green : Colors.red,
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
      'Time to reflect 🧪',
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
        setState(() {
          _showVerificationBanner = !verified;
        });
      }
    }
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
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

          if (postDay == today) {
            return true;
          }
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
              _EditPostDialog(initialText: post['text'] as String),
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
    if (userId == null) {
      return;
    }

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
      if (userIdStr == null) {
        throw Exception('User ID not found');
      }

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

  Future<void> _loadStreak() async {
    if (_currentUserId == null) return;

    final String? token = await _authStorage.getAccessToken();
    final response = await http.get(
      Uri.parse('$environmentVariable/users/$_currentUserId/streak'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['exists'] == false) {
        setState(() => _streak = null);
      } else {
        setState(() => _streak = PersonalStreak.fromJson(data));
      }
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
          (context) => CommentsBottomSheet(
            postId: post['id'],
            currentUserId: _currentUserId!,
            onCommentAdded: () => _loadFeed(),
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

    setState(() => _isLoading = true);

    try {
      if (shouldReloadStreak) {
        await Future.wait([_loadFeed(), _loadStreak()]);
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
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Post created successfully! 🔥'),
                ],
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Post created but not visible yet. Pull to refresh.',
              ),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Refresh',
                textColor: Colors.white,
                onPressed: () async {
                  await Future.wait([_loadFeed(), _loadStreak()]);
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
                await Future.wait([_loadFeed(), _loadStreak()]);
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
      await Future.wait([_loadFeed(), _loadStreak()]);
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to load feed', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(_error!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _initializeData,
              child: const Text('Retry'),
            ),
          ],
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
          _buildStreakSection(),
          const SizedBox(height: 24),
          _buildVerificationBanner(),
          const SizedBox(height: 12),

          if (_userPosts.isNotEmpty) ...[
            _CollapsibleUserPosts(
              posts: _userPosts,
              buildCard: (post) => _buildUserPostCard(theme, post),
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
            ..._friendsPosts
                .map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildFriendPostCard(theme, post),
                  ),
                )
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildUserPostCard(ThemeData theme, Map<String, dynamic> post) {
    final templateId = post['templateId'] as int?;
    PostTemplate? template =
        templateId != null
            ? _templateService.getTemplateById(templateId)
            : null;
    final displayName = template?.name ?? 'Reflection';
    final journalDate =
        post['journal_date'] != null
            ? DateTime.parse(post['journal_date'])
            : post['timestamp'] as DateTime;
    final commentCount = post['comment_count'] as int;
    final totalReactions = post['total_reactions'] as int? ?? 0;
    final userReaction = post['user_reaction'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  template?.iconData ?? Icons.help_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _editPost(post),
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                  tooltip: 'Edit post',
                ),
                IconButton(
                  onPressed: () => _deletePost(post['id']),
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: theme.colorScheme.error.withOpacity(0.7),
                  ),
                  tooltip: 'Delete post',
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _buildBadge(
                  icon: Icons.schedule,
                  label: _getPostedLabel(journalDate),
                  background: theme.colorScheme.surfaceVariant,
                  foreground: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(post['text'], style: theme.textTheme.bodyLarge),

            const SizedBox(height: 12),
            const Divider(),

            Row(
              children: [
                InkWell(
                  onTap: () => _showReactionPicker(post['id'], post),
                  onLongPress: () => _showReactionPicker(post['id'], post),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        if (userReaction != null)
                          Text(
                            _reactionEmojis[userReaction]!,
                            style: const TextStyle(fontSize: 20),
                          )
                        else
                          Icon(
                            Icons.favorite_border,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          '$totalReactions',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () => _showCommentsSheet(post),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$commentCount',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (totalReactions > 0)
                  TextButton(
                    onPressed: () => _showReactionsList(post['id']),
                    child: const Text('View Reactions'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendPostCard(ThemeData theme, Map<String, dynamic> post) {
    final templateId = post['templateId'] as int?;
    final template =
        templateId != null
            ? _templateService.getTemplateById(templateId)
            : null;
    final userName = post['userName'] ?? 'Friend';
    final journalDate =
        post['journal_date'] != null
            ? DateTime.parse(post['journal_date'])
            : post['timestamp'] as DateTime;
    final commentCount = post['comment_count'] as int;
    final totalReactions = post['total_reactions'] as int? ?? 0;
    final userReaction = post['user_reaction'] as String?;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatExpirationTime(journalDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (template != null) ...[
                    Icon(
                      template.iconData,
                      size: 16,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      template?.name ?? 'Unknown template',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(post['text'], style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              children: [
                InkWell(
                  onTap: () => _showReactionPicker(post['id'], post),
                  onLongPress: () => _showReactionPicker(post['id'], post),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        if (userReaction != null)
                          Text(
                            _reactionEmojis[userReaction]!,
                            style: TextStyle(fontSize: 20),
                          )
                        else
                          Icon(
                            Icons.favorite_border,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          '$totalReactions',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () => _showCommentsSheet(post),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$commentCount',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (totalReactions > 0)
                  TextButton(
                    onPressed: () => _showReactionsList(post['id']),
                    child: const Text('View Reactions'),
                  ),
              ],
            ),
          ],
        ),
      ),
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

        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Reactions (${reactions.length})'),
                content:
                    reactions.isEmpty
                        ? const Text('No reactions yet')
                        : SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: reactions.length,
                            itemBuilder: (context, index) {
                              final reaction = reactions[index];
                              return ListTile(
                                leading: Text(
                                  _reactionEmojis[reaction['reaction_type']] ??
                                      '❤️',
                                  style: TextStyle(fontSize: 24),
                                ),
                                title: Text(
                                  reaction['display_name'] ?? 'Unknown',
                                ),
                                subtitle: Text(
                                  '@${reaction['username'] ?? 'unknown'}',
                                ),
                              );
                            },
                          ),
                        ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading reactions: $e')));
      }
    }
  }

  final Map<String, String> _reactionEmojis = {
    'heart': '❤️',
    'laugh': '😂',
    'sad': '😢',
    'angry': '😠',
    'surprised': '🤯',
  };

  Future<void> _showReactionPicker(
    int postId,
    Map<String, dynamic> post,
  ) async {
    final currentReaction = post['user_reaction'] as String?;
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'React to this post',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children:
                        _reactionEmojis.entries.map((entry) {
                          final isSelected = currentReaction == entry.key;
                          return InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _addReaction(postId, entry.key);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? theme.colorScheme.primaryContainer
                                        : theme.colorScheme.surfaceVariant
                                            .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    isSelected
                                        ? Border.all(
                                          color: theme.colorScheme.primary,
                                          width: 2,
                                        )
                                        : null,
                              ),
                              child: Text(
                                entry.value,
                                style: TextStyle(fontSize: 32),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _addReaction(int postId, String reactionType) async {
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

  Widget _buildStreakSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              color:
                  _streak != null && _streak!.streakCount > 0
                      ? Colors.orange
                      : Colors.grey,
              size: 48,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_streak?.streakCount ?? 0} Day Streak',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Longest: ${_streak?.longestStreak ?? 0} days',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
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
        ),
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: _buildVerificationBanner(),
        ),
      ],
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

class CommentsBottomSheet extends StatefulWidget {
  final int postId;
  final int currentUserId;
  final VoidCallback onCommentAdded;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    required this.currentUserId,
    required this.onCommentAdded,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _EditPostDialog extends StatefulWidget {
  final String initialText;
  const _EditPostDialog({required this.initialText});

  @override
  State<_EditPostDialog> createState() => _EditPostDialogState();
}

class _CollapsibleUserPosts extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final Widget Function(Map<String, dynamic> post) buildCard;
  final ThemeData theme;

  const _CollapsibleUserPosts({
    required this.posts,
    required this.buildCard,
    required this.theme,
  });

  @override
  State<_CollapsibleUserPosts> createState() => _CollapsibleUserPostsState();
}

class _CollapsibleUserPostsState extends State<_CollapsibleUserPosts> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Your Posts (${widget.posts.length})',
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: widget.theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: widget.theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              const SizedBox(height: 12),
              ...widget.posts.map(
                (post) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: widget.buildCard(post),
                ),
              ),
            ],
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}

class _EditPostDialogState extends State<_EditPostDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Post'),
      content: TextField(
        controller: _controller,
        maxLength: 500,
        maxLines: 5,
        autofocus: true,
        decoration: InputDecoration(
          hintText: "What's on your mind?",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final trimmed = _controller.text.trim();
            if (trimmed.isNotEmpty) {
              Navigator.of(context).pop(trimmed);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${Environment.baseUrl}posts/${widget.postId}/comments?user_id=${widget.currentUserId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic responseBody = json.decode(response.body);
        List<Map<String, dynamic>> commentsData;
        if (responseBody == null) {
          commentsData = [];
        } else if (responseBody is List) {
          commentsData = responseBody.cast<Map<String, dynamic>>();
        } else {
          commentsData = [];
        }
        if (mounted) {
          setState(() {
            _comments = commentsData;
            _isLoading = false;
          });
        }
      } else {
        if (mounted)
          setState(() {
            _comments = [];
            _isLoading = false;
          });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _comments = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading comments: $e')));
      }
    }
  }

  Future<void> _likeComment(int commentId) async {
    try {
      final response = await http.post(
        Uri.parse('${Environment.baseUrl}comments/$commentId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': widget.currentUserId}),
      );
      if (response.statusCode == 200) {
        await _loadComments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Comment'),
            content: const Text('Delete this comment?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm != true || !mounted) return;

    try {
      final response = await http.delete(
        Uri.parse('${Environment.baseUrl}comments/$commentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': widget.currentUserId}),
      );
      if (response.statusCode == 200) {
        await _loadComments();
        widget.onCommentAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final response = await http.post(
        Uri.parse('${Environment.baseUrl}posts/${widget.postId}/comments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.currentUserId,
          'text': _commentController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        _commentController.clear();
        await _loadComments();
        widget.onCommentAdded();

        if (mounted) {
          FocusScope.of(context).unfocus();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error posting comment: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Comments (${_comments.length})',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _comments.isEmpty
                      ? SingleChildScrollView(
                        controller: scrollController,
                        child: SizedBox(
                          height: 280,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.comment_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No comments yet',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to comment!',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      : ListView.builder(
                        controller: scrollController,
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final isOwner =
                              (comment['user_id'] as int) ==
                              widget.currentUserId;
                          final likeCount = comment['like_count'] as int? ?? 0;
                          final userLiked =
                              comment['user_liked'] as bool? ?? false;

                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                (comment['display_name'] ?? 'U')[0]
                                    .toUpperCase(),
                              ),
                            ),
                            title: Text(
                              comment['display_name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(comment['text']),
                                const SizedBox(height: 4),
                                Text(
                                  _formatCommentTime(comment['created_at']),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (likeCount > 0 && isOwner)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.favorite,
                                          size: 16,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$likeCount',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                if (!isOwner)
                                  InkWell(
                                    onTap:
                                        () =>
                                            _likeComment(comment['id'] as int),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            userLiked
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            size: 16,
                                            color:
                                                userLiked
                                                    ? Colors.red
                                                    : theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                          ),
                                          if (likeCount > 0) ...[
                                            const SizedBox(width: 3),
                                            Text(
                                              '$likeCount',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                if (isOwner)
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: theme.colorScheme.error
                                          .withOpacity(0.7),
                                    ),
                                    onPressed:
                                        () => _deleteComment(
                                          comment['id'] as int,
                                        ),
                                    tooltip: 'Delete comment',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
            const Divider(height: 1),
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      maxLength: 500,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _postComment,
                    icon:
                        _isSending
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatCommentTime(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
