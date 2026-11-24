import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/chat_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/chat_provider.dart';

class MessageScreen extends ConsumerStatefulWidget {
  const MessageScreen({super.key});

  @override
  ConsumerState<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends ConsumerState<MessageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final notifState = ref.watch(notificationListProvider);
    final unreadCount = notifState.value?.unreadCount ?? 0;

    if (!authState.isAuthenticated) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Messages & Alerts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: kNavy,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'Sign in required',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please sign in to view your conversations and notifications.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages & Alerts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: kNavy,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryOrange,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: AppColors.primaryOrange,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            const Tab(text: 'Chats'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Notifications'),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Chats
          _buildChatTab(),

          // Tab 2: Notifications
          _buildNotificationTab(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton.extended(
          onPressed: () => _startSupportChat(context),
          backgroundColor: AppColors.primaryOrange,
          icon: const Icon(Icons.support_agent_rounded, color: Colors.white),
          label: const Text(
            'Contact Support',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Future<void> _startSupportChat(BuildContext context) async {
    try {
      final supportConv = await ref.read(conversationsListProvider.notifier).getOrCreateSupport();
      if (context.mounted) {
        _openChatDetail(context, supportConv.id, supportConv.title);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to support: $e')),
        );
      }
    }
  }

  // --- CHAT TAB ---
  Widget _buildChatTab() {
    final conversationsState = ref.watch(conversationsListProvider);

    return conversationsState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Failed to load chats\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(conversationsListProvider.notifier).loadConversations(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
      data: (conversations) {
        if (conversations.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.read(conversationsListProvider.notifier).refresh(),
            child: ListView(
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'No conversations yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Contact Support" below to start chatting!',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(conversationsListProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final chat = conversations[index];
              final bool hasUnread = chat.unreadCount > 0;
              final lastMsgText = chat.lastMessage?.message ?? 'No messages yet';

              return InkWell(
                onTap: () => _openChatDetail(context, chat.id, chat.title),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: AppColors.paleOrange,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            chat.type == 'support' ? Icons.headset_mic_rounded : Icons.storefront_rounded,
                            color: AppColors.primaryOrange,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Name & Message preview
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    chat.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 14,
                                      color: kNavy,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatTime(chat.updatedAt ?? chat.lastMessage?.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: hasUnread ? AppColors.primaryOrange : Colors.grey[500],
                                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    lastMsgText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: hasUnread ? AppColors.darkText : Colors.grey[600],
                                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (hasUnread)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryOrange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${chat.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- NOTIFICATION TAB ---
  Widget _buildNotificationTab() {
    final notifState = ref.watch(notificationListProvider);

    return notifState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Failed to load notifications\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(notificationListProvider.notifier).loadNotifications(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
      data: (response) {
        final notifications = response.notifications;
        if (notifications.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.read(notificationListProvider.notifier).refresh(),
            child: ListView(
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'No notifications yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Updates on your orders and alerts will appear here.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(notificationListProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isUnread = !notif.isRead;
              final iconData = _getNotificationIcon(notif.type, notif.title);
              final iconColor = _getNotificationColor(notif.type);

              return InkWell(
                onTap: () {
                  if (isUnread) {
                    ref.read(notificationListProvider.notifier).markAsRead(notif.id);
                  }
                  _handleNotificationLink(context, notif.link);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUnread ? Colors.orange.withValues(alpha: 0.04) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUnread ? AppColors.primaryOrange.withValues(alpha: 0.3) : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, color: iconColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notif.title,
                                    style: TextStyle(
                                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 14,
                                      color: kNavy,
                                    ),
                                  ),
                                ),
                                if (isUnread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(left: 6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryOrange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Field is `message` not `body`
                            Text(
                              notif.message,
                              style: TextStyle(
                                fontSize: 12,
                                color: isUnread ? AppColors.darkText : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatTime(notif.createdAt),
                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openChatDetail(BuildContext context, String conversationId, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChatDetailSheet(
        conversationId: conversationId,
        title: title,
      ),
    );
  }

  IconData _getNotificationIcon(String? type, String title) {
    final lowerTitle = title.toLowerCase();
    if (type == 'order' || lowerTitle.contains('order') || lowerTitle.contains('delivery')) {
      return Icons.local_shipping_rounded;
    } else if (type == 'payment' || lowerTitle.contains('payment') || lowerTitle.contains('esewa')) {
      return Icons.check_circle_rounded;
    } else if (type == 'discount' || lowerTitle.contains('price') || lowerTitle.contains('sale')) {
      return Icons.local_offer_rounded;
    }
    return Icons.notifications_rounded;
  }

  Color _getNotificationColor(String? type) {
    if (type == 'order') return Colors.blue;
    if (type == 'payment') return Colors.green;
    if (type == 'discount') return AppColors.primaryOrange;
    return AppColors.primaryOrange;
  }

  void _handleNotificationLink(BuildContext context, String? relativeLink) {
    if (relativeLink == null || relativeLink.trim().isEmpty) return;

    String path = relativeLink.trim();
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    if (path.startsWith('account/orders/')) {
      final orderId = path.replaceFirst('account/orders/', '');
      context.push('/orders/$orderId');
    } else if (path.startsWith('orders/')) {
      final orderId = path.replaceFirst('orders/', '');
      context.push('/orders/$orderId');
    } else if (path.startsWith('products/')) {
      final productId = path.replaceFirst('products/', '');
      context.push('/products/$productId');
    } else if (path.startsWith('categories/')) {
      final catId = path.replaceFirst('categories/', '');
      context.push('/categories/$catId');
    } else if (path == 'cart') {
      context.push('/cart');
    } else if (path == 'wishlist') {
      context.push('/wishlist');
    } else {
      try {
        context.push('/$path');
      } catch (_) {}
    }
  }

  static String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24 && dateTime.day == now.day) {
      return DateFormat.jm().format(dateTime);
    } else if (diff.inDays < 7) {
      return DateFormat.E().format(dateTime);
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

// --- CHAT DETAIL SHEET ---
class _ChatDetailSheet extends ConsumerStatefulWidget {
  final String conversationId;
  final String title;

  const _ChatDetailSheet({
    required this.conversationId,
    required this.title,
  });

  @override
  ConsumerState<_ChatDetailSheet> createState() => _ChatDetailSheetState();
}

class _ChatDetailSheetState extends ConsumerState<_ChatDetailSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  File? _selectedImage;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;
    if (_isSending) return;

    final currentUserId = ref.read(authProvider).user?.id ?? '';
    final imageFile = _selectedImage;

    setState(() {
      _textController.clear();
      _selectedImage = null;
      _isSending = true;
    });

    try {
      await ref.read(conversationDetailProvider(widget.conversationId).notifier).sendMessage(
        text: text,
        imageFiles: imageFile != null ? [imageFile] : null,
        currentUserId: currentUserId,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(conversationDetailProvider(widget.conversationId));
    final currentUserId = ref.read(authProvider).user?.id ?? '';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    ref.listen<AsyncValue<Conversation>>(
      conversationDetailProvider(widget.conversationId),
      (previous, next) {
        if (next.hasValue) {
          _scrollToBottom();
        }
      },
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.paleOrange,
                child: Icon(Icons.headset_mic_rounded, color: AppColors.primaryOrange),
              ),
              title: Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: const Text('Online • Support Team', style: TextStyle(color: Colors.green, fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Divider(height: 1),

            // Messages View
            Expanded(
              child: detailState.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryOrange),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $e', style: const TextStyle(color: Colors.red, fontSize: 13)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref.read(conversationDetailProvider(widget.conversationId).notifier).loadDetail(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (conv) {
                  final messages = conv.messages;
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text('No messages yet. Send a message to start!', style: TextStyle(color: Colors.grey)),
                    );
                  }

                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: ListView.builder(
                      controller: _scrollController,
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final bool isMine = (msg.sender?.id != null && msg.sender?.id == currentUserId) ||
                            (msg.sender?.type == 'customer');

                        return Align(
                          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMine ? AppColors.primaryOrange : Colors.grey[100],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMine ? const Radius.circular(16) : Radius.zero,
                                bottomRight: isMine ? Radius.zero : const Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (!isMine && msg.sender?.name != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      msg.sender!.name,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.darkText,
                                      ),
                                    ),
                                  ),

                                // Image attachments (Image URLs are already absolute)
                                if (msg.images.isNotEmpty) ...[
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: msg.images.map((imgUrl) {
                                      final isLocalFile = imgUrl.startsWith('/') || imgUrl.contains('Picker');
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: isLocalFile
                                            ? Image.file(File(imgUrl), width: 150, height: 150, fit: BoxFit.cover)
                                            : CachedNetworkImage(
                                                imageUrl: imgUrl,
                                                width: 150,
                                                height: 150,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(
                                                  width: 150,
                                                  height: 150,
                                                  color: Colors.grey[300],
                                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                ),
                                                errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 40),
                                              ),
                                      );
                                    }).toList(),
                                  ),
                                  if (msg.message.isNotEmpty) const SizedBox(height: 6),
                                ],

                                if (msg.message.isNotEmpty)
                                  Text(
                                    msg.message,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isMine ? Colors.white : kNavy,
                                    ),
                                  ),

                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _MessageScreenState._formatTime(msg.createdAt),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isMine ? Colors.white70 : Colors.grey[500],
                                      ),
                                    ),
                                    if (msg.isPending) ...[
                                      const SizedBox(width: 4),
                                      const SizedBox(
                                        width: 8,
                                        height: 8,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // Selected Image preview
            if (_selectedImage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_selectedImage!, width: 50, height: 50, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    const Text('Image attached', style: TextStyle(fontSize: 12, color: kNavy)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => setState(() => _selectedImage = null),
                    ),
                  ],
                ),
              ),

            // Message Input Field Bar
            Container(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 8,
                bottom: 12 + bottomPadding,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined, color: AppColors.primaryOrange),
                    onPressed: _pickImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        fillColor: Colors.grey[100],
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primaryOrange,
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
