import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/theme.dart';

class HistogramChartWidget extends StatelessWidget {
  final List<int> original;
  final List<int> compressed;
  final Color channelColor;
  final String channelLabel;

  const HistogramChartWidget({
    super.key,
    required this.original,
    required this.compressed,
    required this.channelColor,
    required this.channelLabel,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate max value for Y-axis normalization
    final int maxVal =
        max(original.reduce(max), compressed.reduce(max)).clamp(1, 1000000);

    // 2. Prepare spots (256 bins)
    final List<FlSpot> originalSpots = [];
    final List<FlSpot> compressedSpots = [];

    for (int i = 0; i < 256; i++) {
      originalSpots.add(FlSpot(i.toDouble(), original[i].toDouble()));
      compressedSpots.add(FlSpot(i.toDouble(), compressed[i].toDouble()));
    }

    return Container(
      height: 240,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Intensitas $channelLabel',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  _buildLegendDot(Colors.grey.shade400, 'Asli'),
                  const SizedBox(width: 12),
                  _buildLegendDot(channelColor, 'Kompresi'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 255,
                minY: 0,
                maxY: maxVal * 1.1,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => AppColors.primary,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          'Level ${spot.x.toInt()}: ${spot.y.toInt()}',
                          const TextStyle(color: Colors.white, fontSize: 10),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == 128 || value == 255) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Plot Asli (Background)
                  LineChartBarData(
                    spots: originalSpots,
                    isCurved: false,
                    color: Colors.grey.withValues(alpha: 0.5), // More visible stroke
                    barWidth: 1.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.grey.withValues(alpha: 0.1), // Subtle fill
                    ),
                  ),
                  // Plot Kompresi (Foreground)
                  LineChartBarData(
                    spots: compressedSpots,
                    isCurved: false,
                    color: channelColor,
                    barWidth: 2, // Thicker line
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: channelColor.withValues(alpha: 0.25), // Stronger interactive fill
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
