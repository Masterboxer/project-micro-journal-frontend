import 'package:flutter/material.dart';
import 'package:project_micro_journal/buddies/service/buddies_service.dart';
import '../models/buddy.dart';
import '../models/buddy_request.dart';
import '../models/user_search_result.dart';

class BuddiesPage extends StatefulWidget {
  const BuddiesPage({super.key});

  @override
  State<BuddiesPage> createState() => _BuddiesPageState();
}

class _BuddiesPageState extends State<BuddiesPage>
    with SingleTickerProviderStateMixin {
  final BuddiesService _buddiesService = BuddiesService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;

  List<Buddy> _buddies = [];
  List<BuddyRequest> _receivedRequests = [];
  List<BuddyRequest> _sentRequests = [];
  List<UserSearchResult> _searchResults = [];

  bool _isSearching = false;
  bool _isLoadingBuddies = false;
  bool _isLoadingReceived = false;
  bool _isLoadingSent = false;

  int _receivedRequestCount = 0;

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
      _loadBuddies(),
      _loadReceivedRequests(),
      _loadSentRequests(),
    ]);
  }

  Future<void> _loadBuddies() async {
    setState(() => _isLoadingBuddies = true);
    try {
      final buddies = await _buddiesService.getBuddies();
      if (mounted) {
        setState(() {
          _buddies = buddies;
          _isLoadingBuddies = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _buddies = [];
          _isLoadingBuddies = false;
        });
      }
    }
  }

  Future<void> _loadReceivedRequests() async {
    setState(() => _isLoadingReceived = true);
    try {
      final requests = await _buddiesService.getReceivedRequests();
      if (mounted) {
        setState(() {
          _receivedRequests = requests;
          _receivedRequestCount = requests.length;
          _isLoadingReceived = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _receivedRequests = [];
          _receivedRequestCount = 0;
          _isLoadingReceived = false;
        });
      }
    }
  }

  Future<void> _loadSentRequests() async {
    setState(() => _isLoadingSent = true);
    try {
      final requests = await _buddiesService.getSentRequests();
      if (mounted) {
        setState(() {
          _sentRequests = requests;
          _isLoadingSent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sentRequests = [];
          _isLoadingSent = false;
        });
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
      final results = await _buddiesService.searchUsers(query);
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

  Future<void> _sendBuddyRequest(int userId, String displayName) async {
    try {
      await _buddiesService.sendBuddyRequest(userId);
      if (mounted) {
        _showSnackBar('Buddy request sent to $displayName');
        _searchController.clear();
        setState(() {
          _searchResults = [];
        });
        await _loadSentRequests();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to send request: $e', isError: true);
      }
    }
  }

  Future<void> _acceptRequest(int requestId, String displayName) async {
    try {
      await _buddiesService.acceptBuddyRequest(requestId);
      if (mounted) {
        _showSnackBar('$displayName is now your buddy!');
        await _loadAllData();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to accept request: $e', isError: true);
      }
    }
  }

  Future<void> _rejectRequest(int requestId, String displayName) async {
    try {
      await _buddiesService.rejectBuddyRequest(requestId);
      if (mounted) {
        _showSnackBar('Request from $displayName rejected');
        await _loadReceivedRequests();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to reject request: $e', isError: true);
      }
    }
  }

  Future<void> _cancelRequest(int requestId, String displayName) async {
    try {
      await _buddiesService.cancelBuddyRequest(requestId);
      if (mounted) {
        _showSnackBar('Request to $displayName cancelled');
        await _loadSentRequests();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to cancel request: $e', isError: true);
      }
    }
  }

  Future<void> _removeBuddy(int buddyId, String displayName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Buddy'),
            content: Text('Remove $displayName from your buddies?'),
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
        await _buddiesService.removeBuddy(buddyId);
        if (mounted) {
          _showSnackBar('$displayName removed from buddies');
          await _loadBuddies();
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Failed to remove buddy: $e', isError: true);
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
        title: const Text('Buddies'),
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
                tabs: [
                  const Tab(text: 'Buddies'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Requests'),
                        if (_receivedRequestCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_receivedRequestCount',
                              style: TextStyle(
                                color: theme.colorScheme.onError,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Sent'),
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
                  _buildBuddiesList(theme),
                  _buildReceivedRequestsList(theme),
                  _buildSentRequestsList(theme),
                ],
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
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final isBuddy = _buddies.any((b) => b.id == user.id);
        final hasSentRequest = _sentRequests.any((r) => r.userId == user.id);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          title: Text(user.displayName),
          subtitle: Text('@${user.username}'),
          trailing:
              isBuddy
                  ? Chip(
                    label: const Text('Buddy'),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                  )
                  : hasSentRequest
                  ? Chip(
                    label: const Text('Pending'),
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                  )
                  : FilledButton.icon(
                    onPressed:
                        () => _sendBuddyRequest(user.id, user.displayName),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add'),
                  ),
        );
      },
    );
  }

  Widget _buildBuddiesList(ThemeData theme) {
    if (_isLoadingBuddies) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadBuddies,
      child:
          _buddies.isEmpty
              ? _buildEmptyState(
                theme,
                Icons.people_outline,
                'No buddies yet',
                'Search for users to add as buddies',
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _buddies.length,
                itemBuilder: (context, index) {
                  final buddy = _buddies[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          buddy.displayName.isNotEmpty
                              ? buddy.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        buddy.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('@${buddy.username}'),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.person_remove,
                          color: theme.colorScheme.error.withOpacity(0.7),
                        ),
                        onPressed:
                            () => _removeBuddy(buddy.id, buddy.displayName),
                        tooltip: 'Remove buddy',
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildReceivedRequestsList(ThemeData theme) {
    if (_isLoadingReceived) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadReceivedRequests,
      child:
          _receivedRequests.isEmpty
              ? _buildEmptyState(
                theme,
                Icons.inbox,
                'No pending requests',
                'Requests from others will appear here',
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _receivedRequests.length,
                itemBuilder: (context, index) {
                  final request = _receivedRequests[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
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
                      ),
                      subtitle: Text('@${request.username}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: theme.colorScheme.error,
                            ),
                            onPressed:
                                () => _rejectRequest(
                                  request.id,
                                  request.displayName,
                                ),
                            tooltip: 'Reject',
                          ),
                          const SizedBox(width: 4),
                          FilledButton(
                            onPressed:
                                () => _acceptRequest(
                                  request.id,
                                  request.displayName,
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

  Widget _buildSentRequestsList(ThemeData theme) {
    if (_isLoadingSent) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadSentRequests,
      child:
          _sentRequests.isEmpty
              ? _buildEmptyState(
                theme,
                Icons.send,
                'No sent requests',
                'Requests you send will appear here',
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _sentRequests.length,
                itemBuilder: (context, index) {
                  final request = _sentRequests[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
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
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('@${request.username}'),
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(request.status.toUpperCase()),
                            backgroundColor: _getStatusColor(
                              theme,
                              request.status,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      trailing:
                          request.status == 'pending'
                              ? TextButton(
                                onPressed:
                                    () => _cancelRequest(
                                      request.id,
                                      request.displayName,
                                    ),
                                child: const Text('Cancel'),
                              )
                              : null,
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

  Color _getStatusColor(ThemeData theme, String status) {
    switch (status) {
      case 'pending':
        return theme.colorScheme.tertiaryContainer;
      case 'accepted':
        return theme.colorScheme.primaryContainer;
      case 'rejected':
        return theme.colorScheme.errorContainer;
      default:
        return theme.colorScheme.surfaceVariant;
    }
  }
}
