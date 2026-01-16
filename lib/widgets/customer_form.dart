import 'package:flutter/material.dart';
import 'package:pos/Services/Controllers/add_customer_controller.dart';
import 'package:pos/widgets/custom_textfield.dart';

class AddCustomerForm extends StatefulWidget {
  final CustomerController controller;
  final VoidCallback onCustomerAdded;

  const AddCustomerForm({
    super.key,
    required this.controller,
    required this.onCustomerAdded,
  });

  @override
  State<AddCustomerForm> createState() => _AddCustomerFormState();
}

class _AddCustomerFormState extends State<AddCustomerForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cellNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  CustomerType _selectedType = CustomerType.regular;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cellNumberController.dispose();
    _emailController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Customer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _nameController,
              hintText: 'Customer Name',
              icon: Icons.person,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _addressController,
              hintText: 'Address',
              icon: Icons.location_on,
              keyboardType: TextInputType.streetAddress,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _cellNumberController,
              hintText: 'Cell Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _emailController,
              hintText: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _discountController,
              hintText: 'Default Discount (%)',
              icon: Icons.percent,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CustomerType>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Customer Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[600]!, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: CustomerType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    type.toString().split('.').last,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // ✅ Gradient Button
            SizedBox(
              width: double.infinity,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(30, 58, 138, 1),
                      Color.fromRGBO(59, 130, 246, 1)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    widget.controller.addCustomer(
                      context,
                      _nameController.text,
                      _addressController.text,
                      _cellNumberController.text,
                      _emailController.text,
                      _selectedType,
                      double.tryParse(_discountController.text) ?? 0.0,
                    );
                    setState(() {
                      _nameController.clear();
                      _addressController.clear();
                      _cellNumberController.clear();
                      _emailController.clear();
                      _discountController.clear();
                      _selectedType = CustomerType.regular;
                    });
                    widget.onCustomerAdded();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, // important for gradient
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Add Customer',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
