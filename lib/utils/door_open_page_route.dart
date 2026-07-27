import 'dart:math' as math;

import 'package:flutter/material.dart';

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
            final fadeInAnimation =
                CurvedAnimation(parent: animation, curve: Curves.easeIn);
            final doorAnimation = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeIn,
            );

            return Stack(
              children: <Widget>[
                FadeTransition(
                  opacity: fadeInAnimation,
                  child: child,
                ),
                if (secondaryAnimation.status != AnimationStatus.dismissed)
                  _buildDoor(context, doorAnimation),
              ],
            );
          },
        );

  static Widget _buildDoor(BuildContext context, Animation<double> animation) {
    final width = MediaQuery.of(context).size.width;
    final angle = animation.value * (math.pi / 2);
    final translate = animation.value * (width / 2);

    return Row(
      children: [
        Expanded(
          child: Transform(
            alignment: Alignment.centerRight,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..translate(translate)
              ..rotateY(angle),
            child: Container(color: Theme.of(context).canvasColor),
          ),
        ),
        Expanded(
          child: Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..translate(-translate)
              ..rotateY(-angle),
            child: Container(color: Theme.of(context).canvasColor),
          ),
        ),
      ],
    );
  }
}
