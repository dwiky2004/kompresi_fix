import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/theme.dart';

// ─────────────────────────────────────────────
// Bar Chart — Perbandingan Ukuran File
// ─────────────────────────────────────────────
class BarChartWidget extends StatefulWidget {
  final double beforeSize; // dalam KB
  final double afterSize;  // dalam KB
  final String beforeLabel;
  final String afterLabel;

  const BarChartWidget({
    super.key,
    required this.beforeSize,
    required this.afterSize,
    required this.beforeLabel,
    required this.afterLabel,
  });

  @override
  State<BarChartWidget> createState() => _BarChartWidgetState();
}

class _BarChartWidgetState extends State<BarChartWidget> {
  int touchedIndex = -1;

  String _formatKB(double kb) {
    if (kb >= 1024) {
      return '${(kb / 1024).toStringAsFixed(1)} MB';
    }
    return '${kb.toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final maxY = (widget.beforeSize > widget.afterSize
            ? widget.beforeSize
            : widget.afterSize) *
        1.3;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text(
              'Perbandingan Ukuran File',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'Sebelum vs Sesudah Kompresi',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
            ),
          ),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primary.withValues(alpha: 0.85),
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = groupIndex == 0
                          ? widget.beforeLabel
                          : widget.afterLabel;
                      return BarTooltipItem(
                        '$label\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: _formatKB(rod.toY),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    setState(() {
                      if (response == null ||
                          response.spot == null ||
                          event is FlTapUpEvent) {
                        touchedIndex = -1;
                      } else {
                        touchedIndex =
                            response.spot!.touchedBarGroupIndex;
                      }
                    });
                  },
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                    ),
                    left: BorderSide(
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      'Ukuran (KB)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: maxY / 5,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            _formatKB(value),
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        String label;
                        switch (value.toInt()) {
                          case 0:
                            label = 'Sebelum';
                            break;
                          case 1:
                            label = 'Sesudah';
                            break;
                          default:
                            return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMain,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  _buildBarGroup(0, widget.beforeSize, AppColors.primary),
                  _buildBarGroup(1, widget.afterSize, AppTheme.brandSecond),
                ],
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            ),
          ),
          // Legend
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: AppColors.primary, label: 'Sebelum'),
              const SizedBox(width: 20),
              _LegendItem(color: AppTheme.brandSecond, label: 'Sesudah'),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double size, Color color) {
    final isTouched = touchedIndex == x;
    return BarChartGroupData(
      x: x,
      showingTooltipIndicators: isTouched ? [0] : [],
      barRods: [
        BarChartRodData(
          toY: size,
          color: isTouched ? color.withValues(alpha: 0.7) : color,
          width: 44,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: (size > 0 ? size : 100) * 1.3,
            color: color.withValues(alpha: 0.07),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Line Chart — Tren Kualitas PSNR
// ─────────────────────────────────────────────
class LineChartWidget extends StatefulWidget {
  final List<FlSpot> spots;

  const LineChartWidget({
    super.key,
    required this.spots,
  });

  @override
  State<LineChartWidget> createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  List<int> showingTooltipSpots = [];

  double get minY {
    if (widget.spots.isEmpty) return 0;
    return (widget.spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 5)
        .clamp(0, double.infinity);
  }

  double get maxY {
    if (widget.spots.isEmpty) return 60;
    return widget.spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 8;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text(
              'Tren Kualitas PSNR',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'Kualitas citra berdasarkan level kompresi',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
            ),
          ),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        AppColors.primary.withValues(alpha: 0.85),
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          'Q: ${spot.x.toStringAsFixed(0)}%\n',
                          const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: 'PSNR: ${spot.y.toStringAsFixed(2)} dB',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 5,
                  verticalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  getDrawingVerticalLine: (_) => FlLine(
                    color: AppColors.textSecondary.withValues(alpha: 0.07),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                    ),
                    left: BorderSide(
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      'PSNR (dB)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            value.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text(
                      'Kualitas (%)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${value.toInt()}%',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2.5,
                        strokeColor: AppColors.primary,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    spots: widget.spots,
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helper Widget — Legend Item
// ─────────────────────────────────────────────
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
