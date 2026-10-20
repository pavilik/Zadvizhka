import 'dart:async';
import 'package:flutter/material.dart';
import '../models/imitation_model.dart';

class ImitationScreen extends StatefulWidget {
  const ImitationScreen({super.key});

  @override
  State<ImitationScreen> createState() => _ImitationScreenState();
}

class _ImitationScreenState extends State<ImitationScreen> {
  final ImitationModel _model = ImitationModel();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _model.addListener(_onModelChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _model.removeListener(_onModelChanged);
    _model.dispose();
    super.dispose();
  }

  void _onModelChanged() {
    // Only rebuild from listener, timer triggers via setState
  }

  void _startSimulation() {
    _model.reset();
    _model.start();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      _model.tick();
    });
    setState(() {});
  }

  void _stopSimulation() {
    _timer?.cancel();
    _timer = null;
    _model.stop();
    setState(() {});
  }

  void _resetSimulation() {
    _timer?.cancel();
    _timer = null;
    _model.reset();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Flow values for display
    final double qZ1 = _model.kZ1 * _model.qIn;
    final double qPpn = _model.kPpn * 0.25;
    final double qPsv = _model.kPsv * qPpn;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // --- Control buttons row ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controlButton(
                icon: Icons.play_arrow,
                label: 'Пуск',
                color: Colors.green,
                onPressed: _model.running ? null : _startSimulation,
              ),
              const SizedBox(width: 8),
              _controlButton(
                icon: Icons.stop,
                label: 'Стоп',
                color: Colors.red,
                onPressed: _model.running ? _stopSimulation : null,
              ),
              const SizedBox(width: 8),
              _controlButton(
                icon: Icons.refresh,
                label: 'Сброс',
                color: Colors.orange,
                onPressed: _resetSimulation,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // --- Random mode toggle (outflow only) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D44),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shuffle, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                const Text(
                  'Потребление:',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _model.setRandomMode(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _model.randomMode
                          ? Colors.grey.withOpacity(0.3)
                          : Colors.teal.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Пост.',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _model.setRandomMode(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _model.randomMode
                          ? Colors.amber.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Случ.',
                      style: TextStyle(
                        fontSize: 11,
                        color: _model.randomMode ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // --- Tick counter ---
          if (_model.running)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Тик: ${_model.tickCount}',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ),

          // --- Flow diagram ---
          _buildFlowDiagram(qZ1, qPpn, qPsv),
          const SizedBox(height: 12),

          // --- Three tanks ---
          Row(
            children: [
              Expanded(
                child: _buildMiniTank(
                  'Ёмкость',
                  _model.hEmk,
                  ImitationModel.hEmkMin,
                  ImitationModel.hEmkMax,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMiniTank(
                  'Химцех',
                  _model.hChem,
                  ImitationModel.hChemMin,
                  ImitationModel.hChemMax,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMiniTank(
                  'Деаэратор',
                  _model.hDea,
                  ImitationModel.hDeaMin,
                  ImitationModel.hDeaMax,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- Sliders ---
          _buildSliderSection(),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.3),
        foregroundColor: color,
        disabledBackgroundColor: Colors.grey.withOpacity(0.15),
        disabledForegroundColor: Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: color.withOpacity(0.5), width: 1),
        ),
      ),
    );
  }

  Widget _buildFlowDiagram(double qZ1, double qPpn, double qPsv) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Top row: Ввод -> З1 -> Ёмкость -> ППН -> ПСВ -> Химцех
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _flowNodeSmall('Ввод', _model.qIn, Colors.blue),
              _flowArrowSmall(),
              _flowNodeSmall('З1', qZ1, Colors.cyan),
              _flowArrowSmall(),
              _flowNodeSmall('Ёмк.', null, Colors.green),
              _flowArrowSmall(),
              _flowNodeSmall('ППН', qPpn, Colors.green),
              _flowArrowSmall(),
              _flowNodeSmall('ПСВ', qPsv, Colors.teal),
              _flowArrowSmall(),
              _flowNodeSmall('Хим.', null, Colors.orange),
            ],
          ),
          const SizedBox(height: 6),
          // Bottom row: Химцех -> Деаэратор -> Потребитель
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 120),
              _flowNodeSmall('Деаэр.', null, Colors.purple),
              _flowArrowSmall(),
              _flowNodeSmall('Потр.', _model.qOut, Colors.red),
              const SizedBox(width: 120),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flowNodeSmall(String label, double? value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withOpacity(0.4), width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: color),
          ),
        ),
        if (value != null)
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(fontSize: 8, color: color),
          ),
      ],
    );
  }

  Widget _flowArrowSmall() {
    return const Icon(Icons.arrow_forward, size: 10, color: Colors.white38);
  }

  Widget _buildMiniTank(
    String name,
    double level,
    double minLevel,
    double maxLevel,
    Color color,
  ) {
    final bool isOver = level > maxLevel;
    final bool isUnder = level < minLevel;
    final Color statusColor = isOver ? Colors.red : (isUnder ? Colors.amber : color);
    final double fill = level.clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withOpacity(0.5),
          width: isOver || isUnder ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          // Tank
          SizedBox(
            height: 100,
            child: CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _MiniTankPainter(
                level: fill,
                color: color,
                isOver: isOver,
                isUnder: isUnder,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(level * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Text(
            'Регулировка задвижек',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          _sliderRow('З1 (в ёмкость)', _model.kZ1, Colors.cyan, _model.setKZ1),
          _sliderRow('ПСВ (в химцех)', _model.kPsv, Colors.teal, _model.setKPsv),
          _sliderRow('ППН (насос)', _model.kPpn, Colors.green, _model.setKPpn),
          const Divider(color: Colors.white12, height: 12),
          _sliderRow('Ввод (приток)', _model.qIn, Colors.blue, _model.setQIn),
          _sliderRow('Потребление', _model.qOut, Colors.red, _model.setQOut),
        ],
      ),
    );
  }

  Widget _sliderRow(String label, double value, Color color, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[300]),
            ),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              activeColor: color,
              inactiveColor: color.withOpacity(0.15),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 10, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTankPainter extends CustomPainter {
  final double level;
  final Color color;
  final bool isOver;
  final bool isUnder;

  _MiniTankPainter({
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
  bool shouldRepaint(covariant _MiniTankPainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.isOver != isOver ||
        oldDelegate.isUnder != isUnder;
  }
}