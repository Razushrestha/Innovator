import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/Blocked/Blocked_Model.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final AppData _appData = AppData();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<BlockedUser> _allBlockedUsers = [];
  List<BlockedUser> _filteredUsers = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String _searchQuery = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
    _setupScrollListener();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent * 0.8) {
        if (!_isLoadingMore && _hasMore && _searchQuery.isEmpty) {
          _loadMoreUsers();
        }
      }
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
      });
      _filterUsers();
    }
  }

  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredUsers = List.from(_allBlockedUsers);
      });
    } else {
      setState(() {
        _filteredUsers = _allBlockedUsers.where((user) {
          return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 user.email.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      });
    }
  }

  Future<void> _loadBlockedUsers() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 0;
      _allBlockedUsers.clear();
      _filteredUsers.clear();
    });

    try {
      final response = await _appData.fetchBlockedUsers(page: 0, limit: 20);
      
      if (response.status == 200) {
        setState(() {
          _allBlockedUsers = response.blockedUsers;
          _filteredUsers = List.from(_allBlockedUsers);
          _hasMore = response.pagination.hasMore;
          _currentPage = response.pagination.page;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load blocked users';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _appData.fetchBlockedUsers(
        page: _currentPage + 1, 
        limit: 20
      );
      
      if (response.status == 200) {
        setState(() {
          _allBlockedUsers.addAll(response.blockedUsers);
          if (_searchQuery.isEmpty) {
            _filteredUsers = List.from(_allBlockedUsers);
          } else {
            _filterUsers();
          }
          _hasMore = response.pagination.hasMore;
          _currentPage = response.pagination.page;
        });
      }
    } catch (e) {
      developer.log('Error loading more users: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshUsers() async {
    await _loadBlockedUsers();
  }

  Future<void> _unblockUser(BlockedUser user) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Unblock User',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to unblock ${user.name}?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'They will be able to see your posts and contact you again.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performUnblock(user);
    }
  }

  Future<void> _performUnblock(BlockedUser user) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Unblocking user...'),
              ],
            ),
          ),
        ),
      );

      final String? authToken = _appData.authToken;
      if (authToken == null || authToken.isEmpty) {
        Navigator.of(context).pop();
        Get.snackbar(
          'Error',
          'Authentication required',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Prepare request body with userId
      final requestBody = {
        'userId': user.id,
      };

      developer.log('🔓 Unblocking user with data: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('http://182.93.94.210:3066/api/v1/unblock-user'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 30));

      Navigator.of(context).pop(); // Close loading dialog

      developer.log('🔓 Unblock API Response: ${response.statusCode}');
      developer.log('🔓 Unblock API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove user from lists
        setState(() {
          _allBlockedUsers.removeWhere((u) => u.id == user.id);
          _filteredUsers.removeWhere((u) => u.id == user.id);
        });

        Get.snackbar(
          'Success',
          '${user.name} has been unblocked',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          icon: Icon(Icons.check_circle, color: Colors.white),
        );

        developer.log('✅ User unblocked successfully: ${user.name}');
        
      } else if (response.statusCode == 401) {
        // Unauthorized - redirect to login
        Get.snackbar(
          'Error',
          'Authentication failed. Please login again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else if (response.statusCode == 404) {
        // User not found or not blocked
        Get.snackbar(
          'Error',
          'User is not blocked or not found',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        // Handle other error responses
        try {
          final responseData = jsonDecode(response.body);
          final errorMessage = responseData['message'] ?? 'Failed to unblock user';
          
          Get.snackbar(
            'Error',
            errorMessage,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar(
            'Error',
            'Failed to unblock user (${response.statusCode})',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
        
        developer.log('❌ Unblock failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog if open
      
      developer.log('❌ Error unblocking user: $e');
      
      Get.snackbar(
        'Error',
        'Network error. Please check your connection and try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showUserDetails(BlockedUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Blocked User Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                
                Divider(),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User info
                        Row(
                          children: [
                            _buildUserAvatar(user, size: 60),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Block details
                        _buildDetailCard('Block Reason', user.blockReason, Icons.report),
                        _buildDetailCard('Block Type', user.blockType.toUpperCase(), Icons.block),
                        _buildDetailCard('Blocked On', _formatDate(user.blockedAt), Icons.calendar_today),
                        
                        SizedBox(height: 16),
                        
                        // Previous interactions
                        Text(
                          'Previous Interactions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        
                        _buildInteractionTile('Followed Each Other', user.previousInteractions.followedEachOther),
                        _buildInteractionTile('Had Conversations', user.previousInteractions.hadConversations),
                        _buildInteractionTile('Shared Content', user.previousInteractions.sharedContent),
                        
                        SizedBox(height: 24),
                        
                        // Unblock button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _unblockUser(user);
                            },
                            icon: Icon(Icons.person_add),
                            label: Text('Unblock User'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionTile(String title, bool hasInteraction) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            hasInteraction ? Icons.check_circle : Icons.cancel,
            color: hasInteraction ? Colors.green : Colors.red,
            size: 20,
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildUserAvatar(BlockedUser user, {double size = 50}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.orange.shade400],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(2),
        child: user.picture.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: user.fullPictureUrl,
                imageBuilder: (context, imageProvider) => CircleAvatar(
                  backgroundImage: imageProvider,
                  radius: size / 2 - 2,
                ),
                placeholder: (context, url) => CircleAvatar(
                  radius: size / 2 - 2,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => CircleAvatar(
                  radius: size / 2 - 2,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : CircleAvatar(
                radius: size / 2 - 2,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: size * 0.3,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildUserCard(BlockedUser user) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          _buildUserAvatar(user),
          SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.blockReason,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          Column(
            children: [
              IconButton(
                onPressed: () => _showUserDetails(user),
                icon: Icon(Icons.info_outline, color: Colors.blue.shade600),
                tooltip: 'View Details',
              ),
              IconButton(
                onPressed: () => _unblockUser(user),
                icon: Icon(Icons.person_add, color: Colors.green.shade600),
                tooltip: 'Unblock',
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Blocked Users',
          
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color.fromRGBO(244, 135, 6, 1),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
        actions: [
          IconButton(
            onPressed: _refreshUsers,
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search blocked users...',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _filterUsers();
                        },
                        icon: Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade600),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading blocked users...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            SizedBox(height: 16),
            Text(
              'Error loading blocked users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshUsers,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.block,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No users found matching "$_searchQuery"'
                  : 'No blocked users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'You haven\'t blocked anyone yet',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshUsers,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(vertical: 8),
        itemCount: _filteredUsers.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _filteredUsers.length) {
            return _buildUserCard(_filteredUsers[index]);
          } else {
            return Container(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }
}