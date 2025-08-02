import 'package:flutter/material.dart';

class HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const HeaderIcon({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((0.15 * 255).toInt()),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withAlpha((0.3 * 255).toInt())),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).toInt()),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
