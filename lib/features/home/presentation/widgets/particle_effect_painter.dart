import 'package:flutter/material.dart';
import 'dart:math' as math;

class ParticleEffectPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final List<Particle> particles;

  ParticleEffectPainter({
    required this.animation,
    required this.color,
  }) : particles = List.generate(20, (index) => Particle()) {
    animation.addListener(() {
      for (var particle in particles) {
        particle.update(animation.value);
      }
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      final position = particle.position(size);
      canvas.drawCircle(position, particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticleEffectPainter oldDelegate) => true;
}

class Particle {
  late double x;
  late double y;
  late double speed;
  late double radius;
  late double direction;

  Particle() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    speed = 0.2 + math.Random().nextDouble() * 0.3;
    radius = 1 + math.Random().nextDouble() * 2;
    direction = math.Random().nextDouble() * 2 * math.pi;
  }

  void update(double delta) {
    x += math.cos(direction) * speed * delta;
    y += math.sin(direction) * speed * delta;

    if (x < 0 || x > 1 || y < 0 || y > 1) {
      reset();
    }
  }

  Offset position(Size size) {
    return Offset(x * size.width, y * size.height);
  }
}
