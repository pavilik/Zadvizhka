import 'package:flutter/material.dart';
import '../models/simulation.dart';

class TankVisualizer extends StatelessWidget {
  final SimulationResult data;

  const TankVisualizer({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final int last = data.time.length - 1;
    final hEmk = data.hEmk[last];
    final hChem = data.hChem[last];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Визуализация наполнения ёмкостей',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Текущее состояние системы (t = ${(data.time[last] / 60).toStringAsFixed(0)} мин)',
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),

          // Flow diagram
          _buildFlowDiagram(data, last),
          const SizedBox(height: 20),

          // Two tanks
          Row(
            children: [
              Expanded(child: _buildTank(
                'Ёмкость\n2000 м³', hEmk, SystemSimulation.vEmk,
                SystemSimulation.hEmkMin, SystemSimulation.hEmkMax,
                Colors.green,
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildTank(
                'Бак химцеха\n800 м³', hChem, SystemSimulation.vChem,
                SystemSimulation.hChemMin, SystemSimulation.hChemMax,
                Colors.orange,
              )),
            ],
          ),
          const SizedBox(height: 24),

          // Status info
          _buildStatusInfo(data, last),
        ],
      ),
    );
  }

  Widget _buildFlowDiagram(SimulationResult data, int last) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Row 1: Ввод → Задвижка 1 → Ёмкость
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _flowNode('Ввод', data.qIn[last], Colors.blue),
              _flowArrow(),
              _flowNode('Задв.1', data.qValve1[last], Colors.cyan),
              _flowArrow(),
              _flowNode('Ёмкость', null, Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Ёмкость → Задвижка 2 → Химцех
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 60),
              _flowNode('Задв.2', data.qValve2[last], Colors.teal),
              _flowArrow(),
              _flowNode('Химцех', null, Colors.orange),
            ],
          ),
          const SizedBox(height: 8),
          // Row 3: Химцех → Выход
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 120),
              _flowNode('Выход', data.qOut[last], Colors.red),
              const SizedBox(width: 120),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flowNode(String label, double? value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.4), width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ),
        if (value != null)
          Text(
            '${value.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 10, color: color),
          ),
      ],
    );
  }

  Widget _flowArrow() {
    return const Icon(Icons.arrow_forward, size: 14, color: Colors.white38);
  }

  Widget _buildTank(
    String name,
    double level,
    double maxVolume,
    double minLevel,
    double maxLevel,
    Color color,
  ) {
    final double percent = (level / maxVolume * 100).clamp(0.0, 100.0);
    final bool isOver = level > maxLevel;
    final bool isUnder = level < minLevel;
    final statusColor = isOver ? Colors.red : (isUnder ? Colors.amber : color);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.5),
          width: isOver || isUnder ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          // Tank body
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: const Size(double.infinity, 140),
              painter: _TankPainter(
                level: percent / 100.0,
                color: color,
                isOver: isOver,
                isUnder: isUnder,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Level value
          Text(
            '${level.toStringAsFixed(0)} м³',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: statusColor),
          ),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
          if (isOver)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                'ПЕРЕПОЛНЕНИЕ!',
                style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          if (isUnder)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                'НИЗКИЙ УРОВЕНЬ!',
                style: TextStyle(fontSize: 9, color: Colors.amber, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo(SimulationResult data, int last) {
    final issues = <String>[];

    if (data.hEmk[last] > SystemSimulation.hEmkMax) {
      issues.add('Ёмкость переполнена (${data.hEmk[last].toStringAsFixed(0)} м³)');
    }
    if (data.hEmk[last] < SystemSimulation.hEmkMin) {
      issues.add('Ёмкость почти пуста (${data.hEmk[last].toStringAsFixed(0)} м³)');
    }
    if (data.hChem[last] > SystemSimulation.hChemMax) {
      issues.add('Химцех переполнен (${data.hChem[last].toStringAsFixed(0)} м³)');
    }
    if (data.hChem[last] < SystemSimulation.hChemMin) {
      issues.add('Химцех почти пуст (${data.hChem[last].toStringAsFixed(0)} м³)');
    }

    if (issues.isEmpty) {
      issues.add('Все параметры в норме ✓');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Статус системы:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          ...issues.map((issue) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Icon(
                  issue.contains('норме') ? Icons.check_circle : Icons.warning_amber,
                  size: 14,
                  color: issue.contains('норме') ? Colors.green : Colors.amber,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    issue,
                    style: TextStyle(
                      fontSize: 11,
                      color: issue.contains('норме') ? Colors.green[300] : Colors.amber[200],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _TankPainter extends CustomPainter {
  final double level;
  final Color color;
  final bool isOver;
  final bool isUnder;

  _TankPainter({
    required this.level,
    required this.color,
    required this.isOver,
    required this.isUnder,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
      const Radius.circular(6),
    );

    // Tank outline
    final paint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rect, paint);

    // Draw water
    if (level > 0) {
      final waterRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          4,
          size.height - 4 - (size.height - 8) * level,
          size.width - 8,
          (size.height - 8) * level,
        ),
        const Radius.circular(3),
      );
      final waterPaint = Paint()
        ..color = const Color(0xFF2196F3).withOpacity(0.6)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(waterRect, waterPaint);

      // Water surface line
      final surfacePaint = Paint()
        ..color = const Color(0xFF64B5F6).withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final surfaceY = size.height - 4 - (size.height - 8) * level;
      canvas.drawLine(
        Offset(6, surfaceY),
        Offset(size.width - 6, surfaceY),
        surfacePaint,
      );
    }

    // Warning border
    if (isOver || isUnder) {
      final warnPaint = Paint()
        ..color = isOver ? Colors.red : Colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(rect, warnPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TankPainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.isOver != isOver ||
        oldDelegate.isUnder != isUnder;
  }
}