import 'package:flutter/material.dart';

class QuickActionCard extends StatelessWidget {
  final String title;
  final num? price;
  final IconData icon;
  final Color color;
  final double cardSize;
  final Function()? onTap;
  final bool showFavorite;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const QuickActionCard({
    super.key,
    required this.title,
    this.price,
    required this.icon,
    required this.color,
    required this.cardSize,
    this.onTap,
    this.showFavorite = false,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          onTap: showFavorite ? onFavoriteToggle : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // ✅ Main icon and text
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: cardSize * 0.35,
                      color: color,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ) ??
                          const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (price != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '\$${price!.toDouble().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: cardSize * 0.1,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              //  Favorite icon (moved to top-left)
              if (showFavorite)
                Positioned(
                  top: 8,
                  right: 8, // ✅ changed from right → left
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.redAccent : Colors.grey,
                    size: cardSize * 0.18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
