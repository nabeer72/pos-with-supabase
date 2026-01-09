import 'package:pos/Services/Controllers/add_customer_controller.dart';

class CustomerModel {
  final int? id;
  final String name;
  final String? address;
  final String? cellNumber;
  final String? email;
  final CustomerType type;
  final bool isActive;
  final String? supabaseId;
  final bool isSynced;

  CustomerModel({
    this.id,
    required this.name,
    this.address,
    this.cellNumber,
    this.email,
    required this.type,
    this.isActive = true,
    this.supabaseId,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'cellNumber': cellNumber,
      'email': email,
      'type': type.index,
      'isActive': isActive ? 1 : 0,
      'supabase_id': supabaseId,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      cellNumber: map['cellNumber'],
      email: map['email'],
      type: CustomerType.values[map['type']],
      isActive: map['isActive'] == 1,
      supabaseId: map['supabase_id'],
      isSynced: map['is_synced'] == 1,
    );
  }
}
