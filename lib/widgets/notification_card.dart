import 'package:flutter/material.dart';

class CustomCardWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget; // New parameter for flexible subtitles
  final String trailingText;
  final VoidCallback onAvatarTap;
  final VoidCallback onCardTap;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;
  final IconData avatarIcon;
  final bool showEditIcon;

  const CustomCardWidget({
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    required this.trailingText,
    required this.onAvatarTap,
    required this.onCardTap,
    this.onEdit,
    required this.onDelete,
    this.avatarIcon = Icons.person,
    this.showEditIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          leading: GestureDetector(
            onTap: onAvatarTap,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(avatarIcon, color: Color(0xFF253746), size: 24),
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: subtitleWidget ?? (subtitle != null
              ? Text(
                  subtitle!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                )
              : null),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trailingText,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              SizedBox(width: 8),
              if (showEditIcon && onEdit != null)
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                  onPressed: onEdit,
                ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.redAccent, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          onTap: onCardTap,
        ),
      ),
    );
  }
}