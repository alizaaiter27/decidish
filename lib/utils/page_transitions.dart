import 'package:flutter/material.dart';

class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  /// Optional route settings (forwarded to PageRouteBuilder) so that
  /// `ModalRoute.of(context)?.settings.arguments` is available inside
  /// pages built by this route.
  SlidePageRoute({
    required this.page,
    this.direction = SlideDirection.right,
    super.settings,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: const Duration(milliseconds: 300),
         reverseTransitionDuration: const Duration(milliseconds: 300),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           const begin = Offset(1.0, 0.0);
           const end = Offset.zero;
           const curve = Curves.easeInOutCubic;

           var tween = Tween(begin: begin, end: end);
           var offsetAnimation = animation
               .drive(CurveTween(curve: curve))
               .drive(tween);

           return SlideTransition(
             position: offsetAnimation,
             child: FadeTransition(opacity: animation, child: child),
           );
         },
       );
}

enum SlideDirection { left, right, up, down }

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page, super.settings})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      );
}
