import 'package:flutter/material.dart';

class CollapsibleCardWidget extends StatelessWidget {
  final String id;
  final String title;
  final Widget leadingIcon;
  final Widget? trailingBadge;
  final List<Widget> expandedChildren;
  final Color accent;

  const CollapsibleCardWidget({
    super.key,
    required this.id,
    required this.title,
    required this.leadingIcon,
    this.trailingBadge,
    required this.expandedChildren,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey[300]!.withOpacity(0.5)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // Remove divider lines
        ),
        child: ExpansionTile(
          leading: leadingIcon,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (trailingBadge != null) trailingBadge!,
            ],
          ),
          trailing: Icon(Icons.expand_more, color:  Color(0xFF253746), size: 24),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: expandedChildren,
              ),
            ),
          ],
        ),
      ),
    );
  }
}