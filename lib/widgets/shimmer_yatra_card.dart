import 'package:flutter/material.dart';

/// Reusable Shimmer Loader for Yatra Cards
class ShimmerYatraCard extends StatefulWidget {
  final double height;
  final double width;
  final bool isHorizontal;

  const ShimmerYatraCard({
    super.key,
    this.height = 200,
    this.width = double.infinity,
    this.isHorizontal = false,
  });

  @override
  State<ShimmerYatraCard> createState() => _ShimmerYatraCardState();
}

class _ShimmerYatraCardState extends State<ShimmerYatraCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: const EdgeInsets.only(right: 12, bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1332).withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        height: 14,
                        width: widget.width * 0.6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 10,
                        width: widget.width * 0.4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
