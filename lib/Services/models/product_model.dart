import 'package:flutter/material.dart';

class Product {
  final int? id;
  final String name;
  final String? barcode;
  final double price;
  final String category;
  final IconData icon;
  final int quantity;
  final int? color;
  final String? supabaseId;
  final bool isSynced;
  final bool isFavorite;
  final double purchasePrice; // New field

  Product({
    this.id,
    required this.name,
    this.barcode,
    required this.price,
    required this.category,
    required this.icon,
    this.quantity = 0,
    this.color,
    this.supabaseId,
    this.isSynced = false,
    this.isFavorite = false,
    this.purchasePrice = 0.0, // Default
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'price': price,
      'category': category,
      'icon': icon.codePoint,
      'quantity': quantity,
      'color': color,
      'supabase_id': supabaseId,
      'is_synced': isSynced ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'purchasePrice': purchasePrice,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'],
      price: map['price'],
      category: map['category'],
      icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
      quantity: map['quantity'] ?? 0,
      color: map['color'],
      supabaseId: map['supabase_id'],
      isSynced: map['is_synced'] == 1,
      isFavorite: map['is_favorite'] == 1,
      purchasePrice: map['purchasePrice'] != null ? (map['purchasePrice'] as num).toDouble() : 0.0,
    );
  }
}
