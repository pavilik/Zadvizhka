import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/simulation.dart';

class RegulatorChart extends StatelessWidget {
  final SimulationResult data;

  const RegulatorChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
          child: Text(
            'Подпитка 50–250 т/ч: регулятор меняет расход, ёмкости реагируют',
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
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
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
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: const TextStyle(fontSize: 10, color: Colors.red),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.3))),
                minX: 0,
                maxX: 120,
                minY: 0,
                maxY: 300,
                lineBarsData: [
                  // Подпитка (левая ось, т/ч)
                  _line(data.time, data.qOut, Colors.red, 'Подпитка (т/ч)'),
                  _constLine(SystemSimulation.qOutMin, Colors.red.withOpacity(0.3)),
                  _constLine(SystemSimulation.qOutMax, Colors.red.withOpacity(0.3)),
                  // Задвижка 2 (левая ось, т/ч)
                  _line(data.time, data.qValve2, Colors.teal, 'Задвижка 2 (т/ч)'),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        String label = '';
                        if (spot.barIndex == 0) label = 'Подпитка';
                        else if (spot.barIndex == 1) label = 'Мин 50 т/ч';
                        else if (spot.barIndex == 2) label = 'Макс 250 т/ч';
                        else if (spot.barIndex == 3) label = 'Задвижка 2';
                        return LineTooltipItem(
                          '$label: ${spot.y.toStringAsFixed(1)} т/ч',
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

  LineChartBarData _constLine(double y, Color color) {
    return LineChartBarData(
      spots: [FlSpot(0, y), FlSpot(120, y)],
      color: color,
      barWidth: 1,
      dashArray: [4, 4],
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final items = [
      _legendItem(Colors.red, 'Подпитка (50–250 т/ч)'),
      _legendItem(Colors.teal, 'Задвижка 2'),
      _legendItem(Colors.red.withOpacity(0.3), 'Границы 50/250 т/ч'),
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
        Container(width: 12, height: 3, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}