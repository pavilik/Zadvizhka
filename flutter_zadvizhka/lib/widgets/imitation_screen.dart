import 'package:flutter/material.dart';
import '../models/imitation_model.dart';

class ImitationScreen extends StatefulWidget {
  const ImitationScreen({super.key});

  @override
  State<ImitationScreen> createState() => _ImitationScreenState();
}

class _ImitationScreenState extends State<ImitationScreen> {
  final ImitationModel _model = ImitationModel();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _model,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Title
              const Text(
                'Имитация системы водоподготовки',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Мгновенная визуализация — двигайте ручки, чтобы видеть результат',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),

              // --- Flow diagram ---
              _buildFlowDiagram(),
              const SizedBox(height: 16),

              // --- Two tanks side by side ---
              Row(
                children: [
                  Expanded(
                    child: _buildTank(
                      'Ёмкость', _model.hEmk,
                      ImitationModel.hEmkMin, ImitationModel.hEmkMax, ImitationModel.vEmk,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTank(
                      'Бак химцеха', _model.hChem,
                      ImitationModel.hChemMin, ImitationModel.hChemMax, ImitationModel.vChem,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Vertical sliders ---
              _buildVerticalSliders(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlowDiagram() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Row 1: Ввод → З1 → Ёмкость
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _flowNode('Ввод', '${ImitationModel.qInMax} т/ч', Colors.blue),
              _arrow(),
              _flowNode('Задвижка 1', '${_model.qThroughValve1.toStringAsFixed(0)} т/ч', Colors.cyan),
              _arrow(),
              _flowNode('Ёмкость', '${_model.hEmk.toStringAsFixed(0)} м³', Colors.blue),
            ],
          ),
          const SizedBox(height: 4),
          // Row 2: Ёмкость → Задвижка 2 → Химцех
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 60),
              _flowNode('Задвижка 2', '${_model.qThroughValve2.toStringAsFixed(0)} т/ч', Colors.teal),
              _arrow(),
              _flowNode('Бак химцеха', '${_model.hChem.toStringAsFixed(0)} м³', Colors.orange),
            ],
          ),
          const SizedBox(height: 4),
          // Row 3: Химцех → Регулятор → Выход
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 100),
              _flowNodeRegulator('Регулятор', '${_model.qOut.toStringAsFixed(0)} т/ч'),
              _arrow(),
              _flowNode('Выход (подпитка)', '${_model.qOut.toStringAsFixed(0)} т/ч', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flowNode(String label, String value, Color color) {
    return Column(
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
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 10, color: color),
        ),
      ],
    );
  }

  /// Зелёный треугольник ▲ для автоматического регулятора
  Widget _flowNodeRegulator(String label, String value) {
    return Column(
      children: [
        const Icon(Icons.play_arrow, size: 24, color: Colors.green),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.green.withOpacity(0.4), width: 1),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 10, color: Colors.green),
        ),
      ],
    );
  }

  Widget _arrow() => const Icon(Icons.arrow_forward, size: 14, color: Colors.white38);

  Widget _buildTank(String name, double level, double minLevel, double maxLevel, double maxVolume) {
    final double percent = ((level - minLevel) / (maxLevel - minLevel) * 100).clamp(0.0, 100.0);
    final bool isOver = level > maxLevel;
    final bool isUnder = level < minLevel;
    final Color statusColor = isOver ? Colors.red : (isUnder ? Colors.amber : Colors.blue);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withOpacity(0.5),
          width: isOver || isUnder ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          // Tank with blue water
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _TankPainter(level: percent / 100.0),
            ),
          ),
          const SizedBox(height: 6),
          // Level info
          Text(
            '${level.toStringAsFixed(0)} м³',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: statusColor),
          ),
          Text(
            '$percent.toStringAsFixed(0)%',
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalSliders() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _verticalSlider(
            label: 'Задвижка 1',
            value: _model.kValve1,
            color: Colors.cyan,
            onChanged: _model.setKValve1,
            valueDisplay: '${_model.qThroughValve1.toStringAsFixed(0)} т/ч',
          ),
          _verticalSlider(
            label: 'Задвижка 2',
            value: _model.kValve2,
            color: Colors.teal,
            onChanged: _model.setKValve2,
            valueDisplay: '${_model.qThroughValve2.toStringAsFixed(0)} т/ч',
          ),
          _verticalSlider(
            label: 'Подпитка',
            value: (_model.qOut - 50) / 200, // Normalize 50-250 to 0-1
            color: Colors.red,
            onChanged: (v) => _model.setQOut(50 + v * 200),
            valueDisplay: '${_model.qOut.toStringAsFixed(0)} т/ч',
          ),
        ],
      ),
    );
  }

  Widget _verticalSlider({
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
    required String valueDisplay,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        // Value display above slider
        Text(
          valueDisplay,
          style: TextStyle(fontSize: 10, color: color),
        ),
        const SizedBox(height: 4),
        // Up arrow
        IconButton(
          icon: const Icon(Icons.arrow_upward, size: 20),
          color: color,
          onPressed: () => onChanged((value + 0.05).clamp(0.0, 1.0)),
        ),
        // Vertical slider
        SizedBox(
          height: 120,
          child: RotatedBox(
            quarterTurns: 3,
            child: SizedBox(
              width: 100,
              child: Slider(
                value: value,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                activeColor: color,
                inactiveColor: color.withOpacity(0.2),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        // Down arrow
        IconButton(
          icon: const Icon(Icons.arrow_downward, size: 20),
          color: color,
          onPressed: () => onChanged((value - 0.05).clamp(0.0, 1.0)),
        ),
        // Percentage
        Text(
          '${(value * 100).toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 10, color: color),
        ),
      ],
    );
  }
}

class _TankPainter extends CustomPainter {
  final double level;

  _TankPainter({required this.level});

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

    canvas.drawRRect(rect, paint);

    // Draw blue water
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
  }

  @override
  bool shouldRepaint(covariant _TankPainter oldDelegate) {
    return oldDelegate.level != level;
  }
}
