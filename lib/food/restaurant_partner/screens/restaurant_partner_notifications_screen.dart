// lib/food/restaurant_partner/screens/restaurant_partner_notifications_screen.dart
import 'package:flutter/material.dart';

class RestaurantPartnerNotificationsScreen extends StatefulWidget {
  const RestaurantPartnerNotificationsScreen({super.key});

  @override
  State<RestaurantPartnerNotificationsScreen> createState() =>
      _RestaurantPartnerNotificationsScreenState();
}

class _RestaurantPartnerNotificationsScreenState
    extends State<RestaurantPartnerNotificationsScreen> {

  final List<Map<String,String>> notifications = [
    {
      "title":"New Order",
      "subtitle":"A new food order has been received.",
      "time":"Just now"
    },
    {
      "title":"Settlement",
      "subtitle":"Weekly settlement processed.",
      "time":"Today"
    },
    {
      "title":"Admin Message",
      "subtitle":"Please update your menu.",
      "time":"Yesterday"
    },
    {
      "title":"Menu Approved",
      "subtitle":"Your latest menu changes are approved.",
      "time":"2 days ago"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Restaurant Notifications"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: (){
              setState(() {
                notifications.clear();
              });
            },
          )
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text("No notifications available"),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              itemBuilder: (context,index){
                final item=notifications[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.notifications),
                    ),
                    title: Text(item["title"]!),
                    subtitle: Text(item["subtitle"]!),
                    trailing: Text(item["time"]!),
                  ),
                );
              },
            ),
    );
  }
}
