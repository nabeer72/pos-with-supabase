import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          colors: [
            Color.fromRGBO(30, 58, 138, 1),
            Color.fromRGBO(59, 130, 246, 1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: const SpinKitFadingCircle(
        color: Colors.white, // Required for gradient to apply
        size: 50.0,
      ),
    );
  }
}
