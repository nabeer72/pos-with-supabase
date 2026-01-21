
class Supplier {
  int? id;
  String name;
  String contact;
  String lastOrder;
  String? adminId;
  String? supabaseId;
  int isSynced;

  Supplier({
    this.id,
    required this.name,
    required this.contact,
    required this.lastOrder,
    this.adminId,
    this.supabaseId,
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'lastOrder': lastOrder,
      'adminId': adminId,
      'supabase_id': supabaseId,
      'is_synced': isSynced,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      contact: map['contact'] ?? '',
      lastOrder: map['lastOrder'] ?? '',
      adminId: map['adminId'],
      supabaseId: map['supabase_id'],
      isSynced: map['is_synced'] ?? 0,
    );
  }
}
