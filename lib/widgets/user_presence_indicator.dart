import 'package:flutter/material.dart';

class UserPresenceIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;
  final EdgeInsets? margin;

  const UserPresenceIndicator({
    super.key,
    required this.isOnline,
    this.size = 12,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? Colors.green : Colors.grey,
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 2,
        ),
      ),
    );
  }
}
