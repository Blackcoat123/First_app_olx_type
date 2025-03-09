import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductListPage extends StatefulWidget {
  final String? userLocation; // User's location passed from main.dart

  const ProductListPage({super.key, this.userLocation});

  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Map<String, dynamic>> products = []; // Store the products

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // Fetch products from Firestore and sort them
  Future<void> fetchProducts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .get();

    final allProducts = snapshot.docs.map((doc) => doc.data()).toList();

    // Sort products by location
    setState(() {
      products = sortProductsByLocation(allProducts, widget.userLocation);
    });
  }

  // Sort products by location
  List<Map<String, dynamic>> sortProductsByLocation(
      List<Map<String, dynamic>> products, String? userLocation) {
    if (userLocation == null) return products;

    // Separate products into two lists: matching location and others
    final matchingLocationProducts = products
        .where((product) => product['location'] == userLocation)
        .toList();

    final otherProducts = products
        .where((product) => product['location'] != userLocation)
        .toList();

    // Combine the lists with matching location products first
    return [...matchingLocationProducts, ...otherProducts];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      body: products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: products.length,
        itemBuilder: (ctx, index) {
          final product = products[index];
          return ListTile(
            title: Text(product['name']),
            subtitle: Text('Price: \$${product['price']}'),
            trailing: Text('Location: ${product['location']}'),
          );
        },
      ),
    );
  }
}