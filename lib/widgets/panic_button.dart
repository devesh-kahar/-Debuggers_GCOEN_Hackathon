import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

class PanicButton extends StatefulWidget {
  final VoidCallback onPressed;
  final double size;

  const PanicButton({
    super.key,
    required this.onPressed,
    this.size = 140,
  });

  @override
  State<PanicButton> createState() => _PanicButtonState();
}

class _PanicButtonState extends State<PanicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        HapticFeedback.heavyImpact();
        setState(() => _isPressed = true);
      },
      onLongPressEnd: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onLongPressCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? 0.93 : _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.3),
                  colors: [
                    _isPressed
                        ? AppColors.danger.withAlpha(200)
                        : AppColors.danger,
                    AppColors.danger.withAlpha(200),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.danger.withAlpha(_isPressed ? 120 : 60),
                    blurRadius: 24,
                    spreadRadius: _isPressed ? 6 : 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'SOS',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hold to activate',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
