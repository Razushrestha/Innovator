import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innovator/screens/chatApp/controller/chat_controller.dart';
import 'package:lottie/lottie.dart';
import 'dart:developer' as developer;

class OptimizedChatHomePage extends GetView<FireChatController> {
  const OptimizedChatHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCurrentUserCard(),
          Expanded(child: _buildUsersList()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Chat App',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white, size: 24),
          onPressed: () => Get.toNamed('/search'),
          tooltip: 'Search Users',
        ),
        Obx(() => IconButton(
          icon: Icon(
            controller.isDarkMode.value ? Icons.light_mode : Icons.dark_mode,
            color: Colors.white,
            size: 24,
          ),
          onPressed: controller.toggleTheme,
          tooltip: 'Toggle Theme',
        )),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'logout') {
              _showLogoutDialog();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentUserCard() {
    return Obx(() {
      final user = controller.currentUser.value;
      if (user == null) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromRGBO(244, 135, 6, 1),
              const Color.fromRGBO(244, 135, 6, 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(244, 135, 6, 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'current_user_avatar',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  backgroundImage: user['photoURL'] != null && user['photoURL'].isNotEmpty
                      ? NetworkImage(user['photoURL'])
                      : null,
                  child: user['photoURL'] == null || user['photoURL'].isEmpty
                      ? Text(
                          user['name']?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            color: Color.fromRGBO(244, 135, 6, 1),
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Online',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.verified_user,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildUsersList() {
    return Obx(() {
      if (controller.isLoadingUsers.value && controller.allUsers.isEmpty) {
        return _buildLoadingState();
      }

      if (controller.allUsers.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () async {
          await controller.loadAllUsers();
        },
        color: const Color.fromRGBO(244, 135, 6, 1),
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: controller.allUsers.length,
          itemBuilder: (context, index) {
            final user = controller.allUsers[index];
            return _buildUserCard(user, index);
          },
        ),
      );
    });
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    final isOnline = user['isOnline'] ?? false;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => controller.navigateToChat(user),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Get.theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildUserAvatar(user, isOnline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name'] ?? 'Unknown User',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Get.theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isOnline
                                  ? 'Online'
                                  : 'Last seen ${controller.formatLastSeen(user['lastSeen'])}',
                              style: TextStyle(
                                color: isOnline ? Colors.green : Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(244, 135, 6, 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          color: Color.fromRGBO(244, 135, 6, 1),
                          size: 20,
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
          tag: 'user_avatar_${user['id']}',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isOnline ? Colors.green : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
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
                        fontSize: 20,
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
            width: 12,
            height: 12,
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie.asset(
          //   'animation/loading.json', // Add a loading animation
          //   width: 100,
          //   height: 100,
          //   fit: BoxFit.contain,
          // ),
          const SizedBox(height: 16),
          Text(
            'Loading users...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie.asset(
          //   'animation/empty_state.json', // Add an empty state animation
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
            'Pull down to refresh or search for users',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.search),
            label: const Text('Search Users'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Obx(() {
      return AnimatedScale(
        scale: controller.fabScale.value,
        duration: const Duration(milliseconds: 150),
        child: FloatingActionButton(
          onPressed: () => Get.toNamed('/search'),
          backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
          elevation: 8,
          child: const Icon(
            Icons.message,
            color: Colors.white,
            size: 24,
          ),
        ),
      );
    });
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.updateUserStatus(false);
              Get.offAllNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}