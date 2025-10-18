import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final double screenWidth;
  final Function(String)? onSearchChanged;

  const SearchBarWidget({
    super.key,
    required this.screenWidth,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: screenWidth,
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
