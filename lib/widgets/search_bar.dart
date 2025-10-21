
import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final Function(String)? onSearchChanged;

  const SearchBarWidget({
    super.key,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: TextField(
        style: Theme.of(context).textTheme.bodySmall,
        decoration: InputDecoration(
          hintText: 'Search transactions or customers...',
          prefixIcon: const Icon(
            Icons.search,
            color: Colors.grey,
            size: 20,
          ),
          hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ),
        ),
        onChanged: (value) => onSearchChanged?.call(value),
      ),
    );
  }
}
