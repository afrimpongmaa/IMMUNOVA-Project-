import 'package:flutter/material.dart';
import 'dart:math' as math;

class ImmunizationOverviewWidget extends StatefulWidget {
  final List<ChartData>? chartData;
  final Duration? loadingDuration;
  final Duration? animationDuration;
  final Color? backgroundColor;
  final bool showLoadingAnimation;

  const ImmunizationOverviewWidget({
    Key? key,
    this.chartData,
    this.loadingDuration,
    this.animationDuration,
    this.backgroundColor,
    this.showLoadingAnimation = true,
  }) : super(key: key);

  @override
  State<ImmunizationOverviewWidget> createState() =>
      _ImmunizationOverviewWidgetState();
}

class _ImmunizationOverviewWidgetState extends State<ImmunizationOverviewWidget>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late AnimationController _chartController;
  late Animation<double> _chartAnimation;
  bool _isLoading = true;

  // Default chart data
  List<ChartData> get defaultChartData => [
    ChartData('Completed Schedule', 5, const Color(0xFF4DD0E1), 12.5),
    ChartData('Upcoming Schedule', 25, const Color(0xFF26C6DA), 62.5),
    ChartData('Partially Completed Schedule', 5, const Color(0xFFE91E63), 12.5),
    ChartData('Overdue Immunizations', 5, const Color(0xFF8BC34A), 12.5),
  ];

  List<ChartData> get chartData => widget.chartData ?? defaultChartData;

  @override
  void initState() {
    super.initState();

    _loadingController = AnimationController(
      duration: widget.loadingDuration ?? const Duration(milliseconds: 2000),
      vsync: this,
    );

    _chartController = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 1500),
      vsync: this,
    );

    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartController, curve: Curves.easeOutCubic),
    );

    if (widget.showLoadingAnimation) {
      _loadingController.repeat();

      // Simulate loading time
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _loadingController.stop();
          _chartController.forward();
        }
      });
    } else {
      _isLoading = false;
      _chartController.forward();
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor ?? Colors.grey[50],
      child: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _loadingController.value * 2.0 * math.pi,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 4),
                  ),
                  child: CustomPaint(
                    painter: LoadingPainter(
                      progress: _loadingController.value,
                      color: const Color(0xFF4DD0E1),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading immunization data...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Container
          AnimatedBuilder(
            animation: _chartAnimation,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Title
                    const Text(
                      'Immunization Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Donut Chart
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CustomPaint(
                        painter: DonutChartPainter(
                          data: chartData,
                          animationProgress: _chartAnimation.value,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Legend
                    Column(
                      children: chartData.map((data) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: data.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data.label,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String label;
  final int value;
  final Color color;
  final double percentage;

  ChartData(this.label, this.value, this.color, this.percentage);
}

class DonutChartPainter extends CustomPainter {
  final List<ChartData> data;
  final double animationProgress;

  DonutChartPainter({required this.data, required this.animationProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final innerRadius = radius * 0.6;

    double startAngle = -math.pi / 2; // Start from top

    for (int i = 0; i < data.length; i++) {
      final sweepAngle =
          (data[i].percentage / 100) * 2 * math.pi * animationProgress;

      final paint = Paint()
        ..color = data[i].color
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - innerRadius;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      // Draw value text outside the circle
      if (animationProgress > 0.8) {
        final textAngle = startAngle + sweepAngle / 2;
        final textRadius = radius + 20; // Position outside the circle
        final textOffset = Offset(
          center.dx + textRadius * math.cos(textAngle),
          center.dy + textRadius * math.sin(textAngle),
        );

        final textPainter = TextPainter(
          text: TextSpan(
            text:
                '${data[i].value}\n(${data[i].percentage.toStringAsFixed(1)}%)',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            textOffset.dx - textPainter.width / 2,
            textOffset.dy - textPainter.height / 2,
          ),
        );
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class LoadingPainter extends CustomPainter {
  final double progress;
  final Color color;

  LoadingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
