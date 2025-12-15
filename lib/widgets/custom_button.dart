import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  // Define the gradient once for reuse
  static const LinearGradient _gradient = LinearGradient(
    colors: [
      Color.fromRGBO(30, 58, 138, 1),
      Color.fromRGBO(59, 130, 246, 1),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        backgroundColor: Colors.transparent, // Required to show gradient
        minimumSize: Size(screenWidth * 0.9, 56), // Consistent height
      ),
      child: Ink(
        decoration: const BoxDecoration(
          gradient: _gradient,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Container(
          alignment: Alignment.center,
          constraints: const BoxConstraints(minHeight: 56),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white, // White text looks best on gradient
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}