// lib/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:smart_outlet_app/main.dart';  // ← correct package import

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification'),
        backgroundColor: const Color(0xFF0A9B88),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1EBEA5), Color(0xFF0A9B88)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ValueListenableBuilder<List<String>>(
          valueListenable: notifications,
          builder: (context, notificationList, _) {
            if (notificationList.isEmpty) {
              return const Center(
                child: Text(
                  'No notifications at the moment.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: notificationList.length,
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.white.withAlpha(230),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.notification_important,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            notificationList[index],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
