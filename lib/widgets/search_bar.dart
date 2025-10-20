import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final Function(String)? onSearchChanged;

  const SearchBarWidget({
    super.key,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Get the screen width dynamically using MediaQuery
    final double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth, // Full width of the screen
      constraints: const BoxConstraints(maxWidth: 600), // Max width constraint
      margin: const EdgeInsets.symmetric(horizontal: 16), // Optional: Add margin for padding on sides
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14), // Consistent border radius
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: TextField(
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search transactions or customers...',
          prefixIcon: Icon(Icons.search, color: Colors.grey[700]),
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
        onChanged: (value) => onSearchChanged?.call(value),
      ),
    );
  }
}