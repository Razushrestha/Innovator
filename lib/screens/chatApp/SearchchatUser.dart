import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innovator/screens/chatApp/controller/chat_controller.dart';
import 'package:lottie/lottie.dart';

class OptimizedSearchUsersPage extends GetView<FireChatController> {
  const OptimizedSearchUsersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    final FocusNode searchFocusNode = FocusNode();

    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchFocusNode.requestFocus();
    });   

    return Scaffold(
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(searchController, searchFocusNode),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Search Users',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      actions: [
        Obx(() {
          if (controller.searchQuery.value.isNotEmpty) {
            return IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                controller.searchQuery.value = '';
                controller.searchResults.clear();
              },
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildSearchBar(TextEditingController searchController, FocusNode searchFocusNode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Get.theme.cardColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          focusNode: searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Search users by name...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Obx(() {
              if (controller.isSearching.value) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: const Color.fromRGBO(244, 135, 6, 1),
                    ),
                  ),
                );
              }
              return const Icon(
                Icons.search,
                color: Color.fromRGBO(244, 135, 6, 1),
              );
            }),
            suffixIcon: Obx(() {
              if (controller.searchQuery.value.isNotEmpty) {
                return IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade600),
                  onPressed: () {
                    searchController.clear();
                    controller.searchQuery.value = '';
                    controller.searchResults.clear();
                  },
                );
              }
              return const SizedBox.shrink();
            }),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          onChanged: (value) {
            controller.searchQuery.value = value;
          },
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              controller.searchUsers(value.trim());
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Obx(() {
      if (controller.isSearching.value && controller.searchResults.isEmpty) {
        return _buildSearchingState();
      }

      if (controller.searchQuery.value.isEmpty) {
        return _buildInitialState();
      }

      if (controller.searchResults.isEmpty && !controller.isSearching.value) {
        return _buildNoResultsState();
      }

      return _buildResultsList();
    });
  }

  Widget _buildSearchingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie.asset(
          //   'animation/searching.json',
          //   width: 120,
          //   height: 120,
          //   fit: BoxFit.contain,
          // ),
          const SizedBox(height: 16),
          Text(
            'Searching users...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we find users',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie.asset(
          //   'animation/search_initial.json',
          //   width: 150,
          //   height: 150,
          //   fit: BoxFit.contain,
          // ),
          const SizedBox(height: 24),
          Text(
            'Find your friends',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a name to search for users',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(244, 135, 6, 0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Color.fromRGBO(244, 135, 6, 1),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tip: Search by full name for better results',
                  style: TextStyle(
                    color: const Color.fromRGBO(244, 135, 6, 1),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie.asset(
          //   'animation/no_results.json',
          //   width: 150,
          //   height: 150,
          //   fit: BoxFit.contain,
          // ),
          const SizedBox(height: 24),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with a different name',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              controller.searchQuery.value = '';
              controller.searchResults.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: controller.searchResults.length,
      itemBuilder: (context, index) {
        final user = controller.searchResults[index];
        return _buildUserCard(user, index);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    final isOnline = user['isOnline'] ?? false;
    final lastSeen = user['lastSeen'];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => controller.navigateToChat(user),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Get.theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildUserAvatar(user, isOnline),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name'] ?? 'Unknown User',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Get.theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user['email'] ?? '',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isOnline ? Colors.green : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOnline
                                      ? 'Online'
                                      : 'Last seen ${controller.formatLastSeen(lastSeen)}',
                                  style: TextStyle(
                                    color: isOnline ? Colors.green : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(244, 135, 6, 1),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(244, 135, 6, 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => controller.navigateToChat(user),
                            borderRadius: BorderRadius.circular(25),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.message,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserAvatar(Map<String, dynamic> user, bool isOnline) {
    return Stack(
      children: [
        Hero(
          tag: 'search_avatar_${user['id']}',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isOnline ? Colors.green : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
              backgroundImage: user['photoURL'] != null && user['photoURL'].isNotEmpty
                  ? NetworkImage(user['photoURL'])
                  : null,
              child: user['photoURL'] == null || user['photoURL'].isEmpty
                  ? Text(
                      user['name']?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}