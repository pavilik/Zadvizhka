import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/simulation.dart';

class DeaeratorChart extends StatelessWidget {
  final SimulationResult data;

  const DeaeratorChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
          child: Text(
            'Деаэратор: автоматика держит уровень, но упирается в лимит 160 т/ч',
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
                  horizontalInterval: 0.5,
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
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: const TextStyle(fontSize: 10, color: Colors.brown),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.3))),
                minX: 0,
                maxX: 120,
                minY: 0,
                maxY: 3,
                lineBarsData: [
                  // Level (left axis)
                  _line(data.time, data.hDea, Colors.purple, 'Деаэратор (уровень)'),
                  _rangeLine(data.time, SystemSimulation.hDeaMin, SystemSimulation.hDeaMax, Colors.purple),
                  // Regulator flow lines (mapped to right axis: 0-200 т/ч → 0-3 м)
                  _line(data.time, data.qReg1.map((v) => v / 200.0 * 3.0).toList(), Colors.pink, 'Рег 1 (в деаэратор)'),
                  _line(data.time, data.qReg2.map((v) => v / 200.0 * 3.0).toList(), Colors.brown, 'Рег 2 (подпитка)'),
                  // Q_dea_max limit line
                  _constLine(SystemSimulation.qDeaMaxT / 200.0 * 3.0, Colors.pink.withOpacity(0.4)),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        String label = '';
                        if (spot.barIndex == 0) label = 'Деаэратор';
                        else if (spot.barIndex == 1) label = 'Норма деаэратора';
                        else if (spot.barIndex == 2) label = 'Рег 1';
                        else if (spot.barIndex == 3) label = 'Рег 2';
                        else if (spot.barIndex == 4) label = 'Лимит Рег1';
                        String value;
                        if (spot.barIndex <= 1) {
                          value = '${spot.y.toStringAsFixed(2)} м';
                        } else {
                          value = '${(spot.y / 3.0 * 200.0).toStringAsFixed(1)} т/ч';
                        }
                        return LineTooltipItem(
                          '$label: $value',
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
      _legendItem(Colors.purple, 'Деаэратор (уровень)'),
      _legendItem(Colors.purple.withOpacity(0.2), 'Норма деаэратора'),
      _legendItem(Colors.pink, 'Рег 1 (в деаэратор)'),
      _legendItem(Colors.brown, 'Рег 2 (подпитка)'),
      _legendItem(Colors.pink.withOpacity(0.4), 'Рег 1 лимит 160 т/ч'),
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