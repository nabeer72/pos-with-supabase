import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/widgets/custom_loader.dart';
import 'package:pos/Services/Controllers/user_controller.dart';
import 'dart:convert';

// COLORS
class AppColors {
  static const Color gradientStart = Color(0xFF1E3A8A);
  static const Color gradientEnd = Color(0xFF3B82F6);
  static const Color background = Color(0xFFF8FAFC);
}

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserController controller = Get.put(UserController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: Get.back,
            ),
            title: const Text(
              'User Management',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: LoadingWidget());
        }

        if (controller.users.isEmpty) {
          return const Center(
            child: Text(
              'No users found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.users.length,
          itemBuilder: (context, index) {
            final user = controller.users[index];
            return _buildUserCard(context, controller, user);
          },
        );
      }),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.gradientStart.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showUserDialog(context, controller),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserController controller, Map<String, dynamic> user) {
    String role = user['role']?.toString() ?? 'Unknown';
    bool isAdmin = role == 'Admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isAdmin ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
          child: Icon(
            Icons.person,
            color: isAdmin ? Colors.orange : AppColors.gradientStart,
          ),
        ),
        title: Text(
          user['name']?.toString() ?? 'No Name',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isAdmin ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                role,
                style: TextStyle(
                  color: isAdmin ? Colors.orange : Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user['email']?.toString() ?? '',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () => _showUserDialog(context, controller, user: user),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deleteUser(context, controller, user),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDialog(BuildContext context, UserController controller, {Map<String, dynamic>? user}) {
    final nameController = TextEditingController(text: user?['name']?.toString() ?? '');
    final emailController = TextEditingController(text: user?['email']?.toString() ?? '');
    final passwordController = TextEditingController(text: user?['password']?.toString() ?? '');
    
    final List<String> roles = ['Admin', 'Manager', 'Cashier'];
    String selectedRole = user?['role']?.toString() ?? roles[2]; // Default to Cashier
    // Ensure selectedRole is valid
    if (!roles.contains(selectedRole)) {
      selectedRole = roles[2]; 
    }

    Map<String, List<String>> roleDefaults = {
      'Admin': ['all'],
      'Manager': ['sales', 'inventory', 'customers', 'suppliers', 'expenses', 'reports', 'analytics', 'purchases', 'loyalty', 'support'],
      'Cashier': ['sales', 'customers', 'reports', 'support'],
    };

    final List<Map<String, String>> permissionOptions = [
      {'key': 'sales', 'label': 'New Sale'},
      {'key': 'inventory', 'label': 'Inventory'},
      {'key': 'customers', 'label': 'Customers'},
      {'key': 'suppliers', 'label': 'Suppliers'},
      {'key': 'expenses', 'label': 'Expenses'},
      {'key': 'reports', 'label': 'Reports'},
      {'key': 'users', 'label': 'User Management'},
      {'key': 'settings', 'label': 'Settings'},
      {'key': 'backup', 'label': 'Backup & Restore'},
      {'key': 'analytics', 'label': 'Analytics'},
      {'key': 'purchases', 'label': 'Purchases'},
      {'key': 'loyalty', 'label': 'Loyalty Program'},
      {'key': 'support', 'label': 'Support'},
    ];

    List<String> selectedPermissions = [];
    if (user != null && user['permissions'] != null) {
      try {
        selectedPermissions = List<String>.from(jsonDecode(user['permissions']));
      } catch (e) {
        selectedPermissions = List.from(roleDefaults[selectedRole] ?? []);
      }
    } else {
      selectedPermissions = List.from(roleDefaults[selectedRole] ?? []);
    }

    bool isEdit = user != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: Text(isEdit ? 'Edit User' : 'Add User'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'User Name',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedRole = value;
                        selectedPermissions = List.from(roleDefaults[value] ?? []);
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView(
                    children: [
                      CheckboxListTile(
                        title: const Text('All Permissions (Admin)', style: TextStyle(fontSize: 14)),
                        value: selectedPermissions.contains('all'),
                        dense: true,
                        activeColor: AppColors.gradientStart,
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedPermissions = ['all'];
                            } else {
                              selectedPermissions = [];
                            }
                          });
                        },
                      ),
                      ...permissionOptions.map((perm) {
                        bool isAll = selectedPermissions.contains('all');
                        return CheckboxListTile(
                          title: Text(perm['label']!, style: const TextStyle(fontSize: 14)),
                          value: isAll || selectedPermissions.contains(perm['key']),
                          dense: true,
                          activeColor: AppColors.gradientStart,
                          onChanged: isAll && perm['key'] != 'all' ? null : (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (!selectedPermissions.contains(perm['key'])) {
                                  selectedPermissions.add(perm['key']!);
                                }
                              } else {
                                selectedPermissions.remove(perm['key']);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final Map<String, dynamic> userData = {
                  'name': nameController.text,
                  'email': emailController.text,
                  'password': passwordController.text,
                  'role': selectedRole,
                  'permissions': jsonEncode(selectedPermissions),
                };

                if (isEdit) {
                  controller.updateUser(user!['id'], userData);
                } else {
                  controller.addUser(userData);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gradientStart,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isEdit ? 'Update' : 'Add', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteUser(BuildContext context, UserController controller, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close dialog first
              Navigator.pop(context);
              // Perform delete
              await controller.deleteUser(user['id'], user['supabase_id']?.toString());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
