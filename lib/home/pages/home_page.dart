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
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

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
      await Future.wait([_loadFeed(), _loadStreak()]);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload == 'daily_reminder') {
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
          await _scheduleDailyReminder();
        }
      }
    } else {
      await setupPushNotifications();
      await _scheduleDailyReminder();
    }
  }

  Future<void> _scheduleDailyReminder() async {
    // Initialize timezone data
    tz.initializeTimeZones();

    // Get the user's timezone (you might want to fetch this from your backend)
    final locationName = tz.local.name;
    final location = tz.getLocation(locationName);

    // Schedule for 9 PM today
    var scheduledDate = tz.TZDateTime.now(location).add(
      Duration(
        hours: 21 - tz.TZDateTime.now(location).hour,
        minutes: -tz.TZDateTime.now(location).minute,
        seconds: -tz.TZDateTime.now(location).second,
      ),
    );

    // If 9 PM has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(tz.TZDateTime.now(location))) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

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

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // Notification ID
      'Time to reflect! 📝',
      'Share your thoughts and reflections for today',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // Repeat daily at same time
    );
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
            'photoPath': post['photo_path'],
            'timestamp': DateTime.parse(post['created_at']),
            'userName': post['display_name'] ?? post['username'] ?? 'User',
            'like_count': post['like_count'] ?? 0,
            'comment_count': post['comment_count'] ?? 0,
            'is_liked_by_user': post['is_liked_by_user'] ?? false,
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

    try {
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
    } catch (e) {
      print('Error loading streak: $e');
    }
  }

  Future<void> _toggleLike(int postId) async {
    if (_currentUserId == null) return;

    try {
      final response = await http.post(
        Uri.parse('${Environment.baseUrl}posts/$postId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': _currentUserId}),
      );

      if (response.statusCode == 200) {
        await _loadFeed();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error toggling like: $e')));
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

  Future<void> _showLikesList(int postId) async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.baseUrl}posts/$postId/likes'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> likes = json.decode(response.body);

        if (!mounted) return;

        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Likes (${likes.length})'),
                content:
                    likes.isEmpty
                        ? const Text('No likes yet')
                        : SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: likes.length,
                            itemBuilder: (context, index) {
                              final like = likes[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    (like['display_name'] ?? 'U')[0]
                                        .toUpperCase(),
                                  ),
                                ),
                                title: Text(like['display_name'] ?? 'Unknown'),
                                subtitle: Text(
                                  '@${like['username'] ?? 'unknown'}',
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
        ).showSnackBar(SnackBar(content: Text('Error loading likes: $e')));
      }
    }
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

  String _formatPostDate(DateTime timestamp) {
    final now = DateTime.now();
    final localTimestamp = timestamp.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final postDate = DateTime(
      localTimestamp.year,
      localTimestamp.month,
      localTimestamp.day,
    );

    if (postDate == today) {
      return 'Today';
    } else if (postDate == yesterday) {
      return 'Yesterday';
    } else {
      final daysAgo = today.difference(postDate).inDays;
      if (daysAgo <= 7) {
        return '$daysAgo day${daysAgo == 1 ? '' : 's'} ago';
      } else {
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return '${months[localTimestamp.month - 1]} ${localTimestamp.day}';
      }
    }
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
                  Text('Post created successfully! 🔥'), // ✅ Add fire emoji
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
          // Add streaks section at the top
          _buildStreakSection(),
          const SizedBox(height: 24),

          // Your existing posts sections
          if (_userPosts.isNotEmpty) ...[
            Text(
              'Your Posts (${_userPosts.length})',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._userPosts
                .map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildUserPostCard(theme, post),
                  ),
                )
                .toList(), // ← Add .toList() here
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
    final likeCount = post['like_count'] as int;
    final commentCount = post['comment_count'] as int;
    final isLiked = post['is_liked_by_user'] as bool;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatExpirationTime(journalDate),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    template?.iconData ?? Icons.help_outline,
                    size: 16,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(post['text'], style: theme.textTheme.bodyLarge),
            if (post['photoPath'] != null &&
                post['photoPath'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.photo,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Photo attached',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Divider(),
            Row(
              children: [
                InkWell(
                  onTap: () => _toggleLike(post['id']),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color:
                              isLiked
                                  ? Colors.red
                                  : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text('$likeCount', style: theme.textTheme.bodyMedium),
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
                if (likeCount > 0)
                  TextButton(
                    onPressed: () => _showLikesList(post['id']),
                    child: const Text('View Likes'),
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
    final likeCount = post['like_count'] as int;
    final commentCount = post['comment_count'] as int;
    final isLiked = post['is_liked_by_user'] as bool;

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
            if (post['photoPath'] != null &&
                post['photoPath'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.photo,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Photo attached',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Divider(),
            Row(
              children: [
                InkWell(
                  onTap: () => _toggleLike(post['id']),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color:
                              isLiked
                                  ? Colors.red
                                  : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text('$likeCount', style: theme.textTheme.bodyMedium),
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
                if (likeCount > 0)
                  TextButton(
                    onPressed: () => _showLikesList(post['id']),
                    child: const Text('View Likes'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format expiration time
  String _formatExpirationTime(DateTime journalDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final postDate = DateTime(
      journalDate.year,
      journalDate.month,
      journalDate.day,
    );

    // Calculate expiration (2 days after journal date)
    final expirationDate = postDate.add(const Duration(days: 2));
    final expiresAt = DateTime(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
    );

    final difference = expiresAt.difference(today).inDays;

    if (difference < 0) {
      return 'Expired';
    } else if (difference == 0) {
      return 'Expires today';
    } else if (difference == 1) {
      return 'Expires tomorrow';
    } else {
      return 'Expires in $difference days';
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            Text(
              'Share your thoughts and reflections for today',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final localTimestamp = timestamp.toLocal();
    final difference = now.difference(localTimestamp);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _initializeData();
    }
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
        Uri.parse('${Environment.baseUrl}posts/${widget.postId}/comments'),
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
        if (mounted) {
          setState(() {
            _comments = [];
            _isLoading = false;
          });
        }
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
                      ? Center(
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
                      )
                      : ListView.builder(
                        controller: scrollController,
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
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
