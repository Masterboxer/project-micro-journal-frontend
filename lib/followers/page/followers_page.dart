import 'package:flutter/material.dart';
import 'package:project_micro_journal/followers/service/followers_service.dart';
import '../models/follower.dart';
import '../models/user_search_result.dart';
import '../models/follow_stats.dart';

class FollowersPage extends StatefulWidget {
  const FollowersPage({super.key});

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage>
    with SingleTickerProviderStateMixin {
  final FollowersService _followersService = FollowersService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;

  List<Follower> _followers = [];
  List<Follower> _following = [];
  List<Follower> _pendingRequests = [];
  List<UserSearchResult> _searchResults = [];
  FollowStats? _stats;

  bool _isSearching = false;
  bool _isLoadingFollowers = false;
  bool _isLoadingFollowing = false;
  bool _isLoadingPending = false;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadFollowers(),
      _loadFollowing(),
      _loadPendingRequests(),
      _loadStats(),
    ]);
  }

  Future<void> _loadFollowers() async {
    setState(() => _isLoadingFollowers = true);
    try {
      final followers = await _followersService.getFollowers();
      if (mounted) {
        setState(() {
          _followers = followers;
          _isLoadingFollowers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _followers = [];
          _isLoadingFollowers = false;
        });
      }
    }
  }

  Future<void> _loadFollowing() async {
    setState(() => _isLoadingFollowing = true);
    try {
      final following = await _followersService.getFollowing();
      if (mounted) {
        setState(() {
          _following = following;
          _isLoadingFollowing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _following = [];
          _isLoadingFollowing = false;
        });
      }
    }
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoadingPending = true);
    try {
      final pending = await _followersService.getPendingFollowRequests();
      if (mounted) {
        setState(() {
          _pendingRequests = pending;
          _isLoadingPending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingRequests = [];
          _isLoadingPending = false;
        });
      }
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final stats = await _followersService.getFollowStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _followersService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        _showSnackBar('Search failed: $e', isError: true);
      }
    }
  }

  Future<void> _followUser(
    int userId,
    String displayName,
    bool isPrivate,
  ) async {
    try {
      final result = await _followersService.followUser(userId);
      final status = result['status'] as String?;

      if (mounted) {
        if (status == 'pending') {
          _showSnackBar('Follow request sent to $displayName');
        } else {
          _showSnackBar('Following $displayName');
        }
        _searchController.clear();
        setState(() {
          _searchResults = [];
        });
        await _loadAllData();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to follow: $e', isError: true);
      }
    }
  }

  Future<void> _cancelFollowRequest(int userId, String displayName) async {
    try {
      await _followersService.cancelFollowRequest(userId);
      if (mounted) {
        _showSnackBar('Follow request cancelled');
        _searchController.clear();
        setState(() {
          _searchResults = [];
        });
        await _loadAllData();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to cancel request: $e', isError: true);
      }
    }
  }

  Future<void> _acceptFollowRequest(int followerId, String displayName) async {
    try {
      await _followersService.acceptFollowRequest(followerId);
      if (mounted) {
        _showSnackBar('Accepted follow request from $displayName');
        await _loadAllData();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to accept: $e', isError: true);
      }
    }
  }

  Future<void> _rejectFollowRequest(int followerId, String displayName) async {
    try {
      await _followersService.rejectFollowRequest(followerId);
      if (mounted) {
        _showSnackBar('Rejected follow request from $displayName');
        await _loadAllData();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to reject: $e', isError: true);
      }
    }
  }

  Future<void> _unfollowUser(int userId, String displayName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Unfollow User'),
            content: Text('Stop following $displayName?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Unfollow'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      try {
        await _followersService.unfollowUser(userId);
        if (mounted) {
          _showSnackBar('Unfollowed $displayName');
          await _loadAllData();
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Failed to unfollow: $e', isError: true);
        }
      }
    }
  }

  Future<void> _removeFollower(int followerId, String displayName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Follower'),
            content: Text('Remove $displayName from your followers?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      try {
        await _followersService.removeFollower(followerId);
        if (mounted) {
          _showSnackBar('Removed $displayName from followers');
          await _loadAllData();
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Failed to remove: $e', isError: true);
        }
      }
    }
  }

  Future<void> _showUnfollowOptions(Follower user) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    user.displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.person_remove_outlined),
                  title: const Text('Unfollow'),
                  subtitle: const Text('Stop following this user'),
                  onTap: () => Navigator.pop(context, 'unfollow'),
                ),
                ListTile(
                  leading: const Icon(Icons.block_outlined),
                  title: const Text('Unfollow and Remove Follower'),
                  subtitle: const Text('Break connection both ways'),
                  onTap: () => Navigator.pop(context, 'disconnect'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );

    if (result == 'unfollow' && mounted) {
      await _unfollowUser(user.id, user.displayName);
    } else if (result == 'disconnect' && mounted) {
      await _disconnectUser(user.id, user.displayName);
    }
  }

  Future<void> _disconnectUser(int userId, String displayName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Disconnect User'),
            content: Text(
              'This will unfollow $displayName AND remove them as a follower. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Disconnect'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      try {
        await _followersService.disconnectUser(userId);
        if (mounted) {
          _showSnackBar('Disconnected from $displayName');
          await _loadAllData();
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Failed to disconnect: $e', isError: true);
        }
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Followers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _searchUsers('');
                              },
                            )
                            : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _searchUsers,
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Followers'),
                        if (_stats != null) ...[
                          const SizedBox(width: 6),
                          _buildTabBadge(
                            '${_stats!.followersCount}',
                            theme.colorScheme.primaryContainer,
                            theme.colorScheme.onPrimaryContainer,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Following'),
                        if (_stats != null) ...[
                          const SizedBox(width: 6),
                          _buildTabBadge(
                            '${_stats!.followingCount}',
                            theme.colorScheme.secondaryContainer,
                            theme.colorScheme.onSecondaryContainer,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Requests'),
                        if (_stats != null &&
                            _stats!.pendingRequestsCount > 0) ...[
                          const SizedBox(width: 6),
                          _buildTabBadge(
                            '${_stats!.pendingRequestsCount}',
                            theme.colorScheme.errorContainer,
                            theme.colorScheme.onErrorContainer,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body:
          _searchController.text.isNotEmpty
              ? _buildSearchResults(theme)
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildFollowersList(theme),
                  _buildFollowingList(theme),
                  _buildPendingRequestsList(theme),
                ],
              ),
    );
  }

  Widget _buildTabBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final followStatus = user.followStatus ?? 'none';
        final isFollowing = followStatus == 'accepted';
        final requestSent = followStatus == 'pending';
        final followsYou = user.isFollower ?? false;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                if (user.isPrivate)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    user.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (followsYou) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Follows you',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              '@${user.username}',
              overflow: TextOverflow.ellipsis,
            ),
            trailing: SizedBox(
              width: 110,
              child:
                  isFollowing
                      ? OutlinedButton(
                        onPressed:
                            () => _unfollowUser(user.id, user.displayName),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text(
                          'Following',
                          style: TextStyle(fontSize: 12),
                        ),
                      )
                      : requestSent
                      ? OutlinedButton.icon(
                        onPressed:
                            () =>
                                _cancelFollowRequest(user.id, user.displayName),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(Icons.schedule, size: 14),
                        label: const Text(
                          'Pending',
                          style: TextStyle(fontSize: 12),
                        ),
                      )
                      : FilledButton.icon(
                        onPressed:
                            () => _followUser(
                              user.id,
                              user.displayName,
                              user.isPrivate,
                            ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text(
                          'Follow',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingRequestsList(ThemeData theme) {
    if (_isLoadingPending) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child:
          _pendingRequests.isEmpty
              ? _buildEmptyState(
                theme,
                Icons.inbox_outlined,
                'No pending requests',
                'Follow requests will appear here',
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _pendingRequests.length,
                itemBuilder: (context, index) {
                  final request = _pendingRequests[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          request.displayName.isNotEmpty
                              ? request.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        request.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '@${request.username}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            color: theme.colorScheme.error,
                            onPressed:
                                () => _rejectFollowRequest(
                                  request.id,
                                  request.displayName,
                                ),
                            tooltip: 'Reject',
                          ),
                          const SizedBox(width: 4),
                          FilledButton(
                            onPressed:
                                () => _acceptFollowRequest(
                                  request.id,
                                  request.displayName,
                                ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            child: const Text('Accept'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildFollowersList(ThemeData theme) {
    if (_isLoadingFollowers) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child:
          _followers.isEmpty
              ? _buildEmptyState(
                theme,
                Icons.people_outline,
                'No followers yet',
                'Users who follow you will appear here',
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _followers.length,
                itemBuilder: (context, index) {
                  final follower = _followers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          follower.displayName.isNotEmpty
                              ? follower.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        follower.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '@${follower.username}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.person_remove,
                          color: theme.colorScheme.error.withOpacity(0.7),
                        ),
                        onPressed:
                            () => _removeFollower(
                              follower.id,
                              follower.displayName,
                            ),
                        tooltip: 'Remove follower',
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildFollowingList(ThemeData theme) {
    if (_isLoadingFollowing) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child:
          _following.isEmpty
              ? _buildEmptyState(
                theme,
                Icons.person_add_outlined,
                'Not following anyone',
                'Search for users to follow',
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _following.length,
                itemBuilder: (context, index) {
                  final user = _following[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        child: Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '@${user.username}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showUnfollowOptions(user),
                        tooltip: 'Options',
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 80,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
