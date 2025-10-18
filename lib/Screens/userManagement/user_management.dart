import 'package:flutter/material.dart';
import 'package:pos/widgets/notification_card.dart';
class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  // Dummy user data for POS
  List<Map<String, String>> users = [
    {
      'name': 'John Doe',
      'role': 'Admin',
      'lastActive': 'Oct 18, 2025',
    },
    {
      'name': 'Jane Smith',
      'role': 'Cashier',
      'lastActive': 'Oct 17, 2025',
    },
    {
      'name': 'Mike Johnson',
      'role': 'Manager',
      'lastActive': 'Oct 16, 2025',
    },
  ];

  // List of available roles
  final List<String> roles = ['Admin', 'Cashier', 'Manager'];

  // Function to show dialog for adding or editing a user
  void _showUserDialog({Map<String, String>? user, int? index}) {
    final nameController = TextEditingController(text: user?['name'] ?? '');
    String? selectedRole = user?['role'] ?? roles[0];
    final isEdit = user != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: Text(
          isEdit ? 'Edit User' : 'Add User',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'User Name',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: InputDecoration(
                hintText: 'Role',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              items: roles.map((role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Text(role, style: TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (value) {
                selectedRole = value;
              },
            ),
          ],
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
              if (nameController.text.isNotEmpty && selectedRole != null) {
                setState(() {
                  final newUser = {
                    'name': nameController.text,
                    'role': selectedRole!,
                    'lastActive': isEdit ? user['lastActive']! : 'Oct 18, 2025',
                  };
                  if (isEdit) {
                    users[index!] = newUser;
                  } else {
                    users.add(newUser);
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'User updated' : 'User added'),
                    backgroundColor: Colors.deepOrangeAccent,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.redAccent,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrangeAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              isEdit ? 'Update' : 'Add',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Function to delete a user
  void _deleteUser(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: Text(
          'Delete User',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        content: Text(
          'Are you sure you want to delete ${users[index]['name']}?',
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
                users.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('User deleted'),
                  backgroundColor: Colors.deepOrangeAccent,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        title: Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.deepOrangeAccent,
        elevation: 0,
      ),
      body: users.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 50, color: Colors.grey[400]),
                  SizedBox(height: 12),
                  Text(
                    'No Users',
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
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return CustomCardWidget(
                  title: user['name']!,
                  subtitle: user['role']!,
                  trailingText: user['lastActive']!,
                  avatarIcon: Icons.person,
                  onAvatarTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tapped: ${user['name']}'),
                        backgroundColor: Colors.deepOrangeAccent,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  onCardTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Selected: ${user['name']}'),
                        backgroundColor: Colors.deepOrangeAccent,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  onEdit: () => _showUserDialog(user: user, index: index),
                  onDelete: () => _deleteUser(index),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUserDialog,
        backgroundColor: Colors.deepOrangeAccent,
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}