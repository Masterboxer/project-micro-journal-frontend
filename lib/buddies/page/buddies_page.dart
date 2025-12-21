import 'package:flutter/material.dart';
import 'package:project_micro_journal/buddies/service/buddies_service.dart';
import '../models/buddy.dart';
import '../models/user_search_result.dart';

class BuddiesPage extends StatefulWidget {
  const BuddiesPage({super.key});

  @override
  State<BuddiesPage> createState() => _BuddiesPageState();
}

class _BuddiesPageState extends State<BuddiesPage> {
  final BuddiesService _buddiesService = BuddiesService();
  final TextEditingController _searchController = TextEditingController();

  List<Buddy> _buddies = [];
  List<UserSearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadBuddies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBuddies() async {
    try {
      final buddies = await _buddiesService.getBuddies();
      if (mounted) {
        setState(() {
          _buddies = buddies;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _buddies = [];
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    }
  }

  Future<void> _addBuddy(int buddyId, String displayName) async {
    try {
      await _buddiesService.addBuddy(buddyId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$displayName added as buddy!')));
        _searchController.clear();
        _searchResults = [];
        await _loadBuddies();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add buddy: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$displayName removed from buddies')),
          );
          await _loadBuddies();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove buddy: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buddies'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
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
        ),
      ),
      body:
          _searchController.text.isNotEmpty
              ? _buildSearchResults(theme)
              : _buildBuddiesList(theme),
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
                  : FilledButton.icon(
                    onPressed: () => _addBuddy(user.id, user.displayName),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add'),
                  ),
        );
      },
    );
  }

  Widget _buildBuddiesList(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadBuddies,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _buddies.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add Buddies to Connect with those you value!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final buddy = _buddies[index - 1];

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
                onPressed: () => _removeBuddy(buddy.id, buddy.displayName),
                tooltip: 'Remove buddy',
              ),
            ),
          );
        },
      ),
    );
  }
}
