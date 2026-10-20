import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/simulation.dart';

class LevelChart extends StatelessWidget {
  final SimulationResult data;

  const LevelChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
          child: Text(
            'Уровни: ручные задвижки НЕ держат диапазон (выход за границы!)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 30,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.3))),
                minX: 0,
                maxX: 120,
                minY: 0,
                maxY: 8,
                lineBarsData: [
                  _line(data.time, data.hEmk, Colors.green, 'Ёмкость'),
                  _line(data.time, data.hChem, Colors.orange, 'Химцех'),
                  _rangeLine(data.time, SystemSimulation.hEmkMin, SystemSimulation.hEmkMax, Colors.green),
                  _rangeLine(data.time, SystemSimulation.hChemMin, SystemSimulation.hChemMax, Colors.orange),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        String label = '';
                        if (spot.barIndex == 0) label = 'Ёмкость';
                        else if (spot.barIndex == 1) label = 'Химцех';
                        else if (spot.barIndex == 2) label = 'Ёмкость min/max';
                        else if (spot.barIndex == 3) label = 'Химцех min/max';
                        return LineTooltipItem(
                          '$label: ${spot.y.toStringAsFixed(2)} м',
                          TextStyle(color: spot.bar.color, fontSize: 11),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildLegend(context),
      ],
    );
  }

  LineChartBarData _line(List<double> time, List<double> values, Color color, String label) {
    final spots = <FlSpot>[];
    for (int i = 0; i < time.length; i += 6) {
      spots.add(FlSpot(time[i] / 60, values[i]));
    }
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  LineChartBarData _rangeLine(List<double> time, double minVal, double maxVal, Color color) {
    final spots = <FlSpot>[
      FlSpot(0, minVal),
      FlSpot(120, minVal),
      FlSpot(120, maxVal),
      FlSpot(0, maxVal),
    ];
    return LineChartBarData(
      spots: spots,
      color: color.withOpacity(0.15),
      barWidth: 0,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.08)),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final items = [
      _legendItem(Colors.green, 'Ёмкость'),
      _legendItem(Colors.orange, 'Химцех'),
      _legendItem(Colors.green.withOpacity(0.2), 'Норма ёмкости'),
      _legendItem(Colors.orange.withOpacity(0.2), 'Норма химцеха'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(spacing: 12, runSpacing: 4, children: items),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}