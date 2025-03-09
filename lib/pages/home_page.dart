import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:kuchbhi/pages/add_item_page.dart';
import 'package:kuchbhi/pages/item_info_page.dart';
import 'package:kuchbhi/pages/myads_page.dart';
import 'package:kuchbhi/pages/profile_page.dart';
import 'package:kuchbhi/pages/users.dart';
import 'package:kuchbhi/screens/chat.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:kuchbhi/widgets/chat_messages.dart';
import 'package:badges/badges.dart' as badges; // For the notification badge

import '../services/notification.dart';
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String userId;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      userId = user.uid;
    } else {
      userId = '';
    }
  }

  List<Widget> get _pages {
    return [
      HomeContent(),
      UsersPage(),
      AddItemPage(userId: userId),
      MyAdsPage(userId: userId),
      ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.white),
            SizedBox(width: 5),
            Text("Your Address", style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          // Notification Icon with Unread Count Badge
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .doc(userId)
                .collection('userNotifications')
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationsPage(),
                      ),
                    );
                  },
                );
              }

              final unreadCount = snapshot.data?.docs.length ?? 0;

              return badges.Badge(
                showBadge: unreadCount > 0,
                badgeContent: Text(
                  '$unreadCount',
                  style: TextStyle(color: Colors.white),
                ),
                child: IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationsPage(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: "Sell"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "My Ads"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search",
              prefixIcon: Icon(Icons.search, color: Colors.white),
              hintStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white),
              ),
              filled: true,
              fillColor: Colors.blueGrey.shade700.withOpacity(0.5),
            ),
            style: TextStyle(color: Colors.white),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('items').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: Colors.white));
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error fetching data", style: TextStyle(color: Colors.white)));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("No items found", style: TextStyle(color: Colors.white)));
              }

              final filteredItems = snapshot.data!.docs.where((doc) {
                final itemData = doc.data() as Map<String, dynamic>;
                final title = itemData['title'] ?? '';
                return title.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

              if (filteredItems.isEmpty) {
                return Center(child: Text("No items found", style: TextStyle(color: Colors.white)));
              }

              return ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  final itemData = item.data() as Map<String, dynamic>;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemSellerInfoPage(
                            itemData: itemData,
                            sellerUserId: itemData['userId'] ?? '',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: MediaQuery.of(context).size.height / 1.8,
                      margin: EdgeInsets.all(8.0),
                      child: Card(
                        color: Colors.blueGrey.shade800.withOpacity(0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        child: Column(
                          children: [
                            Container(
                              height: MediaQuery.of(context).size.height / 3,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                                image: DecorationImage(
                                  image: itemData['imageBase64'] != null
                                      ? MemoryImage(base64Decode(itemData['imageBase64']))
                                      : NetworkImage('https://via.placeholder.com/400') as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  "Title: ${itemData['title'] ?? 'N/A'}",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "Description: ${itemData['description1'] ?? 'N/A'}",
                                          style: TextStyle(fontSize: 16, color: Colors.white),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Price: \$${itemData['price'] ?? 'N/A'}",
                                        style: TextStyle(fontSize: 18, color: Colors.white),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Location: ${itemData['location'] ?? 'N/A'}",
                                        style: TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class ItemSellerInfoPage extends StatelessWidget {
  final Map<String, dynamic> itemData;
  final String sellerUserId;

  const ItemSellerInfoPage({required this.itemData, required this.sellerUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Item and Seller Info", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black54,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blueGrey.shade900,
              Colors.blueGrey.shade700,
              Colors.blueGrey.shade500,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImagePage(imageData: itemData['imageBase64']),
                            ),
                          );
                        },
                        child: Hero(
                          tag: "itemImage",
                          child: Container(
                            height: MediaQuery.of(context).size.height / 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              image: DecorationImage(
                                image: itemData['imageBase64'] != null
                                    ? MemoryImage(base64Decode(itemData['imageBase64']))
                                    : NetworkImage('https://via.placeholder.com/300') as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Title: ${itemData['title'] ?? 'N/A'}",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(sellerUserId)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator(color: Colors.white);
                          }

                          if (snapshot.hasError) {
                            return Text("Error loading seller info", style: TextStyle(color: Colors.white));
                          }

                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return Text("Seller information not found", style: TextStyle(color: Colors.white));
                          }

                          final sellerData = snapshot.data!.data() as Map<String, dynamic>;

                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(sellerData['profileImage'] ?? 'https://via.placeholder.com/100'),
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sellerData['name'] ?? 'Unknown Seller',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  Row(
                                    children: List.generate(5, (index) => Icon(Icons.star, color: Colors.amber, size: 18)),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Description 1: ${itemData['description1'] ?? 'N/A'}",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Description 2: ${itemData['description2'] ?? 'N/A'}",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Price: \$${itemData['price'] ?? 'N/A'}",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Location: ${itemData['location'] ?? 'N/A'}",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 16,
                right: 16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (sellerUserId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatMessages(otherUserId: sellerUserId),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Seller information not available")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.black.withOpacity(0.8),
                    shadowColor: Colors.black.withOpacity(0.5),
                    elevation: 8,
                  ),
                  child: Text(
                    "Chat with Seller",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String? imageData;

  const FullScreenImagePage({this.imageData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: Hero(
            tag: "itemImage",
            child: imageData != null
                ? Image.memory(base64Decode(imageData!), fit: BoxFit.contain)
                : Image.network('https://via.placeholder.com/300', fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}