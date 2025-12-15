import 'package:flutter/material.dart';
import 'package:pos/Services/Controllers/add_customer_controller.dart';
import 'package:pos/widgets/customer_form.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  late CustomerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CustomerController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Add Customer',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(30, 58, 138, 1),
                Color.fromRGBO(59, 130, 246, 1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Form
            AddCustomerForm(
              controller: _controller,
              onCustomerAdded: () {
                setState(() {}); // Refresh the customer list
              },
            ),
            const SizedBox(height: 24),
            // Customer List
            Text(
              'Customers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 12),
            _controller.customers.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No customers added',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _controller.customers.length,
                    itemBuilder: (context, index) {
                      final customer = _controller.customers[index];
                      return Card(
                        color: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(
                            customer.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Type: ${customer.type.toString().split('.').last}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (customer.address != null)
                                Text(
                                  'Address: ${customer.address}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              if (customer.cellNumber != null)
                                Text(
                                  'Cell: ${customer.cellNumber}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              if (customer.email != null)
                                Text(
                                  'Email: ${customer.email}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              Text(
                                'Status: ${customer.isActive ? 'Active' : 'Deactive'}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              customer.isActive ? Icons.toggle_on : Icons.toggle_off,
                              color: customer.isActive ? Colors.green : Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _controller.toggleCustomerStatus(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}