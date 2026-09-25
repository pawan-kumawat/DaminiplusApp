import 'dart:convert';
import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';

/// Full notification center — real data (board/exam/course/coupon/
/// referral additions + admin offers), fetched per the selected
/// filter chip. Tap marks read (removes the unread dot); swipe
/// deletes for real via the API, so it never reappears on refresh.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  String _filter = 'all';
  List<Map<String, dynamic>> _notifications = [];

  static const List<Map<String, String>> _filters = [
    {'key': 'all', 'label': 'All'},
    {'key': 'important', 'label': 'Important'},
    {'key': 'board', 'label': 'Boards'},
    {'key': 'exam', 'label': 'Exams'},
    {'key': 'otherCourse', 'label': 'Courses'},
    {'key': 'coupon', 'label': 'Coupons'},
    {'key': 'referral', 'label': 'Refer & Earn'},
    {'key': 'offer', 'label': 'Offers'},
  ];

  static const Map<String, IconData> _typeIcons = {
    'board': Icons.account_balance_rounded,
    'exam': Icons.emoji_events_rounded,
    'otherCourse': Icons.school_rounded,
    'coupon': Icons.local_offer_rounded,
    'referral': Icons.card_giftcard_rounded,
    'offer': Icons.campaign_rounded,
    'general': Icons.notifications_rounded,
  };

  static const Map<String, Color> _typeColors = {
    'board': Color(0xFF5B7FFF),
    'exam': Color(0xFFF2A93B),
    'otherCourse': Color(0xFF8B5CF6),
    'coupon': Color(0xFFEF5DA8),
    'referral': Color(0xFF2E9E5B),
    'offer': Color(0xFF2E9E5B),
    'general': Color(0xFF5B7FFF),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await APIService.getApiCaller(
      context: context,
      url: ApiUrls.getNotifications(type: _filter),
      showLoader: false,
    );
    if (!mounted) return;
    if (res != "Error") {
      try {
        final list = jsonDecode(res)['data'] as List<dynamic>? ?? [];
        setState(() => _notifications = list.cast<Map<String, dynamic>>());
      } catch (_) {}
    } else {
      setState(() => _notifications = []);
    }
    setState(() => _isLoading = false);
  }

  void _selectFilter(String key) {
    if (_filter == key) return;
    setState(() => _filter = key);
    _load();
  }

  Future<void> _markRead(Map<String, dynamic> n) async {
    if (n['isRead'] == true) return;
    setState(() => n['isRead'] = true);
    final id = n['_id']?.toString() ?? '';
    if (id.isEmpty) return;
    await APIService.putApiCaller(
      context: context,
      url: ApiUrls.markNotificationRead(id),
      body: const {},
      showLoader: false,
    );
  }

  void _openDetail(Map<String, dynamic> n) {
    _markRead(n);
    final type = n['type']?.toString() ?? 'general';
    final color = _typeColors[type] ?? AppColors.primaryBlue;
    final icon = _typeIcons[type] ?? Icons.notifications_rounded;
    final imageUrl = n['imageUrl']?.toString() ?? '';
    final title = n['title']?.toString() ?? '';
    final message = n['message']?.toString() ?? '';
    final date = DateTime.tryParse(n['createdAt']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: imageUrl.isNotEmpty ? 0.65 : 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              if (imageUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade100),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                          child: Icon(icon, color: color, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                        ),
                      ],
                    ),
                    if (date != null) ...[
                      const SizedBox(height: 6),
                      Text(_relativeTime(date), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 16),
                    Text(message, style: const TextStyle(fontSize: 14.5, color: AppColors.navy, height: 1.5)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _delete(Map<String, dynamic> n) async {
    final id = n['_id']?.toString() ?? '';
    if (id.isEmpty) return false;
    final res = await APIService.deleteApiCaller(
      context: context,
      url: ApiUrls.deleteNotification(id),
      showLoader: false,
    );
    if (res == "Error") return false;
    setState(() => _notifications.removeWhere((e) => e['_id'] == n['_id']));
    return true;
  }

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inDays == 1) return 'Yesterday, ${_timeOfDay(date)}';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _timeOfDay(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // Groups newest-first into Today / Yesterday / This Week / Earlier.
  List<MapEntry<String, List<Map<String, dynamic>>>> _grouped() {
    final today = <Map<String, dynamic>>[];
    final yesterday = <Map<String, dynamic>>[];
    final thisWeek = <Map<String, dynamic>>[];
    final earlier = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (final n in _notifications) {
      final raw = n['createdAt']?.toString() ?? '';
      final date = DateTime.tryParse(raw);
      if (date == null) {
        earlier.add(n);
        continue;
      }
      final diffDays = DateTime(now.year, now.month, now.day)
          .difference(DateTime(date.year, date.month, date.day))
          .inDays;
      if (diffDays <= 0) {
        today.add(n);
      } else if (diffDays == 1) {
        yesterday.add(n);
      } else if (diffDays < 7) {
        thisWeek.add(n);
      } else {
        earlier.add(n);
      }
    }

    final groups = <MapEntry<String, List<Map<String, dynamic>>>>[];
    if (today.isNotEmpty) groups.add(MapEntry('Today', today));
    if (yesterday.isNotEmpty) groups.add(MapEntry('Yesterday', yesterday));
    if (thisWeek.isNotEmpty) groups.add(MapEntry('This Week', thisWeek));
    if (earlier.isNotEmpty) groups.add(MapEntry('Earlier', earlier));
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['isRead'] != true).length;
    final groups = _grouped();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Expanded(
                    child: Text('Notifications', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _filters[i];
                  final selected = _filter == f['key'];
                  return GestureDetector(
                    onTap: () => _selectFilter(f['key']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryBlue : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: selected ? AppColors.primaryBlue : Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (f['key'] == 'all' && unreadCount > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: selected ? Colors.white : Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('$unreadCount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: selected ? AppColors.primaryBlue : Colors.white)),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(f['label']!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.navy)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No notifications here yet.', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: groups.length,
                            itemBuilder: (_, gi) {
                              final group = groups[gi];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                                    child: Text(group.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navy)),
                                  ),
                                  ...group.value.map((n) => _notificationCard(n)),
                                ],
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationCard(Map<String, dynamic> n) {
    final id = n['_id']?.toString() ?? UniqueKey().toString();
    final type = n['type']?.toString() ?? 'general';
    final isRead = n['isRead'] == true;
    final date = DateTime.tryParse(n['createdAt']?.toString() ?? '');
    final color = _typeColors[type] ?? AppColors.primaryBlue;
    final icon = _typeIcons[type] ?? Icons.notifications_rounded;
    final imageUrl = n['imageUrl']?.toString() ?? '';

    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _delete(n),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(height: 2),
            Text('Clear', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => _openDetail(n),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF0F0F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isRead) ...[
                Container(
                  margin: const EdgeInsets.only(top: 20, right: 8),
                  width: 7, height: 7,
                  decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle),
                ),
              ] else
                const SizedBox(width: 15),
              imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 46, height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                          child: Icon(icon, color: color, size: 22),
                        ),
                      ),
                    )
                  : Container(
                      width: 46, height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(23)),
                      child: Icon(icon, color: color, size: 22),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n['title']?.toString() ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy)),
                    const SizedBox(height: 3),
                    Text(
                      n['message']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(date != null ? _relativeTime(date) : '', style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                  if (!isRead) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text('New', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
