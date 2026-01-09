class Supplier {
  final int? id;
  final String name;
  final String contact;
  final String lastOrder;
  final String? supabaseId;
  final bool isSynced;

  Supplier({
    this.id,
    required this.name,
    required this.contact,
    required this.lastOrder,
    this.supabaseId,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'lastOrder': lastOrder,
      'supabase_id': supabaseId,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      contact: map['contact'],
      contact: map['contact'],
      lastOrder: map['lastOrder'],
      supabaseId: map['supabase_id'],
      isSynced: map['is_synced'] == 1,
    );
  }
}
