import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // List notifikasi dummy
  final List<NotificationItem> _notifications = [
    NotificationItem(
      title: "Pesanan Diterima",
      message: "Paket Anda telah diterima. Terima kasih telah berbelanja!",
      time: "Baru saja",
      icon: Icons.check_circle,
      color: Colors.green,
      isUnread: true,
    ),
    NotificationItem(
      title: "Pesanan Dikirim",
      message:
          "Sepatu Nike Air Max sedang dalam pengiriman. Estimasi tiba 2 hari lagi.",
      time: "10 menit yang lalu",
      icon: Icons.local_shipping,
      color: Colors.blue,
      isUnread: true,
    ),
    NotificationItem(
      title: "Pembayaran Berhasil",
      message:
          "Pembayaran untuk pesanan #12345 berhasil. Pesanan segera diproses.",
      time: "1 jam yang lalu",
      icon: Icons.payment,
      color: Colors.purple,
      isUnread: false,
    ),
    NotificationItem(
      title: "Flash Sale!",
      message:
          "Jangan lewatkan! Flash sale dimulai hari ini pukul 12.00 untuk produk elektronik.",
      time: "3 jam yang lalu",
      icon: Icons.flash_on,
      color: Colors.orange,
      isUnread: false,
    ),
    NotificationItem(
      title: "Ulasan Produk",
      message:
          "Bagaimana kualitas Headphone Bluetooth yang Anda beli? Berikan ulasan sekarang.",
      time: "6 jam yang lalu",
      icon: Icons.star,
      color: Colors.amber,
      isUnread: false,
    ),
    NotificationItem(
      title: "Kupon Diskon",
      message:
          "Selamat! Anda mendapatkan kupon diskon 15% untuk pembelian berikutnya.",
      time: "1 hari yang lalu",
      icon: Icons.card_giftcard,
      color: Colors.red,
      isUnread: false,
    ),
    NotificationItem(
      title: "Stok Tersedia",
      message:
          "iPhone 15 yang Anda tandai kini tersedia! Segera checkout sebelum kehabisan.",
      time: "1 hari yang lalu",
      icon: Icons.inventory,
      color: Colors.teal,
      isUnread: false,
    ),
    NotificationItem(
      title: "Pengembalian Disetujui",
      message:
          "Pengembalian dana untuk pesanan #54321 telah disetujui dan sedang diproses.",
      time: "2 hari yang lalu",
      icon: Icons.assignment_return,
      color: Colors.indigo,
      isUnread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black54),
            onPressed: () {
              // Settings action
            },
          ),
        ],
      ),
      body:
          _notifications.isEmpty
              ? _buildEmptyNotifications()
              : _buildNotificationsList(),
      // FloatingActionButton removed as requested
    );
  }

  // Widget untuk menampilkan daftar notifikasi
  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  // Widget untuk satu item notifikasi
  Widget _buildNotificationItem(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isUnread ? const Color(0xFFF5F5FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(
              alpha: 26,
            ), // Fixed: withOpacity(0.1) -> withValues(alpha: 26)
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: notification.color.withValues(
            alpha: 51,
          ), // Fixed: withOpacity(0.2) -> withValues(alpha: 51)
          radius: 24,
          child: Icon(notification.icon, color: notification.color, size: 24),
        ),
        title: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isUnread ? FontWeight.bold : FontWeight.w500,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              notification.time,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
        ),
        trailing:
            notification.isUnread
                ? Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4B4ACF),
                    shape: BoxShape.circle,
                  ),
                )
                : null,
        onTap: () {
          // Handle tap on notification
          setState(() {
            notification.isUnread = false;
          });
        },
      ),
    );
  }

  // Widget untuk menampilkan ketika tidak ada notifikasi
  Widget _buildEmptyNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Notification bell with sleeping icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFFEEBE9), // Light pink background
              borderRadius: BorderRadius.circular(60),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    size: 60,
                    color: const Color(0xFF4B4ACF),
                  ),
                  // Sleeping zzz
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Column(
                      children: [
                        Text(
                          'z',
                          style: TextStyle(
                            color: const Color(0xFF4B4ACF),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'z',
                          style: TextStyle(
                            color: const Color(0xFF4B4ACF),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'z',
                          style: TextStyle(
                            color: const Color(0xFF4B4ACF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sleeping face
                  Positioned(
                    bottom: 32,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B4ACF),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: SizedBox(width: 4, height: 4),
                        ),
                        SizedBox(width: 8), // Gunakan SizedBox untuk whitespace
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B4ACF),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: SizedBox(width: 4, height: 4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // All caught up text
          const Text(
            "Semua notifikasi sudah dibaca",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle text
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Kembali lagi nanti untuk melihat update pesanan, promo, dan informasi belanja terbaru",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

// Model untuk item notifikasi
class NotificationItem {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
  bool isUnread;

  NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    this.isUnread = false,
  });
}
