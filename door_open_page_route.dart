import 'package:flutter/material.dart';
import 'dart:math' as math;

class DoorOpenPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  DoorOpenPageRoute({required this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            // The new page (child) just fades in
            final fadeInAnimation =
                CurvedAnimation(parent: animation, curve: Curves.easeIn);

            // The old page (secondaryAnimation) does the door opening effect
            final doorAnimation =
                CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn);

            return Stack(
              children: <Widget>[
                // New page fades in
                FadeTransition(
                  opacity: fadeInAnimation,
                  child: child,
                ),
                // Old page splits and opens
                if (secondaryAnimation.status != AnimationStatus.dismissed)
                  _buildDoor(context, doorAnimation),
              ],
            );
          },
        );

  static Widget _buildDoor(BuildContext context, Animation<double> animation) {
    final width = MediaQuery.of(context).size.width;
    // The rotation angle for the 3D effect
    final angle = (animation.value) * (math.pi / 2);
    // The translation to move the doors apart
    final translate = (animation.value) * (width / 2);

    return Row(
      children: [
        // Left Door
        Expanded(
          child: Transform(
            alignment: Alignment.centerRight,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..translate(translate)
              ..rotateY(angle),
            child: Container(color: Theme.of(context).canvasColor),
          ),
        ),
        // Right Door
        Expanded(
          child: Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..translate(-translate)
              ..rotateY(-angle),
            child: Container(color: Theme.of(context).canvasColor),
          ),
        ),
      ],
    );
  }
}