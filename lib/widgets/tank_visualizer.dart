import 'package:flutter/material.dart';
import '../models/simulation.dart';

class TankVisualizer extends StatelessWidget {
  final SimulationResult data;

  const TankVisualizer({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Use the last data point
    final int last = data.time.length - 1;
    final hEmk = data.hEmk[last];
    final hChem = data.hChem[last];
    final hDea = data.hDea[last];

    final hEmkNorm = (hEmk - SystemSimulation.hEmkMin) /
        (SystemSimulation.hEmkMax - SystemSimulation.hEmkMin);
    final hChemNorm = (hChem - SystemSimulation.hChemMin) /
        (SystemSimulation.hChemMax - SystemSimulation.hChemMin);
    final hDeaNorm = (hDea - SystemSimulation.hDeaMin) /
        (SystemSimulation.hDeaMax - SystemSimulation.hDeaMin);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Title
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

          // Flow arrows at top
          _buildFlowArrows(data, last),
          const SizedBox(height: 20),

          // Three tanks row
          Row(
            children: [
              Expanded(child: _buildTank(context, 'Ёмкость', hEmk, hEmkNorm,
                  SystemSimulation.hEmkMin, SystemSimulation.hEmkMax,
                  Colors.green, Icons.water_drop)),
              const SizedBox(width: 8),
              Expanded(child: _buildTank(context, 'Химцех', hChem, hChemNorm,
                  SystemSimulation.hChemMin, SystemSimulation.hChemMax,
                  Colors.orange, Icons.science)),
              const SizedBox(width: 8),
              Expanded(child: _buildTank(context, 'Деаэратор', hDea, hDeaNorm,
                  SystemSimulation.hDeaMin, SystemSimulation.hDeaMax,
                  Colors.purple, Icons.opacity)),
            ],
          ),
          const SizedBox(height: 24),

          // Legend / status info
          _buildStatusInfo(data, last),
        ],
      ),
    );
  }

  Widget _buildFlowArrows(SimulationResult data, int last) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // First row: Ввод -> З1 -> Ёмкость -> ППН -> ПСВ -> Химцех
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _flowNode('Ввод', data.qIn[last], Colors.blue),
              _flowArrow(),
              _flowNode('З1', data.qZ1[last], Colors.cyan),
              _flowArrow(),
              _flowNode('Ёмкость', null, Colors.green),
              _flowArrow(),
              _flowNode('ППН', data.qPpn[last], Colors.green),
              _flowArrow(),
              _flowNode('ПСВ', data.qPsv[last], Colors.cyan),
              _flowArrow(),
              _flowNode('Химцех', null, Colors.orange),
            ],
          ),
          const SizedBox(height: 8),
          // Second row: Химцех -> НХОВ -> Деаэратор -> Рег2 -> Потребитель
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 60),
              _flowNode('НХОВ', data.qNchov[last], Colors.orange),
              _flowArrow(),
              _flowNode('Деаэратор', null, Colors.purple),
              _flowArrow(),
              _flowNode('Рег2', data.qReg2[last], Colors.brown),
              _flowArrow(),
              _flowNode('Потребитель', data.qOut[last], Colors.red),
              const SizedBox(width: 60),
            ],
          ),
          const SizedBox(height: 8),
          // Third row: Рег1 branch
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _flowNode('Рег1', data.qReg1[last], Colors.pink),
              _flowArrow(),
              const Text('→ в Деаэратор',
                  style: TextStyle(fontSize: 11, color: Colors.pink)),
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
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
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
    BuildContext context,
    String name,
    double level,
    double levelNorm,
    double minLevel,
    double maxLevel,
    Color color,
    IconData icon,
  ) {
    final levelClamped = levelNorm.clamp(0.0, 1.0);
    final isOver = level > maxLevel;
    final isUnder = level < minLevel;
    final statusColor = isOver
        ? Colors.red
        : isUnder
            ? Colors.amber
            : color;

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
          // Tank name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Tank body
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: const Size(double.infinity, 140),
              painter: _TankPainter(
                level: levelClamped,
                color: color,
                isOver: isOver,
                isUnder: isUnder,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Level value
          Text(
            '${level.toStringAsFixed(2)} м',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          // Range
          Text(
            'норма: ${minLevel.toStringAsFixed(1)}-${maxLevel.toStringAsFixed(1)} м',
            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
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
      issues.add('Ёмкость переполнена (${data.hEmk[last].toStringAsFixed(2)} м)');
    }
    if (data.hEmk[last] < SystemSimulation.hEmkMin) {
      issues.add('Ёмкость почти пуста (${data.hEmk[last].toStringAsFixed(2)} м)');
    }
    if (data.hChem[last] > SystemSimulation.hChemMax) {
      issues.add('Химцех переполнен (${data.hChem[last].toStringAsFixed(2)} м)');
    }
    if (data.hChem[last] < SystemSimulation.hChemMin) {
      issues.add('Химцех почти пуст (${data.hChem[last].toStringAsFixed(2)} м)');
    }
    if (data.hDea[last] > SystemSimulation.hDeaMax) {
      issues.add('Деаэратор переполнен (${data.hDea[last].toStringAsFixed(2)} м)');
    }
    if (data.hDea[last] < SystemSimulation.hDeaMin) {
      issues.add('Деаэратор почти пуст (${data.hDea[last].toStringAsFixed(2)} м)');
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          ...issues.map((issue) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Icon(
                      issue.contains('норме')
                          ? Icons.check_circle
                          : Icons.warning_amber,
                      size: 14,
                      color: issue.contains('норме')
                          ? Colors.green
                          : Colors.amber,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        issue,
                        style: TextStyle(
                          fontSize: 11,
                          color: issue.contains('норме')
                              ? Colors.green[300]
                              : Colors.amber[200],
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
    final paint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
      const Radius.circular(6),
    );

    // Draw tank outline
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
        ..color = color.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(waterRect, waterPaint);

      // Water surface line
      final surfacePaint = Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final surfaceY = size.height - 4 - (size.height - 8) * level;
      canvas.drawLine(
        Offset(6, surfaceY),
        Offset(size.width - 6, surfaceY),
        surfacePaint,
      );
    }

    // Draw min/max markers on the right side
    final markerPaint = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Min marker (at bottom)
    final minY = size.height - 4 - (size.height - 8) * 0.1; // ~10% for visual
    canvas.drawLine(
      Offset(size.width - 12, minY),
      Offset(size.width - 4, minY),
      markerPaint,
    );

    // Max marker (at top)
    final maxY = size.height - 4 - (size.height - 8) * 0.9; // ~90% for visual
    canvas.drawLine(
      Offset(size.width - 12, maxY),
      Offset(size.width - 4, maxY),
      markerPaint,
    );

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