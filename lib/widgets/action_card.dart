import 'package:flutter/material.dart';
import 'package:pos/widgets/currency_text.dart';

class QuickActionCard extends StatelessWidget {
  final String title;
  final num? price;
  final IconData icon;
  final Color color;
  final double cardSize; // Size of the card (width and height)
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
    // Calculate proportional sizes based on cardSize
    final iconSize = cardSize * 0.35;
    final fontSize = cardSize * 0.12;
    final favoriteIconSize = cardSize * 0.18;
    final priceFontSize = cardSize * 0.1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: cardSize, // Ensure fixed width
        height: cardSize, // Ensure fixed height
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
              // Main icon and text
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: iconSize,
                      color: color,
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: cardSize * 0.8),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis, // Use ellipsis for overflow
                      ),
                    ),
                    if (price != null) ...[
                      const SizedBox(height: 4),
                      CurrencyText(
                        price: price!.toDouble(),
                        style: TextStyle(
                          fontSize: priceFontSize,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Favorite icon (top-right)
              if (showFavorite)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.redAccent : Colors.grey,
                    size: favoriteIconSize,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}