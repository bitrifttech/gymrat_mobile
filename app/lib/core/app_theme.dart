import 'package:flutter/material.dart';

/// App bar gradient - soft blue gradient across all screens
class AppBarGradients {
  // Softer, more subtle blue gradient
  static const all = LinearGradient(
    colors: [
      Color(0xFF64B5F6), // soft blue
      Color(0xFF90CAF9), // lighter soft blue
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

/// Helper widget for creating gradient app bars
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.gradient = AppBarGradients.all,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: AppBar(
        title: title,
        actions: actions,
        leading: leading,
        bottom: bottom,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}


