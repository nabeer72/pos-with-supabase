import 'package:flutter/material.dart';
import 'package:pos/widgets/notification_card.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Dummy notification data for POS
  List<Map<String, String>> notifications = [
    {
      'title': 'Order #1234',
      'message': 'Order completed for Table 5.',
      'time': '10:30 AM',
    },
    {
      'title': 'Stock Alert',
      'message': 'Coffee Beans stock low (5 units).',
      'time': '9:15 AM',
    },
    {
      'title': 'New User',
      'message': 'Cashier John Doe added.',
      'time': '8:45 AM',
    },
  ];

  // Function to delete a notification
  void _deleteNotification(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: Text(
          'Delete Notification',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        content: Text(
          'Are you sure you want to delete ${notifications[index]['title']} notification?',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                notifications.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Notification deleted'),
                  backgroundColor: Colors.deepOrangeAccent,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(30, 58, 138, 1),
                Color.fromRGBO(59, 130, 246, 1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off,
                      size: 50, color: Colors.grey[400]),
                  SizedBox(height: 12),
                  Text(
                    'No Notifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return CustomCardWidget(
                  title: notification['title']!,
                  subtitle: notification['message']!,
                  trailingText: notification['time']!,
                  avatarIcon: Icons.notifications_active,
                  showEditIcon: false, // Hide edit icon for notifications
                  onAvatarTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Avatar tapped: ${notification['title']}'),
                        backgroundColor: Colors.deepOrangeAccent,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  onCardTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Notification: ${notification['title']}'),
                        backgroundColor: Colors.deepOrangeAccent,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  onEdit: null, // No edit functionality
                  onDelete: () => _deleteNotification(index),
                );
              },
            ),
    );
  }
}
