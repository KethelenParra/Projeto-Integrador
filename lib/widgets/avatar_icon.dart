import 'package:flutter/material.dart';

class AvatarIcon extends StatelessWidget {
  final double radius;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const AvatarIcon({
    Key? key,
    this.radius = 40.0,
    this.icon = Icons.bug_report,
    this.backgroundColor = const Color(0xFFEAB08A),
    this.iconColor = const Color(0xFF4A4A4A),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Icon(
        icon,
        size: radius,
        color: iconColor,
      ),
    );
  }
}
