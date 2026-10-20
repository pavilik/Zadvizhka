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
                'Управляйте задвижками, наблюдайте динамику уровней',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
              const SizedBox(height: 12),

              // --- Control buttons + speed ---
              _buildControls(),
              const SizedBox(height: 12),

              // --- Flow diagram ---
              _buildFlowDiagram(),
              const SizedBox(height: 12),

              // --- Two tanks side by side ---
              Row(
                children: [
                  Expanded(
                    child: _buildTank(
                      'Ёмкость\n2000 м³',
                      _model.hEmk,
                      ImitationModel.vEmk,
                      _model.emkStatus,
                      _model.emkDirection,
                      _model.emkTimeToAlarm,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTank(
                      'Бак химцеха\n800 м³',
                      _model.hChem,
                      ImitationModel.vChem,
                      _model.chemStatus,
                      _model.chemDirection,
                      _model.chemTimeToAlarm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ctrlButton(
                icon: Icons.play_arrow,
                label: 'Пуск',
                color: Colors.green,
                onPressed: _model.running ? null : _model.start,
              ),
              const SizedBox(width: 8),
              _ctrlButton(
                icon: Icons.stop,
                label: 'Стоп',
                color: Colors.red,
                onPressed: _model.running ? _model.stop : null,
              ),
              const SizedBox(width: 8),
              _ctrlButton(
                icon: Icons.refresh,
                label: 'Сброс',
                color: Colors.orange,
                onPressed: _model.reset,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Speed slider (логарифмический: 1x..5000x)
          Row(
            children: [
              const Icon(Icons.speed, size: 16, color: Colors.white54),
              const SizedBox(width: 6),
              const Text('Ускорение:', style: TextStyle(fontSize: 11, color: Colors.white70)),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    activeTrackColor: Colors.amber,
                    inactiveTrackColor: Colors.amber.withOpacity(0.15),
                    thumbColor: Colors.amber,
                    overlayColor: Colors.amber.withOpacity(0.1),
                  ),
                  child: Slider(
                    value: _model.speedSlider,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    label: _model.speedLabel,
                    onChanged: _model.setSpeed,
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  _model.speedLabel,
                  style: const TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          // Симулированное время
          if (_model.running)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Время: ${_model.simulatedTimeFormatted}',
                style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ctrlButton({
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
              _flowNode('Ввод', '300 т/ч', Colors.blue),
              _arrow(),
              _flowNodeEditable(
                'Задвижка 1',
                _model.qValve1,
                _model.kValve1 * 100,
                Colors.cyan,
                step: 1,
                onIncrease: () => _model.setQValve1(_model.qValve1 + 1),
                onDecrease: () => _model.setQValve1(_model.qValve1 - 1),
              ),
              _arrow(),
              _flowNode('Ёмкость', '${_model.hEmk.toStringAsFixed(0)} м³', _statusColor(_model.emkStatus)),
            ],
          ),
          const SizedBox(height: 4),
          // Row 2: Ёмкость → Задвижка 2 → Химцех
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 60),
              _flowNodeEditable(
                'Задвижка 2',
                _model.qValve2,
                _model.kValve2 * 100,
                Colors.teal,
                step: 1,
                onIncrease: () => _model.setQValve2(_model.qValve2 + 1),
                onDecrease: () => _model.setQValve2(_model.qValve2 - 1),
              ),
              _arrow(),
              _flowNode('Бак химцеха', '${_model.hChem.toStringAsFixed(0)} м³', _statusColor(_model.chemStatus)),
            ],
          ),
          const SizedBox(height: 4),
          // Row 3: Химцех → Подпитка → Выход
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 100),
              _flowNodeEditable(
                'Подпитка',
                _model.qOut,
                null,
                Colors.red,
                step: 1,
                onIncrease: () => _model.setQOut(_model.qOut + 1),
                onDecrease: () => _model.setQOut(_model.qOut - 1),
                isRandom: _model.randomQOut,
              ),
              _arrow(),
              _flowNode('Выход', '${_model.qOut.toStringAsFixed(0)} т/ч', Colors.red),
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

  /// Редактируемый узел схемы с кнопками +/-
  Widget _flowNodeEditable(
    String label,
    double value,
    double? percentage,
    Color color, {
    required double step,
    required VoidCallback onIncrease,
    required VoidCallback onDecrease,
    bool isRandom = false,
  }) {
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
        const SizedBox(height: 4),
        // Кнопки +/- и значение
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.remove_circle_outline, size: 22),
              color: isRandom ? Colors.grey : Colors.red,
              onPressed: isRandom ? null : onDecrease,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
            const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${value.toStringAsFixed(0)} т/ч',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                ),
                if (percentage != null)
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 8, color: color.withOpacity(0.7)),
                  ),
              ],
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.add_circle_outline, size: 22),
              color: isRandom ? Colors.grey : Colors.green,
              onPressed: isRandom ? null : onIncrease,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ],
    );
  }

  Widget _arrow() => const Icon(Icons.arrow_forward, size: 14, color: Colors.white38);

  /// Цвет статуса: 0=синий(норма), 1=жёлтый(внимание), 2=красный(авария)
  Color _statusColor(int status) {
    switch (status) {
      case 2: return Colors.red;
      case 1: return Colors.amber;
      default: return Colors.blue;
    }
  }

  Widget _buildTank(String name, double level, double maxVolume, int status, int direction, String? timeToAlarm) {
    final double percent = (level / maxVolume * 100).clamp(0.0, 100.0);
    final Color color = _statusColor(status);

    // Стрелка направления
    Widget directionIcon;
    Color? directionColor;
    if (direction > 0) {
      directionIcon = const Icon(Icons.arrow_upward, size: 16, color: Colors.green);
      directionColor = Colors.green;
    } else if (direction < 0) {
      directionIcon = const Icon(Icons.arrow_downward, size: 16, color: Colors.orange);
      directionColor = Colors.orange;
    } else {
      directionIcon = const Icon(Icons.arrow_right, size: 16, color: Colors.grey);
      directionColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: status == 2 ? 2.5 : (status == 1 ? 2.0 : 1.0),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
                ),
              ),
              const SizedBox(width: 4),
              directionIcon,
            ],
          ),
          const SizedBox(height: 4),
          // Tank with colored water
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _TankPainter(level: percent / 100.0, statusColor: color, status: status),
            ),
          ),
          const SizedBox(height: 6),
          // Level info
          Text(
            '${level.toStringAsFixed(0)} м³',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
          // Прогноз времени до аварии
          if (timeToAlarm != null && status < 2)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      'Авария: $timeToAlarm',
                      style: const TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          // Статус indicator
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statusDot(0, 'Норм', status),
              const SizedBox(width: 6),
              _statusDot(1, 'Вним', status),
              const SizedBox(width: 6),
              _statusDot(2, 'Авар', status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusDot(int level, String label, int current) {
    final bool active = current >= level;
    final Color c = _statusColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: active ? c.withOpacity(0.25) : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: active ? c.withOpacity(0.6) : Colors.white12,
          width: active ? 1 : 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          color: active ? c : Colors.grey[600],
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _TankPainter extends CustomPainter {
  final double level;
  final Color statusColor;
  final int status;

  _TankPainter({required this.level, required this.statusColor, required this.status});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
      const Radius.circular(6),
    );

    // Tank border
    final borderPaint = Paint()
      ..color = statusColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rect, borderPaint);

    // Draw water with color based on status
    if (level > 0) {
      Color waterColor;
      Color surfaceColor;
      switch (status) {
        case 2: // Авария - красный
          waterColor = const Color(0xFFE53935);
          surfaceColor = const Color(0xFFEF5350);
          break;
        case 1: // Внимание - жёлтый
          waterColor = const Color(0xFFFFC107);
          surfaceColor = const Color(0xFFFFD54F);
          break;
        default: // Норма - синий
          waterColor = const Color(0xFF2196F3);
          surfaceColor = const Color(0xFF64B5F6);
      }

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
        ..color = waterColor.withOpacity(0.6)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(waterRect, waterPaint);

      // Water surface line
      final surfacePaint = Paint()
        ..color = surfaceColor.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final surfaceY = size.height - 4 - (size.height - 8) * level;
      canvas.drawLine(
        Offset(6, surfaceY),
        Offset(size.width - 6, surfaceY),
        surfacePaint,
      );
    }

    // Границы: 15% и 85% линии
    final double y15 = size.height - 4 - (size.height - 8) * 0.15;
    final double y85 = size.height - 4 - (size.height - 8) * 0.85;
    final dashPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(6, y15), Offset(size.width - 6, y15), dashPaint);
    canvas.drawLine(Offset(6, y85), Offset(size.width - 6, y85), dashPaint);
  }

  @override
  bool shouldRepaint(covariant _TankPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.statusColor != statusColor || oldDelegate.status != status;
  }
}
