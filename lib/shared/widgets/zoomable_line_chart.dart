import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ZoomableLineChart extends StatefulWidget {
  final List<FlSpot> expenseSpots;
  final List<FlSpot> incomeSpots;
  final List<String> labels;
  final double minY;
  final double maxY;
  final double horizontalInterval;
  final Color incomeColor;
  final Color expenseColor;

  const ZoomableLineChart({
    super.key,
    required this.expenseSpots,
    required this.incomeSpots,
    required this.labels,
    required this.minY,
    required this.maxY,
    required this.horizontalInterval,
    required this.incomeColor,
    required this.expenseColor,
  });

  @override
  State<ZoomableLineChart> createState() => _ZoomableLineChartState();
}

class _ZoomableLineChartState extends State<ZoomableLineChart> {
  double _zoomLevel = 1.0;
  double _baseZoomLevel = 1.0;

  double _panOffset = 0.0;
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double maxLimit = widget.labels.isNotEmpty
        ? widget.labels.length.toDouble() - 1.0
        : 0.0;

    // Minimum base width based on the screen.
    double screenWidth =
        MediaQuery.of(context).size.width - 40; // 20 padding on each side
    if (screenWidth < 100) screenWidth = 300;

    // Give each day a base width of 30 pixels for a comfortable un-zoomed view.
    double baseWidth = widget.labels.length * 30.0;
    if (baseWidth < screenWidth) baseWidth = screenWidth;

    double currentWidth = baseWidth * _zoomLevel;
    
    double minPan = screenWidth - currentWidth;
    if (minPan > 0) minPan = 0;

    if (!_isInitialized) {
      _panOffset = minPan;
      _isInitialized = true;
    }

    return SizedBox(
      height: 180,
      width: double.infinity,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: (details) {
          _baseZoomLevel = _zoomLevel;
        },
        onScaleUpdate: (details) {
          setState(() {
            // 1. Handle Zooming (2 fingers)
            if (details.pointerCount >= 2) {
              double oldZoom = _zoomLevel;
              _zoomLevel = _baseZoomLevel * details.scale;
              if (_zoomLevel < 1.0) _zoomLevel = 1.0;
              if (_zoomLevel > 10.0) _zoomLevel = 10.0;

              // Adjust pan offset so we zoom into the focal point
              if (oldZoom != _zoomLevel) {
                double focalPoint = details.localFocalPoint.dx;
                // The point on the chart that is under the focal point:
                double chartPoint = focalPoint - _panOffset;
                // The new width ratio
                double ratio = _zoomLevel / oldZoom;
                // The new pan offset required to keep the chartPoint under the focalPoint
                _panOffset = focalPoint - (chartPoint * ratio);
              }
            }

            // 2. Handle Panning
            // We add the translation from the focal point
            _panOffset += details.focalPointDelta.dx;

            // 3. Constrain Pan Bounds
            currentWidth = baseWidth * _zoomLevel;
            double minPan = screenWidth - currentWidth;
            if (minPan > 0) minPan = 0; // Chart is smaller than screen

            if (_panOffset > 0) _panOffset = 0; // Lock to left edge
            if (_panOffset < minPan) _panOffset = minPan; // Lock to right edge
          });
        },
        child: ClipRect(
          child: Stack(
            children: [
              Positioned(
                left: _panOffset,
                child: SizedBox(
                  width: currentWidth,
                  height: 180, // Lock height to 180 to prevent vertical scaling
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: maxLimit,
                      clipData: const FlClipData.all(),
                      minY: widget.minY,
                      maxY: widget.maxY,
                      lineTouchData: LineTouchData(
                        enabled: true,
                        handleBuiltInTouches: false,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                spot.y.toStringAsFixed(0),
                                theme.textTheme.labelSmall!.copyWith(
                                  color: theme.colorScheme.surface,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: widget.horizontalInterval,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.1,
                            ),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < widget.labels.length) {
                                double pixelsPerLabel =
                                    currentWidth / widget.labels.length;
                                int step = 1;
                                if (pixelsPerLabel < 15) {
                                  step = 7;
                                } else if (pixelsPerLabel < 30) {
                                  step = 3;
                                } else if (pixelsPerLabel < 50) {
                                  step = 2;
                                }

                                if (index == 0 ||
                                    index == widget.labels.length - 1 ||
                                    index % step == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      widget.labels[index],
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontSize: 10,
                                          ),
                                    ),
                                  );
                                }
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: widget.incomeSpots,
                          isCurved: true,
                          color: widget.incomeColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: widget.incomeColor,
                                strokeWidth: 2,
                                strokeColor: theme.colorScheme.surface,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: widget.incomeColor.withValues(alpha: 0.1),
                          ),
                        ),
                        LineChartBarData(
                          spots: widget.expenseSpots,
                          isCurved: true,
                          color: widget.expenseColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: widget.expenseColor,
                                strokeWidth: 2,
                                strokeColor: theme.colorScheme.surface,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: widget.expenseColor.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
